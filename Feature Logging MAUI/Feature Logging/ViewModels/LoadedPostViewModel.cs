using System.Collections.ObjectModel;
using System.Net.Http.Headers;
using Android.Provider;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Core;
using FeatureLogging.Base;
using FeatureLogging.Models;
using FeatureLogging.Views;
using HtmlAgilityPack;
using Newtonsoft.Json.Linq;
using SkiaSharp;
using Browser = Microsoft.Maui.ApplicationModel.Browser;

namespace FeatureLogging.ViewModels;

public class LoadedPostViewModel(MainViewModel vm) : NotifyPropertyChanged
{
    private readonly HttpClient httpClient = new();

    public async Task TriggerLoad()
    {
        await Task.Delay(TimeSpan.FromSeconds(1));
        await LoadPost();
    }

    public MainViewModel MainViewModel { get; } = vm;

    private async Task LoadPost()
    {
        LogEntries.Clear();

        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            // Accept JSON result
            httpClient.DefaultRequestHeaders.Accept.Clear();
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("text/html", 0.9));
            httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/xhtml+xml", 0.9));
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml", 0.9));
            var postUri = new Uri(MainViewModel.SelectedFeature!.PostLink);
            var content = await httpClient.GetStringAsync(postUri);

            if (!string.IsNullOrEmpty(content))
            {
                LogProgress("Loaded the post contents");
                var document = new HtmlDocument();
                document.LoadHtml(content);
                var scripts = document.DocumentNode.Descendants("script").ToArray();
                foreach (var script in scripts)
                {
                    var scriptText = script.InnerText.Trim();
                    if (string.IsNullOrEmpty(scriptText))
                    {
                        continue;
                    }

                    if (!scriptText.StartsWith("window.__staticRouterHydrationData = JSON.parse(\"") ||
                        !scriptText.EndsWith("\");"))
                    {
                        continue;
                    }

                    var prefixLength = "window.__staticRouterHydrationData = JSON.parse(\"".Length;
                    var jsonString = string.Concat("\"", scriptText
                        .AsSpan(prefixLength, scriptText.Length - (prefixLength + 3)), "\"");
                    // Use JToken.Parse to convert from JSON encoded as a JSON string to the JSON.
                    jsonString = (string)JToken.Parse(jsonString)!;
                    var postData = PostData.FromJson(jsonString);
                    if (postData != null)
                    {
                        LogProgress("Found the post data", LogType.Success);
                        var profile = postData.LoaderData?.Entry?.Profile?.Profile;
                        if (profile != null)
                        {
                            LogProgress("Loaded the user's profile", LogType.Success);
                            UserAlias = profile.Username ?? string.Empty;
                            if (string.IsNullOrEmpty(UserAlias) && !string.IsNullOrEmpty(profile.Name))
                            {
                                UserAlias = profile.Name!.Replace(" ", "");
                            }

                            UserName = profile.Name ?? string.Empty;
                            UserProfileUrl = profile.Url?.ToString() ?? string.Empty;
                            UserBio = profile.Bio?.Replace("\\n", "\n").StripExtraSpaces(true) ?? string.Empty;
                        }
                        else
                        {
                            LogProgress("No profile found", LogType.Error);
                        }

                        var post = postData.LoaderData?.Entry?.Post?.Post;
                        if (post != null)
                        {
                            ShowDescription = true;
                            pageHashTags.Clear();
                            Description = post.Caption != null
                                ? PostDataHelper.JoinSegments(post.Caption, pageHashTags).StripExtraSpaces()
                                : "";
                            var pageTagFound = "";
                            if (pageHashTags.FirstOrDefault(hashTag =>
                                {
                                    return MainViewModel.SelectedPage!.PageTags.FirstOrDefault(pageHashTag =>
                                    {
                                        if (string.Equals(hashTag, pageHashTag, StringComparison.OrdinalIgnoreCase))
                                        {
                                            pageTagFound = pageHashTag.ToLower();
                                            return true;
                                        }
                                        return false;
                                    }) != null;
                                }) != null)
                            {
                                PageHashtagCheck = new ValidationResult(message: $"Contains page hashtag {pageTagFound}");
                                LogProgress(PageHashtagCheck.Message!);
                            }
                            else
                            {
                                PageHashtagCheck = new ValidationResult(ValidationLevel.Error, "MISSING page hashtag");
                                LogProgress(PageHashtagCheck.Message!, LogType.Error);
                            }
                            UpdateExcludedTags();

                            ImageEntries.Clear();
                            var imageUrls = post.Images?.Select(image => image.Url)
                                .Where(url => url != null && url.ToString().StartsWith("https://")).ToArray();
                            if (imageUrls?.Length > 0)
                            {
                                foreach (var imageUrl in imageUrls)
                                {
                                    if (imageUrl != null)
                                    {
                                        ImageEntries.Add(new ImageEntry(imageUrl, this));
                                    }
                                }
                            }
                            if (ImageEntries.Count > 0)
                            {
                                ShowImages = true;
                                LogProgress($"Found {ImageEntries.Count} images in post");
                            }
                            else
                            {
                                LogProgress("No images found in post", LogType.Error);
                            }
                            ShowImageNavigators = ImageEntries.Count > 1;

                            if (MainViewModel.SelectedPage!.HubName == "snap" ||
                                MainViewModel.SelectedPage!.HubName == "click")
                            {
                                var comments = postData.LoaderData?.Entry?.Post?.Comments ?? [];
                                var localPageComments = new List<CommentEntry>();
                                var localHubComments = new List<CommentEntry>();
                                foreach (var comment in comments)
                                {
                                    var commentUserName = comment.Author?.Username?.ToLower() ?? "";
                                    if (commentUserName.Equals(MainViewModel.SelectedPage!.DisplayName, StringComparison.OrdinalIgnoreCase))
                                    {
                                        var commentSegments = PostDataHelper.JoinSegments(comment.Content).StripExtraSpaces(true);
                                        localPageComments.Add(new CommentEntry(
                                            commentUserName,
                                            comment.Timestamp,
                                            commentSegments,
                                            (_, _) => { MainViewModel.SelectedFeature!.PhotoFeaturedOnPage = true; }));
                                        PageCommentsValidation = new ValidationResult(
                                            ValidationLevel.Error, 
                                            "Found page comments - possibly already featured on page");
                                        ShowComments = true;
                                        LogProgress(
                                            $"Found page comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {commentSegments}", 
                                            LogType.Error);
                                    }
                                    else if (commentUserName.StartsWith($"{MainViewModel.SelectedPage!.HubName.ToLower()}_"))
                                    {
                                        var commentSegments = PostDataHelper.JoinSegments(comment.Content).StripExtraSpaces(true);
                                        localHubComments.Add(new CommentEntry(
                                            commentUserName,
                                            comment.Timestamp,
                                            commentSegments,
                                            (page, timestamp) =>
                                            {
                                                MainViewModel.SelectedFeature!.PhotoFeaturedOnHub = true;
                                                MainViewModel.SelectedFeature!.PhotoLastFeaturedPage =
                                                    page[(MainViewModel.SelectedPage!.HubName.Length + 1)..];
                                                MainViewModel.SelectedFeature!.PhotoLastFeaturedOnHub = timestamp;
                                            }));
                                        HubCommentsValidation = new ValidationResult(
                                            ValidationLevel.Warning,
                                            "Found hub comments - possibly already featured on another page");
                                        ShowComments = true;
                                        LogProgress(
                                            $"Found hub comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {commentSegments}",
                                            LogType.Warning);
                                    }
                                }

                                MoreComments = comments.Length < (post.Comments ?? 0);
                                if (MoreComments)
                                {
                                    LogProgress("More comments!", LogType.Warning);
                                    ShowComments = true;
                                }

                                PageComments = [.. localPageComments];
                                HubComments = [.. localHubComments];
                            }
                        }
                        else
                        {
                            LogProgress("No post information in the post data found", LogType.Error);
                        }
                    }
                    else
                    {
                        LogProgress("No post data found", LogType.Error);
                    }
                }
            }
            else
            {
                LogProgress("No contents were loaded for the post", LogType.Error);
            }
        }
        catch (Exception ex)
        {
            LogProgress($"Failed to load the post: {ex.Message}", LogType.Error);
        }
    }

    private void LogProgress(string message, LogType type = LogType.Info)
    {
        LogEntries.Add(new LogEntry(message, type));
    }

    private readonly List<string> pageHashTags = [];

    #region Logging

    public ObservableCollection<LogEntry> LogEntries { get; } = [];

    #endregion

    #region User Alias

    private string? userAlias;

    public string? UserAlias
    {
        get => userAlias;
        set
        {
            if (Set(ref userAlias, value))
            {
                UserAliasValidation = Validation.ValidateUserName(userAlias ?? "");
                OnPropertyChanged(nameof(TransferUserAliasCommand));
            }
        }
    }

    private ValidationResult userAliasValidation = Validation.ValidateUserName("");

    public ValidationResult UserAliasValidation
    {
        get => userAliasValidation;
        private set => Set(ref userAliasValidation, value);
    }

    #endregion

    #region User Name

    private string? userName;

    public string? UserName
    {
        get => userName;
        set
        {
            if (Set(ref userName, value))
            {
                UserNameValidation = Validation.ValidateUserName(userName ?? "");
                OnPropertyChanged(nameof(TransferUserNameCommand));
            }
        }
    }

    private ValidationResult userNameValidation = Validation.ValidateUserName("");

    public ValidationResult UserNameValidation
    {
        get => userNameValidation;
        private set => Set(ref userNameValidation, value);
    }

    #endregion

    #region User Profile URL

    private string? userProfileUrl;

    public string? UserProfileUrl
    {
        get => userProfileUrl;
        set
        {
            if (Set(ref userProfileUrl, value))
            {
                UserProfileUrlValidation = Validation.ValidateUserProfileUrl(userProfileUrl ?? "");
                OnPropertyChanged(nameof(CopyUserProfileUrlCommand));
                OnPropertyChanged(nameof(LaunchUserProfileUrlCommand));
            }
        }
    }

    private ValidationResult userProfileUrlValidation = Validation.ValidateUserProfileUrl("");

    public ValidationResult UserProfileUrlValidation
    {
        get => userProfileUrlValidation;
        private set => Set(ref userProfileUrlValidation, value);
    }

    #endregion

    #region User BIO

    private string? userBio;

    public string? UserBio
    {
        get => userBio;
        set => Set(ref userBio, value);
    }

    #endregion

    #region Description

    private bool showDescription;

    public bool ShowDescription
    {
        get => showDescription;
        set => Set(ref showDescription, value);
    }

    private string? description;

    public string? Description
    {
        get => description;
        set => Set(ref description, value);
    }

    #endregion

    #region Tag Checks

    private ValidationResult pageHashtagCheck = new(ValidationLevel.Valid);

    public ValidationResult PageHashtagCheck
    {
        get => pageHashtagCheck;
        set => Set(ref pageHashtagCheck, value);
    }

    private ValidationResult excludedHashtagCheck = new(ValidationLevel.Valid);

    public ValidationResult ExcludedHashtagCheck
    {
        get => excludedHashtagCheck;
        set => Set(ref excludedHashtagCheck, value);
    }

    #endregion

    #region Comments

    private bool showComments;

    public bool ShowComments
    {
        get => showComments;
        set => Set(ref showComments, value);
    }

    private CommentEntry[] pageComments = [];

    public CommentEntry[] PageComments
    {
        get => pageComments;
        private set => Set(ref pageComments, value);
    }

    private ValidationResult pageCommentsValidation = new(ValidationLevel.Valid);

    public ValidationResult PageCommentsValidation
    {
        get => pageCommentsValidation;
        set => Set(ref pageCommentsValidation, value);
    }

    private CommentEntry[] hubComments = [];

    public CommentEntry[] HubComments
    {
        get => hubComments;
        private set => Set(ref hubComments, value);
    }

    private ValidationResult hubCommentsValidation = new(ValidationLevel.Valid);

    public ValidationResult HubCommentsValidation
    {
        get => hubCommentsValidation;
        set => Set(ref hubCommentsValidation, value);
    }

    private bool moreComments;

    public bool MoreComments
    {
        get => moreComments;
        private set => Set(ref moreComments, value);
    }

    #endregion

    #region Images

    public ObservableCollection<ImageEntry> ImageEntries { get; } = [];

    private ImageEntry? currentImage;
    public ImageEntry? CurrentImage
    {
        get => currentImage;
        set => Set(ref currentImage, value);
    }

    private bool showImages;
    public bool ShowImages
    {
        get => showImages;
        set => Set(ref showImages, value);
    }

    private bool showImageNavigators;
    public bool ShowImageNavigators
    {
        get => showImageNavigators;
        set => Set(ref showImageNavigators, value);
    }

    #endregion

    #region Image Validation

    private ImageValidationViewModel? imageValidation;
    public ImageValidationViewModel? ImageValidation
    {
        get => imageValidation;
        private set
        {
            if (Set(ref imageValidation, value))
            {
                MainViewModel.TriggerTinEyeSource();
            }
        }
    }

    #endregion

    #region Commands

    public SimpleCommand CopyPostUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(MainViewModel.SelectedFeature?.PostLink))
        {
            _ = CopyTextToClipboard(MainViewModel.SelectedFeature.PostLink, "Copied the post URL to the clipboard");
        }
    }, () => !string.IsNullOrEmpty(MainViewModel.SelectedFeature?.PostLink));

    public SimpleCommand LaunchPostUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(MainViewModel.SelectedFeature?.PostLink))
        {
            _ = Browser.OpenAsync(MainViewModel.SelectedFeature!.PostLink, BrowserLaunchMode.SystemPreferred);
        }
    }, () => !string.IsNullOrEmpty(MainViewModel.SelectedFeature?.PostLink));

    public SimpleCommand CopyUserProfileUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(UserProfileUrl))
        {
            _ = CopyTextToClipboard(UserProfileUrl, "Copied the user profile URL to the clipboard");
        }
    }, () => !string.IsNullOrEmpty(UserProfileUrl));

    public SimpleCommand LaunchUserProfileUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(UserProfileUrl))
        {
            _ = Browser.OpenAsync(UserProfileUrl, BrowserLaunchMode.SystemPreferred);
        }
    }, () => !string.IsNullOrEmpty(UserProfileUrl));

    public SimpleCommand TransferUserAliasCommand => new(() => { MainViewModel.SelectedFeature!.UserAlias = UserAlias!; },
        () => !string.IsNullOrEmpty(UserAlias));

    public SimpleCommand TransferUserNameCommand => new(() => { MainViewModel.SelectedFeature!.UserName = UserName!; },
        () => !string.IsNullOrEmpty(UserName));

    public SimpleCommand PreviousImageCommand => new(() =>
    {
        if (CurrentImage != null && ImageEntries.Count > 1)
        {
            var index = ImageEntries.IndexOf(CurrentImage);
            CurrentImage = index > 0 ? ImageEntries[index - 1] : ImageEntries.Last();
        }
    });

    public SimpleCommand NextImageCommand => new(() =>
    {
        if (CurrentImage != null && ImageEntries.Count > 1)
        {
            var index = ImageEntries.IndexOf(CurrentImage);
            CurrentImage = index < ImageEntries.Count - 1 ? ImageEntries[index + 1] : ImageEntries.First();
        }
    });

    public SimpleCommand CopyLogCommand => new(() =>
    {
        _ = CopyTextToClipboard(string.Join("\n", LogEntries.Select(entry => entry.Message)),
            "Copied the log messages to the clipboard");
    });

    #endregion

    private static async Task CopyTextToClipboard(string text, string successMessage)
    {
        await MainViewModel.TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
    }

    public void UpdateExcludedTags()
    {
        var excludedHashtags = MainViewModel.ExcludedTags.Split(",", StringSplitOptions.RemoveEmptyEntries);
        if (excludedHashtags.Length != 0)
        {
            ExcludedHashtagCheck = new ValidationResult(message: "Post does not contain any excluded hashtags");
            foreach (var excludedHashtag in excludedHashtags)
            {
                if (pageHashTags.IndexOf(excludedHashtag) != -1)
                {
                    ExcludedHashtagCheck = new ValidationResult(ValidationLevel.Error, $"Post contains excluded hashtag {excludedHashtag}");
                    LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!, LogType.Error));
                    break;
                }
            }

            if (ExcludedHashtagCheck.Valid)
            {
                LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!));
            }
        }
        else
        {
            ExcludedHashtagCheck = new ValidationResult(message: "There are no excluded hashtags");
            LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!));
        }
    }

    public void ValidateImage(ImageEntry imageEntry)
    {
        ImageValidation = new ImageValidationViewModel(MainViewModel, imageEntry);
        MainViewModel.MainWindow!.Navigation.PushAsync(new ImageValidation
        {
            BindingContext = ImageValidation
        });
    }
}

public class ImageEntry : NotifyPropertyChanged, IDisposable
{
    public ImageEntry(Uri source, LoadedPostViewModel vm)
    {
        Source = source;
        this.vm = vm;
        _ = GetImageDimensionsAsync(source.AbsoluteUri);
    }

    public Uri Source { get; }
   
    private readonly LoadedPostViewModel vm;

    private int width;
    public int Width
    {
        get => width;
        private set => Set(ref width, value);
    }

    private int height;
    public int Height
    {
        get => height;
        private set => Set(ref height, value);
    }
    
    private SKBitmap? SkiaBitmap { get; set; }

    private async Task GetImageDimensionsAsync(string imageUrl)
    {
        // Create HttpClient instance
        using var client = new HttpClient();
        // Download the image data
        var response = await client.GetAsync(imageUrl);
        if (response.IsSuccessStatusCode)
        {
            // Read the image data into a memory stream
            var imageData = await response.Content.ReadAsByteArrayAsync();
            using var stream = new MemoryStream(imageData);
            // Load the image from the memory stream
            // Load the image from the memory stream using SkiaSharp
            SkiaBitmap = SKBitmap.Decode(stream);
            // Get the image dimensions
            Width = SkiaBitmap.Width;
            Height = SkiaBitmap.Height;
        }
        else
        {
            throw new Exception("Failed to download image");
        }
    }    
    
    public SimpleCommand ValidateImageCommand => new(() =>
    {
        vm.ValidateImage(this);
    });

    public SimpleCommand SaveImageCommand => new(async void () =>
    {
        try
        {
            using var imageStream = new MemoryStream();
            using var skImage = SKImage.FromBitmap(SkiaBitmap);
            using var skData = skImage.Encode(SKEncodedImageFormat.Png, 100);
            skData.SaveTo(imageStream);
            await SaveToPhotoLibraryAsync(imageStream.ToArray());
            await Toast.Make($"Saved the image to your photo gallery folder").Show();
        }
        catch (Exception ex)
        {
            await Toast.Make($"Failed to save image: {ex.Message}", ToastDuration.Long).Show();
        }
    });
    
    private static async Task SaveToPhotoLibraryAsync(byte[] imageData)
    {
        if (DeviceInfo.Platform == DevicePlatform.Android)
        {
            await SaveToPhotoLibraryAndroidAsync(imageData);
        }
        else if (DeviceInfo.Platform == DevicePlatform.iOS)
        {
            throw new NotImplementedException("Saving images to the iOS photo library is not implemented yet.");
        }
    }

    private static Task SaveToPhotoLibraryAndroidAsync(byte[] imageData)
    {
#pragma warning disable CA1416
        var context = Android.App.Application.Context;
        var filename = $"IMG_{DateTime.Now:yyyyMMdd_HHmmss}.png";
        var values = new Android.Content.ContentValues();
        values.Put(
            MediaStore.Images.Media.InterfaceConsts.DisplayName, 
            filename);
        values.Put(
            MediaStore.Images.Media.InterfaceConsts.MimeType, 
            "image/png");
        values.Put(
            MediaStore.Images.Media.InterfaceConsts.DateAdded,
            Java.Lang.JavaSystem.CurrentTimeMillis() / 1000);
        values.Put(
            MediaStore.Images.Media.InterfaceConsts.DateTaken,
            Java.Lang.JavaSystem.CurrentTimeMillis());

        if (MediaStore.Images.Media.ExternalContentUri != null)
        {
            var uri = context.ContentResolver?.Insert(MediaStore.Images.Media.ExternalContentUri, values);
            if (uri != null)
            {
                using var outputStream = context.ContentResolver?.OpenOutputStream(uri);
                outputStream?.Write(imageData, 0, imageData.Length);
            }
        }
#pragma warning restore CA1416

        return Task.CompletedTask;
    }

    public SimpleCommand CopyImageUrlCommand => new(() =>
    {
        _ = CopyTextToClipboard(Source.AbsoluteUri, "Copied image URL to clipboard");
    });
    public SimpleCommand LaunchImageCommand => new(() =>
    {
        _ = Browser.OpenAsync(Source.AbsoluteUri, BrowserLaunchMode.SystemPreferred);
    });

    private static async Task CopyTextToClipboard(string text, string successMessage)
    {
        await MainViewModel.TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
    }

    public void Dispose()
    {
        if (SkiaBitmap != null)
        {
            SkiaBitmap.Dispose();
            SkiaBitmap = null;
        }
        GC.SuppressFinalize(this);
    }
}

public class CommentEntry(string page, DateTime? timestamp, string comment, Action<string, string> markFeature) : NotifyPropertyChanged
{
    public string Page { get; } = page;

    public string Timestamp { get; } = timestamp?.FormatTimestamp() ?? "?";

    public string Comment { get; } = comment;

    public SimpleCommand MarkFeatureCommand => new(() =>
    {
        markFeature(Page, this.Timestamp);
    });
}
