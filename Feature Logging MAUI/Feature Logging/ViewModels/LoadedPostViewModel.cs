using System.Collections.ObjectModel;
// using System.IO;
using System.Net.Http.Headers;
// using System.Net.Http;
using System.Text;
// using System.Windows.Media;
// using System.Xml;
// using Newtonsoft.Json;
// using Sgml;
// using System.Diagnostics;
using System.Text.RegularExpressions;
// using System.Windows.Input;
using CommunityToolkit.Maui.Alerts;
using FeatureLogging.Base;
using FeatureLogging.Models;

// using CommunityToolkit.Maui.Core;
// using System.Windows.Media.Imaging;
// using Notification.Wpf;
// using Newtonsoft.Json.Linq;

namespace FeatureLogging.ViewModels;

public class LoadedPostViewModel : NotifyPropertyChanged
{
    private static readonly Color? DefaultLogColor = null;
    private readonly HttpClient httpClient = new();
    private readonly MainViewModel vm;

    public LoadedPostViewModel(MainViewModel vm)
    {
        this.vm = vm;

        // Load the post async-ly.
        _ = LoadPost();
    }

    private async Task LoadPost()
    {
        var postUrl = vm.SelectedFeature!.PostLink;
        var selectedPage = vm.SelectedPage!;
        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            // Accept JSON result
            httpClient.DefaultRequestHeaders.Accept.Clear();
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            var postUri = new Uri(postUrl);
            var content = await httpClient.GetStringAsync(postUri);
            if (!string.IsNullOrEmpty(content))
            {
                // try
                // {
                //     using var reader = new StringReader(content);
                //     using var sgmlReader = new SgmlReader();
                //     sgmlReader.DocType = "HTML";
                //     sgmlReader.WhitespaceHandling = WhitespaceHandling.All;
                //     sgmlReader.CaseFolding = CaseFolding.ToLower;
                //     sgmlReader.InputStream = reader;
                //     var document = new XmlDocument
                //     {
                //         PreserveWhitespace = true,
                //         XmlResolver = null
                //     };
                //     document.Load(sgmlReader);

                //     progress.Report((40, "Looking for script", null, null));
                //     var scriptElements = document.GetElementsByTagName("script");
                //     foreach (var scriptElement in scriptElements)
                //     {
                //         if (scriptElement is XmlElement scriptXmlElement)
                //         {
                //             var scriptText = scriptXmlElement.InnerText;
                //             if (!string.IsNullOrEmpty(scriptText))
                //             {
                //                 if (scriptText.StartsWith("window.__staticRouterHydrationData = JSON.parse(\"") && scriptText.EndsWith("\");"))
                //                 {
                //                     var prefixLength = "window.__staticRouterHydrationData = JSON.parse(\"".Length;
                //                     var jsonString = string.Concat("\"", scriptText
                //                         .AsSpan(prefixLength, scriptText.Length - (prefixLength + 3)), "\"");
                //                     // Use JToken.Parse to convert from JSON encoded as a JSON string to the JSON.
                //                     jsonString = (string)JToken.Parse(jsonString)!;
                //                     var postData = PostData.FromJson(jsonString);
                //                     if (postData != null)
                //                     {
                //                         var profile = postData.LoaderData?.Entry?.Profile?.Profile;
                //                         if (profile != null)
                //                         {
                //                             UserAlias = profile.Username;
                //                             if (string.IsNullOrEmpty(UserAlias) && !string.IsNullOrEmpty(profile.Name))
                //                             {
                //                                 UserAlias = profile.Name!.Replace(" ", "");
                //                             }
                //                             LogProgress(UserAlias, "User's alias");
                //                             UserName = profile.Name;
                //                             LogProgress(UserName, "User's name");
                //                             UserProfileUrl = profile.Url?.ToString();
                //                             LogProgress(UserProfileUrl, "User's profile URL");
                //                             UserBio = profile.Bio?.Replace("\\n", "\n").StripExtraSpaces(true);
                //                             LogProgress(UserBio, "User's BIO");
                //                         }
                //                         else
                //                         {
                //                             LogEntries.Add(new LogEntry("Failed to find the profile information, the account is likely private", Colors.Red));
                //                             LogEntries.Add(new LogEntry("Post must be handled manually in VERO app", Colors.Red));
                //                             // TODO andydragon : add post validation and mark it failed here...
                //                         }
                //                         var post = postData.LoaderData?.Entry?.Post?.Post;
                //                         if (post != null)
                //                         {
                //                             ShowDescription = true;
                //                             pageHashTags.Clear();
                //                             Description = post.Caption != null ? JoinSegments(post.Caption, pageHashTags).StripExtraSpaces() : "";
                //                             var pageTagFound = "";
                //                             if (pageHashTags.FirstOrDefault(hashTag =>
                //                             {
                //                                 return selectedPage.PageTags.FirstOrDefault(pageHashTag =>
                //                                 {
                //                                     if (string.Equals(hashTag, pageHashTag, StringComparison.OrdinalIgnoreCase))
                //                                     {
                //                                         pageTagFound = pageHashTag.ToLower();
                //                                         return true;
                //                                     }
                //                                     return false;
                //                                 }) != null;
                //                             }) != null)
                //                             {
                //                                 PageHashtagCheck = new ValidationResult(true, message: $"Contains page hashtag {pageTagFound}");
                //                                 LogEntries.Add(new LogEntry(PageHashtagCheck.Message!, defaultLogColor));
                //                             }
                //                             else
                //                             {
                //                                 PageHashtagCheck = new ValidationResult(false, "MISSING page hashtag");
                //                                 LogEntries.Add(new LogEntry(PageHashtagCheck.Error!, Colors.Red));
                //                             }
                //                             UpdateExcludedTags();

                //                             var imageUrls = post?.Images?.Select(image => image.Url).Where(url => url != null && url.ToString().StartsWith("https://"));
                //                             if (imageUrls?.Count() > 0)
                //                             {
                //                                 foreach (var imageUrl in imageUrls)
                //                                 {
                //                                     LogProgress(imageUrl!.ToString(), "Image source");
                //                                     ImageUrls.Add(new ImageEntry(imageUrl, userName ?? "unknown", this, notificationManager));
                //                                 }
                //                                 ShowImages = true;
                //                             }
                //                             else
                //                             {
                //                                 LogEntries.Add(new LogEntry("No images found in post", Colors.Red));
                //                             }

                //                             if (selectedPage.HubName == "snap" || selectedPage.HubName == "click")
                //                             {
                //                                 var comments = postData.LoaderData?.Entry?.Post?.Comments ?? [];
                //                                 var localPageComments = new List<CommentEntry>();
                //                                 var localHubComments = new List<CommentEntry>();
                //                                 foreach (var comment in comments)
                //                                 {
                //                                     var commentUserName = comment?.Author?.Username?.ToLower() ?? "";
                //                                     if (commentUserName.Equals(selectedPage.DisplayName, StringComparison.OrdinalIgnoreCase))
                //                                     {
                //                                         var commentSegments = JoinSegments(comment?.Content).StripExtraSpaces(true);
                //                                         localPageComments.Add(new CommentEntry(
                //                                             commentUserName,
                //                                             comment?.Timestamp,
                //                                             commentSegments,
                //                                             (page, timestamp) => { vm.SelectedFeature!.PhotoFeaturedOnPage = true; }));
                //                                         PageCommentsValidation = new ValidationResult(false, "Found page comments - possibly already featured on page");
                //                                         ShowComments = true;
                //                                         LogEntries.Add(new LogEntry($"Found page comment: {commentUserName} - {comment?.Timestamp?.FormatTimestamp()} - {commentSegments}", Colors.Red));
                //                                     }
                //                                     else if (commentUserName.StartsWith($"{selectedPage.HubName.ToLower()}_"))
                //                                     {
                //                                         var commentSegments = JoinSegments(comment?.Content).StripExtraSpaces(true);
                //                                         localHubComments.Add(new CommentEntry(
                //                                             commentUserName,
                //                                             comment?.Timestamp,
                //                                             commentSegments,
                //                                             (page, timestamp) =>
                //                                             {
                //                                                 vm.SelectedFeature!.PhotoFeaturedOnHub = true;
                //                                                 vm.SelectedFeature!.PhotoLastFeaturedPage = page[(selectedPage.HubName.Length + 1)..];
                //                                                 vm.SelectedFeature!.PhotoLastFeaturedOnHub = timestamp;
                //                                             }));
                //                                         HubCommentsValidation = new ValidationResult(false, "Found hub comments - possibly already featured on another page");
                //                                         ShowComments = true;
                //                                         LogEntries.Add(new LogEntry($"Found hub comment: {commentUserName} - {comment?.Timestamp?.FormatTimestamp()} - {commentSegments}", Colors.Orange));
                //                                     }
                //                                 }
                //                                 MoreComments = comments.Length < (post?.Comments ?? 0);
                //                                 if (MoreComments)
                //                                 {
                //                                     LogEntries.Add(new LogEntry("More comments!", Colors.Orange));
                //                                     ShowComments = true;
                //                                 }
                //                                 PageComments = [.. localPageComments];
                //                                 HubComments = [.. localHubComments];
                //                             }
                //                         }
                //                         else
                //                         {
                //                             LogEntries.Add(new LogEntry("Failed to find the post information, the account is likely private", Colors.Red));
                //                             LogEntries.Add(new LogEntry("Post must be handled manually in VERO app", Colors.Red));
                //                             // TODO andydragon : add post validation and mark it failed here...
                //                         }
                //                     }
                //                     else
                //                     {
                //                         LogEntries.Add(new LogEntry("Failed to parse the post JSON", Colors.Red));
                //                         // TODO andydragon : add post validation and mark it failed here...
                //                     }
                //                 }
                //             }
                //         }
                //     }
                // }
                // catch (Exception ex)
                // {
                //     LogEntries.Add(new LogEntry($"Could not load the post {ex.Message}", Colors.Red));
                // }
            }
        }
        catch (Exception ex)
        {
            // Do nothing, not vital
            Console.WriteLine("Error occurred: {0}", ex.Message);
        }
    }

    private void LogProgress(string? value, string label)
    {
        LogEntries.Add(string.IsNullOrEmpty(UserAlias)
            ? new LogEntry($"{label.ToLower()} not find", Colors.Red)
            : new LogEntry($"{label}: {value}", DefaultLogColor));
    }

    private static string JoinSegments(Segment[]? segments, List<string>? hashTags = null)
    {
        var builder = new StringBuilder();
        foreach (var segment in (segments ?? []))
        {
            switch (segment.Type)
            {
                case "text":
                    builder.Append(segment.Value);
                    break;

                case "tag":
                    builder.Append($"#{segment.Value}");
                    if (segment.Value != null)
                    {
                        hashTags?.Add(segment.Value);
                    }
                    break;

                case "person":
                    if (segment.Label != null)
                    {
                        builder.Append($"@{segment.Label}");
                    }
                    else
                    {
                        builder.Append(segment.Value);
                    }
                    break;

                case "url":
                    builder.Append(segment.Label ?? segment.Value);
                    break;
            }
        }
        return builder.ToString().Replace("\\n", "\n");
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
                // TransferUserAliasCommand.OnCanExecuteChanged();
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
                // TransferUserNameCommand.OnCanExecuteChanged();
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
                // CopyUserProfileUrlCommand.OnCanExecuteChanged();
                // LaunchUserProfileUrlCommand.OnCanExecuteChanged();
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

    public ObservableCollection<ImageEntry> ImageUrls { get; } = [];

    private bool showImages;
    public bool ShowImages
    {
        get => showImages;
        set => Set(ref showImages, value);
    }

    #endregion

    #region Image Validation

    private ImageValidationViewModel? imageValidation;
    public ImageValidationViewModel? ImageValidation
    {
        get => imageValidation;
        set
        {
            if (Set(ref imageValidation, value))
            {
                vm.TriggerTinEyeSource();
            }
        }
    }

    #endregion

    #region Commands

    public SimpleCommand CopyPostUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(vm.SelectedFeature?.PostLink))
        {
            _ = CopyTextToClipboard(vm.SelectedFeature.PostLink, "Copied the post URL to the clipboard");
        }
    }, () => !string.IsNullOrEmpty(vm.SelectedFeature?.PostLink));

    public SimpleCommand LaunchPostUrlCommand => new(() =>
    {
        if (!string.IsNullOrEmpty(vm.SelectedFeature?.PostLink))
        {
            // TODO andydragon
            // Process.Start(new ProcessStartInfo
            // {
            //     FileName = vm.SelectedFeature.PostLink,
            //     UseShellExecute = true
            // });
        }
    }, () => !string.IsNullOrEmpty(vm.SelectedFeature?.PostLink));

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
            // TODO andydragon
            // Process.Start(new ProcessStartInfo
            // {
            //     FileName = UserProfileUrl,
            //     UseShellExecute = true
            // });
        }
    }, () => !string.IsNullOrEmpty(UserProfileUrl));

    public SimpleCommand TransferUserAliasCommand => new(() =>
    {
        vm.SelectedFeature!.UserAlias = UserAlias!;
    }, () => !string.IsNullOrEmpty(UserAlias));

    public SimpleCommand TransferUserNameCommand => new(() =>
    {
        vm.SelectedFeature!.UserName = UserName!;
    }, () => !string.IsNullOrEmpty(UserName));

    public SimpleCommand CopyLogCommand => new(() =>
    {
        _ = CopyTextToClipboard(string.Join("\n", LogEntries.Select(entry => entry.Messsage)), "Copied the log messages to the clipboard");
    });

    #endregion

    private static async Task CopyTextToClipboard(string text, string successMessage)
    {
        await MainViewModel.TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
    }

    public void UpdateExcludedTags()
    {
        var excludedHashtags = vm.ExcludedTags.Split(",", StringSplitOptions.RemoveEmptyEntries);
        if (excludedHashtags.Length != 0)
        {
            ExcludedHashtagCheck = new ValidationResult(message: "Post does not contain any excluded hashtags");
            foreach (var excludedHashtag in excludedHashtags)
            {
                if (pageHashTags.IndexOf(excludedHashtag) != -1)
                {
                    ExcludedHashtagCheck = new ValidationResult(ValidationLevel.Error, error: $"Post contains excluded hashtag {excludedHashtag}");
                    LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, Colors.Red));
                    break;
                }
            }
            if (ExcludedHashtagCheck.Valid)
            {
                LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!, DefaultLogColor));
            }
        }
        else
        {
            ExcludedHashtagCheck = new ValidationResult(message: "There are no excluded hashtags");
            LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, DefaultLogColor));
        }
    }

    public void ValidateImage(ImageEntry imageEntry)
    {
        this.ImageValidation = new ImageValidationViewModel(vm, imageEntry);
        // vm.View = MainViewModel.ViewMode.ImageValidationView;
    }
}

public static partial class StringExtensions
{
    public static string StripExtraSpaces(this string source, bool stripNewlines = false)
    {
        if (stripNewlines)
        {
            return WhitespaceRegex().Replace(source, " ");
        }
        return string.Join("\n", source.Split('\n').Select(line => line.Trim().StripExtraSpaces(true)));
    }

    [GeneratedRegex("[\\s]+")]
    private static partial Regex WhitespaceRegex();
}

public static class DateTimeExtensions
{
    public static string FormatTimestamp(this DateTime source)
    {
        var delta = DateTime.Now - source.ToLocalTime();
        if (delta.TotalMinutes < 1)
        {
            return "Now";
        }
        if (delta.TotalMinutes < 60)
        {
            var minutes = (int)delta.TotalMinutes;
            var result = $"{minutes}m";
            return result;
        }
        if (delta.TotalHours < 24)
        {
            var hours = (int)delta.TotalHours;
            var result = $"{hours}h";
            return result;
        }
        if (delta.TotalDays < 7)
        {
            var days = (int)delta.TotalDays;
            var result = $"{days}d";
            return result;
        }
        if (source.Year == DateTime.Now.Year)
        {
            return source.ToString("MMM d");
        }
        return source.ToString("MMM d, yyyy");
    }
}

public class LogEntry(string message, Color? color = null, bool skipBullet = false) : NotifyPropertyChanged
{
    private Color? color = color;
    public Color? Color
    {
        get => color;
        set => Set(ref color, value);
    }

    private string message = message;
    public string Messsage
    {
        get => message;
        set => Set(ref message, value);
    }

    private bool skipBullet = skipBullet;
    public bool SkipBullet
    {
        get => skipBullet;
        set => Set(ref skipBullet, value);
    }
}

public class ImageEntry : NotifyPropertyChanged
{
    private readonly LoadedPostViewModel postVm;

    public ImageEntry(Uri source, string username, LoadedPostViewModel postVm)
    {
        this.postVm = postVm;
        Source = source;
        // frame = BitmapFrame.Create(source);
        // if (!frame.IsFrozen && frame.IsDownloading)
        // {
        //     frame.DownloadCompleted += (object? sender, EventArgs e) =>
        //     {
        //         Width = frame.PixelWidth;
        //         Height = frame.PixelHeight;
        //     };
        // }
        // else
        // {
        //     Width = frame.PixelWidth;
        //     Height = frame.PixelHeight;
        // }
    }

    public Uri Source { get; }

    // private readonly BitmapFrame frame;

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

    public SimpleCommand ValidateImageCommand => new(() =>
    {
        postVm.ValidateImage(this);
    });

    public SimpleCommand SaveImageCommand => new(() =>
    {
        // PngBitmapEncoder png = new();
        // png.Frames.Add(frame);
        // var veroSnapshotsFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "VERO");
        // if (!Directory.Exists(veroSnapshotsFolder))
        // {
        //     try
        //     {
        //         Directory.CreateDirectory(veroSnapshotsFolder);
        //     }
        //     catch (Exception ex)
        //     {
        //         notificationManager.Show(ex);
        //         return;
        //     }
        // }
        // try
        // {
        //     using var stream = File.Create(Path.Combine(veroSnapshotsFolder, $"{username}.png"));
        //     png.Save(stream);
        //     notificationManager.Show(
        //         "Saved image",
        //         $"Saved the image to the {veroSnapshotsFolder} folder",
        //         type: NotificationType.Success,
        //         areaName: "WindowArea",
        //         expirationTime: TimeSpan.FromSeconds(3));
        // }
        // catch (Exception ex)
        // {
        //     notificationManager.Show(ex);
        // }
    });

    public SimpleCommand CopyImageUrlCommand => new(() =>
    {
        _ = CopyTextToClipboard(Source.AbsoluteUri, "Copied image URL to clipboard");
    });

    public SimpleCommand LaunchImageCommand => new(() =>
    {
        // TODO andydragon
        // Process.Start(new ProcessStartInfo
        // {
        //     FileName = Source.AbsoluteUri,
        //     UseShellExecute = true
        // });
    });

    private static async Task CopyTextToClipboard(string text, string successMessage/*, NotificationManager notificationManager*/)
    {
        await MainViewModel.TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
    }
}

public class CommentEntry : NotifyPropertyChanged
{
    private readonly Action<string, string> markFeature;

    public CommentEntry(string page, DateTime? timestamp, string comment, Action<string, string> markFeature)
    {
        Page = page;
        Timestamp = timestamp?.FormatTimestamp() ?? "?";
        Comment = comment;
        this.markFeature = markFeature;
    }

    public string Page { get; }

    private string Timestamp { get; }

    public string Comment { get; }

    public SimpleCommand MarkFeatureCommand => new(() =>
    {
        markFeature(Page, this.Timestamp);
    });
}
