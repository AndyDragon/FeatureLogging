using System.Collections.ObjectModel;
using System.IO;
using System.Net.Http.Headers;
using System.Net.Http;
using System.Text;
using System.Windows.Media;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Windows.Input;
using System.Windows.Media.Imaging;

using HtmlAgilityPack;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Notification.Wpf;

namespace FeatureLogging
{
    public class DownloadedPostViewModel : NotifyPropertyChanged
    {
        static readonly Color? defaultLogColor = null;// Colors.Blue;
        private readonly HttpClient httpClient = new();
        private readonly NotificationManager notificationManager = new();
        private readonly MainViewModel vm;

        public DownloadedPostViewModel(MainViewModel vm)
        {
            this.vm = vm;

            #region Commands

            copyPostUrlCommand = new Command(() =>
            {
                if (!string.IsNullOrEmpty(vm.SelectedFeature?.PostLink))
                {
                    CopyTextToClipboard(vm.SelectedFeature.PostLink, "Copied the post URL to the clipboard", notificationManager);
                }
            }, () => !string.IsNullOrEmpty(vm.SelectedFeature?.PostLink));

            launchPostUrlCommand = new Command(() =>
            {
                if (!string.IsNullOrEmpty(vm.SelectedFeature?.PostLink))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = vm.SelectedFeature.PostLink,
                        UseShellExecute = true
                    });
                }
            }, () => !string.IsNullOrEmpty(vm.SelectedFeature?.PostLink));

            copyUserProfileUrlCommand = new Command(() =>
            {
                if (!string.IsNullOrEmpty(UserProfileUrl))
                {
                    CopyTextToClipboard(UserProfileUrl, "Copied the user profile URL to the clipboard", notificationManager);
                }
            }, () => !string.IsNullOrEmpty(UserProfileUrl));

            launchUserProfileUrlCommand = new Command(() =>
            {
                if (!string.IsNullOrEmpty(UserProfileUrl))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = UserProfileUrl,
                        UseShellExecute = true
                    });
                }
            }, () => !string.IsNullOrEmpty(UserProfileUrl));

            transferUserAliasCommand = new Command(() =>
            {
                vm.SelectedFeature!.UserAlias = UserAlias!;
            }, () => !string.IsNullOrEmpty(UserAlias));

            transferUserNameCommand = new Command(() =>
            {
                vm.SelectedFeature!.UserName = UserName!;
            }, () => !string.IsNullOrEmpty(UserName));

            copyLogCommand = new Command(() =>
            {
                CopyTextToClipboard(string.Join("\n", LogEntries.Select(entry => entry.Messsage)), "Copied the log messages to the clipboard", notificationManager);
            });

            #endregion

            // Load the post asyncly.
            _ = LoadPost();
        }

        private async Task LoadPost()
        {
            LogEntries.Clear();

            var postUrl = vm.SelectedFeature!.PostLink!;
            var selectedPage = vm.SelectedPage!;
            using var progress = notificationManager.ShowProgressBar(
                "Loading the post",
                ShowCancelButton: false,
                areaName: "WindowArea");
            await Task.Delay(TimeSpan.FromSeconds(0.5), progress.Cancel);
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                // Accept HTML result.
                httpClient.DefaultRequestHeaders.Accept.Clear();
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("text/html", 0.9));
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xhtml+xml", 0.9));
                httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml", 0.9));
                var postUri = new Uri(postUrl);
                progress.Report((20, "Waiting for server", null, null));
                var content = await httpClient.GetStringAsync(postUri);
                if (!string.IsNullOrEmpty(content))
                {
                    try
                    {
                        progress.Report((30, "Loaded the post contents", null, null));
                        var document = new HtmlDocument();
                        document.LoadHtml(content);
                        progress.Report((40, "Looking for script", null, null));
                        var scripts = document.DocumentNode.Descendants("script").ToArray();
                        foreach (var script in scripts)
                        {
                            var scriptText = script.InnerText.Trim();
                            if (!string.IsNullOrEmpty(scriptText))
                            {
                                if (scriptText.StartsWith("window.__staticRouterHydrationData = JSON.parse(\"") && scriptText.EndsWith("\");"))
                                {
                                    var prefixLength = "window.__staticRouterHydrationData = JSON.parse(\"".Length;
                                    var jsonString = string.Concat("\"", scriptText
                                        .AsSpan(prefixLength, scriptText.Length - (prefixLength + 3)), "\"");
                                    // Use JToken.Parse to convert from JSON encoded as a JSON string to the JSON.
                                    jsonString = (string)JToken.Parse(jsonString)!;
                                    var postData = PostData.FromJson(jsonString);
                                    if (postData != null)
                                    {
                                        var profile = postData.LoaderData?.Entry?.Profile?.Profile;
                                        if (profile != null)
                                        {
                                            UserAlias = profile.Username;
                                            if (string.IsNullOrEmpty(UserAlias) && !string.IsNullOrEmpty(profile.Name))
                                            {
                                                UserAlias = profile.Name!.Replace(" ", "");
                                            }
                                            LogProgress(UserAlias, "User's alias");
                                            UserName = profile.Name;
                                            LogProgress(UserName, "User's name");
                                            UserProfileUrl = profile.Url?.ToString();
                                            LogProgress(UserProfileUrl, "User's profile URL");
                                            UserBio = profile.Bio?.Replace("\\n", "\n").StripExtraSpaces(true);
                                            LogProgress(UserBio, "User's BIO");
                                        }
                                        else
                                        {
                                            LogEntries.Add(new LogEntry("Failed to find the profile information, the account is likely private", Colors.Red));
                                            LogEntries.Add(new LogEntry("Post must be handled manually in VERO app", Colors.Red));
                                            // TODO andydragon : add post validation and mark it failed here...
                                        }
                                        var post = postData.LoaderData?.Entry?.Post?.Post;
                                        if (post != null)
                                        {
                                            ShowDescription = true;
                                            pageHashTags.Clear();
                                            Description = post.Caption != null ? JoinSegments(post.Caption, pageHashTags).StripExtraSpaces() : "";
                                            var pageTagFound = "";
                                            if (pageHashTags.FirstOrDefault(hashTag =>
                                            {
                                                return selectedPage.PageTags.FirstOrDefault(pageHashTag =>
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
                                                PageHashtagCheck = new ValidationResult(true, message: $"Contains page hashtag {pageTagFound}");
                                                LogEntries.Add(new LogEntry(PageHashtagCheck.Message!, defaultLogColor));
                                            }
                                            else
                                            {
                                                PageHashtagCheck = new ValidationResult(false, "MISSING page hashtag");
                                                LogEntries.Add(new LogEntry(PageHashtagCheck.Error!, Colors.Red));
                                            }
                                            UpdateExcludedTags();

                                            var imageUrls = post?.Images?.Select(image => image.Url).Where(url => url != null && url.ToString().StartsWith("https://"));
                                            if (imageUrls?.Count() > 0)
                                            {
                                                foreach (var imageUrl in imageUrls)
                                                {
                                                    LogProgress(imageUrl!.ToString(), "Image source");
                                                    ImageEntries.Add(new ImageEntry(imageUrl, userName ?? "unknown", this, notificationManager));
                                                }
                                                ShowImages = true;
                                            }
                                            else
                                            {
                                                LogEntries.Add(new LogEntry("No images found in post", Colors.Red));
                                            }
                                            OnPropertyChanged(nameof(MultipleImages));

                                            if (selectedPage.HubName == "snap" || selectedPage.HubName == "click")
                                            {
                                                var comments = postData.LoaderData?.Entry?.Post?.Comments ?? [];
                                                var localPageComments = new List<CommentEntry>();
                                                var localHubComments = new List<CommentEntry>();
                                                foreach (var comment in comments)
                                                {
                                                    var commentUserName = comment?.Author?.Username?.ToLower() ?? "";
                                                    if (commentUserName.Equals(selectedPage.DisplayName, StringComparison.OrdinalIgnoreCase))
                                                    {
                                                        var commentSegments = JoinSegments(comment?.Content).StripExtraSpaces(true);
                                                        localPageComments.Add(new CommentEntry(
                                                            commentUserName,
                                                            comment?.Timestamp,
                                                            commentSegments,
                                                            (page, timestamp) => { vm.SelectedFeature!.PhotoFeaturedOnPage = true; }));
                                                        PageCommentsValidation = new ValidationResult(false, "Found page comments - possibly already featured on page");
                                                        ShowComments = true;
                                                        LogEntries.Add(new LogEntry($"Found page comment: {commentUserName} - {comment?.Timestamp?.FormatTimestamp()} - {commentSegments}", Colors.Red));
                                                    }
                                                    else if (commentUserName.StartsWith($"{selectedPage.HubName.ToLower()}_"))
                                                    {
                                                        var commentSegments = JoinSegments(comment?.Content).StripExtraSpaces(true);
                                                        localHubComments.Add(new CommentEntry(
                                                            commentUserName,
                                                            comment?.Timestamp,
                                                            commentSegments,
                                                            (page, timestamp) =>
                                                            {
                                                                vm.SelectedFeature!.PhotoFeaturedOnHub = true;
                                                                vm.SelectedFeature!.PhotoLastFeaturedPage = page[(selectedPage.HubName.Length + 1)..];
                                                                vm.SelectedFeature!.PhotoLastFeaturedOnHub = timestamp;
                                                            }));
                                                        HubCommentsValidation = new ValidationResult(false, "Found hub comments - possibly already featured on another page");
                                                        ShowComments = true;
                                                        LogEntries.Add(new LogEntry($"Found hub comment: {commentUserName} - {comment?.Timestamp?.FormatTimestamp()} - {commentSegments}", Colors.Orange));
                                                    }
                                                }
                                                MoreComments = comments.Length < (post?.Comments ?? 0);
                                                if (MoreComments)
                                                {
                                                    LogEntries.Add(new LogEntry("More comments!", Colors.Orange));
                                                    ShowComments = true;
                                                }
                                                PageComments = [.. localPageComments];
                                                HubComments = [.. localHubComments];
                                            }
                                        }
                                        else
                                        {
                                            LogEntries.Add(new LogEntry("Failed to find the post information, the account is likely private", Colors.Red));
                                            LogEntries.Add(new LogEntry("Post must be handled manually in VERO app", Colors.Red));
                                            // TODO andydragon : add post validation and mark it failed here...
                                        }
                                    }
                                    else
                                    {
                                        LogEntries.Add(new LogEntry("Failed to parse the post JSON", Colors.Red));
                                        // TODO andydragon : add post validation and mark it failed here...
                                    }
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        LogEntries.Add(new LogEntry($"Could not load the post {ex.Message}", Colors.Red));
                    }
                }
            }
            catch (Exception ex)
            {
                // Do nothing, not vital
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
            progress.Report((100, null, null, null));
        }

        private void LogProgress(string? value, string label)
        {
            if (string.IsNullOrEmpty(UserAlias))
            {
                LogEntries.Add(new LogEntry($"{label.ToLower()} not find", Colors.Red));
            }
            else
            {
                LogEntries.Add(new LogEntry($"{label}: {value}", defaultLogColor));
            }
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
                        if (segment.Label != null)
                        {
                            builder.Append(segment.Label);
                        }
                        else
                        {
                            builder.Append(segment.Value);
                        }
                        break;
                }
            }
            return builder.ToString().Replace("\\n", "\n");
        }

        private readonly List<string> pageHashTags = [];

        #region Logging

        private readonly ObservableCollection<LogEntry> logEntries = [];
        public ObservableCollection<LogEntry> LogEntries { get => logEntries; }

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
                    UserAliasValidation = ValidateUserAlias(userAlias);
                    TransferUserAliasCommand.OnCanExecuteChanged();
                }
            }
        }

        private ValidationResult userAliasValidation = ValidateUserAlias(null);
        public ValidationResult UserAliasValidation
        {
            get => userAliasValidation;
            private set => Set(ref userAliasValidation, value);
        }
        static private ValidationResult ValidateUserAlias(string? userAlias)
        {
            if (string.IsNullOrEmpty(userAlias))
            {
                return new ValidationResult(false, "Missing the user alias");
            }
            return new ValidationResult(true);
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
                    UserNameValidation = ValidateUserName(userName);
                    TransferUserNameCommand.OnCanExecuteChanged();
                }
            }
        }

        private ValidationResult userNameValidation = ValidateUserName(null);
        public ValidationResult UserNameValidation
        {
            get => userNameValidation;
            private set => Set(ref userNameValidation, value);
        }
        static private ValidationResult ValidateUserName(string? userName)
        {
            if (string.IsNullOrEmpty(userName))
            {
                return new ValidationResult(false, "Missing the user name");
            }
            return new ValidationResult(true);
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
                    UserProfileUrlValidation = ValidateUserProfileUrl(userProfileUrl);
                    CopyUserProfileUrlCommand.OnCanExecuteChanged();
                    LaunchUserProfileUrlCommand.OnCanExecuteChanged();
                }
            }
        }

        private ValidationResult userProfileUrlValidation = ValidateUserProfileUrl(null);
        public ValidationResult UserProfileUrlValidation
        {
            get => userProfileUrlValidation;
            private set => Set(ref userProfileUrlValidation, value);
        }
        static private ValidationResult ValidateUserProfileUrl(string? userProfileUrl)
        {
            if (string.IsNullOrEmpty(userProfileUrl))
            {
                return new ValidationResult(false, "Missing the user profile URL");
            }
            if (!userProfileUrl.StartsWith("https://vero.co/"))
            {
                return new ValidationResult(false, "User profile URL does not point to VERO");
            }
            return new ValidationResult(true);
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

        private bool showDescription = false;
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

        private ValidationResult pageHashtagCheck = new(true);
        public ValidationResult PageHashtagCheck
        {
            get => pageHashtagCheck;
            set => Set(ref pageHashtagCheck, value);
        }

        private ValidationResult excludedHashtagCheck = new(true);
        public ValidationResult ExcludedHashtagCheck
        {
            get => excludedHashtagCheck;
            set => Set(ref excludedHashtagCheck, value);
        }

        #endregion

        #region Comments

        private bool showComments = false;
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

        private ValidationResult pageCommentsValidation = new(true);
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

        private ValidationResult hubCommentsValidation = new(true);
        public ValidationResult HubCommentsValidation
        {
            get => hubCommentsValidation;
            set => Set(ref hubCommentsValidation, value);
        }

        private bool moreComments = false;
        public bool MoreComments
        {
            get => moreComments;
            private set => Set(ref moreComments, value);
        }

        #endregion

        #region Images

        private readonly ObservableCollection<ImageEntry> imageEntries = [];
        public ObservableCollection<ImageEntry> ImageEntries { get => imageEntries; }

        private bool showImages = false;
        public bool ShowImages
        {
            get => showImages;
            set => Set(ref showImages, value);
        }

        public bool MultipleImages => ImageEntries.Count > 1;

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

        private readonly Command copyPostUrlCommand;
        public Command CopyPostUrlCommand { get => copyPostUrlCommand; }

        private readonly Command launchPostUrlCommand;
        public Command LaunchPostUrlCommand { get => launchPostUrlCommand; }

        private readonly Command copyUserProfileUrlCommand;
        public Command CopyUserProfileUrlCommand { get => copyUserProfileUrlCommand; }

        private readonly Command launchUserProfileUrlCommand;
        public Command LaunchUserProfileUrlCommand { get => launchUserProfileUrlCommand; }

        private readonly Command transferUserAliasCommand;
        public Command TransferUserAliasCommand { get => transferUserAliasCommand; }

        private readonly Command transferUserNameCommand;
        public Command TransferUserNameCommand { get => transferUserNameCommand; }

        private readonly Command copyLogCommand;
        public Command CopyLogCommand { get => copyLogCommand; }

        #endregion

        private static void CopyTextToClipboard(string text, string successMessage, NotificationManager notificationManager)
        {
            if (MainViewModel.TrySetClipboardText(text))
            {
                notificationManager.Show(
                    "Copied script",
                    successMessage,
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                notificationManager.Show(
                    "Failed to copy script",
                    "Could not copy script to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(12));
            }
        }

        public void UpdateExcludedTags()
        {
            var excludedHashtags = vm.ExcludedTags.Split(",", StringSplitOptions.RemoveEmptyEntries);
            if (excludedHashtags.Length != 0)
            {
                ExcludedHashtagCheck = new ValidationResult(true, message: "Post does not contain any excluded hashtags");
                foreach (var excludedHashtag in excludedHashtags)
                {
                    if (pageHashTags.IndexOf(excludedHashtag) != -1)
                    {
                        ExcludedHashtagCheck = new ValidationResult(false, error: $"Post contains excluded hashtag {excludedHashtag}");
                        LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, Colors.Red));
                        break;
                    }
                }
                if (ExcludedHashtagCheck.Valid)
                {
                    LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!, defaultLogColor));
                }
            }
            else
            {
                ExcludedHashtagCheck = new ValidationResult(true, message: "There are no excluded hashtags");
                LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, defaultLogColor));
            }
        }

        public void ValidateImage(ImageEntry imageEntry)
        {
            this.ImageValidation = new ImageValidationViewModel(vm, imageEntry);
            vm.View = MainViewModel.ViewMode.ImageValidationView;
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

    public static partial class DateTimeExtensions
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
        private readonly DownloadedPostViewModel postVm;

        public ImageEntry(Uri source, string username, DownloadedPostViewModel postVm, NotificationManager notificationManager)
        {
            this.postVm = postVm;
            this.source = source;
            frame = BitmapFrame.Create(source);
            if (!frame.IsFrozen && frame.IsDownloading)
            {
                frame.DownloadCompleted += (object? sender, EventArgs e) =>
                {
                    Width = frame.PixelWidth;
                    Height = frame.PixelHeight;
                };
            }
            else
            {
                Width = frame.PixelWidth;
                Height = frame.PixelHeight;
            }

            ValidateImageCommand = new Command(() =>
            {
                this.postVm.ValidateImage(this);
            });
            saveImageCommand = new Command(() =>
            {
                PngBitmapEncoder png = new();
                png.Frames.Add(frame);
                var veroSnapshotsFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "VERO");
                if (!Directory.Exists(veroSnapshotsFolder))
                {
                    try
                    {
                        Directory.CreateDirectory(veroSnapshotsFolder);
                    }
                    catch (Exception ex)
                    {
                        notificationManager.Show(ex);
                        return;
                    }
                }
                try
                {
                    using var stream = File.Create(Path.Combine(veroSnapshotsFolder, $"{username}.png"));
                    png.Save(stream);
                    notificationManager.Show(
                        "Saved image",
                        $"Saved the image to the {veroSnapshotsFolder} folder",
                        type: NotificationType.Success,
                        areaName: "WindowArea",
                        expirationTime: TimeSpan.FromSeconds(3));
                }
                catch (Exception ex)
                {
                    notificationManager.Show(ex);
                }
            });
            copyImageUrlCommand = new Command(() =>
            {
                CopyTextToClipboard(source.AbsoluteUri, "Copied image URL to clipboard", notificationManager);
            });
            launchImageCommand = new Command(() =>
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = source.AbsoluteUri,
                    UseShellExecute = true
                });
            });
        }

        private readonly Uri source;
        public Uri Source
        {
            get => source;
        }

        private readonly BitmapFrame frame;

        private int width = 0;
        public int Width
        {
            get => width;
            private set => Set(ref width, value);
        }

        private int height = 0;
        public int Height
        {
            get => height;
            private set => Set(ref height, value);
        }

        public ICommand ValidateImageCommand { get; }

        private readonly ICommand saveImageCommand;
        public ICommand SaveImageCommand { get => saveImageCommand; }

        private readonly ICommand copyImageUrlCommand;
        public ICommand CopyImageUrlCommand { get => copyImageUrlCommand; }

        private readonly ICommand launchImageCommand;
        public ICommand LaunchImageCommand { get => launchImageCommand; }

        private static void CopyTextToClipboard(string text, string successMessage, NotificationManager notificationManager)
        {
            if (MainViewModel.TrySetClipboardText(text))
            {
                notificationManager.Show(
                    "Copied script",
                    successMessage,
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                notificationManager.Show(
                    "Failed to copy script",
                    "Could not copy script to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(12));
            }
        }
    }

    public class CommentEntry : NotifyPropertyChanged
    {
        public CommentEntry(string page, DateTime? timestamp, string comment, Action<string, string> markFeature)
        {
            this.page = page;
            this.timestamp = timestamp?.FormatTimestamp() ?? "?";
            this.comment = comment;
            markFeatureCommand = new Command(() =>
            {
                markFeature(page, this.timestamp);
            });
        }

        private readonly string page;
        public string Page { get => page; }

        private readonly string timestamp;
        public string Timestamp { get => timestamp; }

        private readonly string comment;
        public string Comment { get => comment; }

        private readonly Command markFeatureCommand;
        public Command MarkFeatureCommand { get => markFeatureCommand; }
    }

    #region Post JSON

    public partial class PostData
    {
        public static PostData? FromJson(string json) => JsonConvert.DeserializeObject<PostData>(json);
    }

    public partial class PostData
    {
        [JsonProperty("loaderData", NullValueHandling = NullValueHandling.Ignore)]
        public LoaderData? LoaderData { get; set; }
    }

    public partial class LoaderData
    {
        [JsonProperty("0-1", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry1 { get; set; }

        [JsonProperty("0-2", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry2 { get; set; }

        [JsonProperty("0-3", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry3 { get; set; }

        [JsonProperty("0-4", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry4 { get; set; }

        [JsonProperty("0-5", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry5 { get; set; }

        public PostEntry? Entry
        {
            get => Entry1 ?? Entry2 ?? Entry3 ?? Entry4 ?? Entry5;
        }
    }

    public partial class PostEntry
    {
        [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
        public EntryProfile? Profile { get; set; }

        [JsonProperty("post", NullValueHandling = NullValueHandling.Ignore)]
        public EntryPost? Post { get; set; }
    }

    public partial class EntryProfile
    {
        [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
        public Profile? Profile { get; set; }
    }

    public partial class Profile
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("firstname", NullValueHandling = NullValueHandling.Ignore)]
        public string? Name { get; set; }

        [JsonProperty("picture", NullValueHandling = NullValueHandling.Ignore)]
        public Picture? Picture { get; set; }

        [JsonProperty("username", NullValueHandling = NullValueHandling.Ignore)]
        public string? Username { get; set; }

        [JsonProperty("bio", NullValueHandling = NullValueHandling.Ignore)]
        public string? Bio { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public partial class Picture
    {
        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public partial class EntryPost
    {
        [JsonProperty("post", NullValueHandling = NullValueHandling.Ignore)]
        public Post? Post { get; set; }

        [JsonProperty("comments", NullValueHandling = NullValueHandling.Ignore)]
        public Comment[]? Comments { get; set; }
    }

    public partial class Post
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("author", NullValueHandling = NullValueHandling.Ignore)]
        public Author? Author { get; set; }

        [JsonProperty("title", NullValueHandling = NullValueHandling.Ignore)]
        public string? Title { get; set; }

        [JsonProperty("caption", NullValueHandling = NullValueHandling.Ignore)]
        public Segment[]? Caption { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }

        [JsonProperty("images", NullValueHandling = NullValueHandling.Ignore)]
        public PostImage[]? Images { get; set; }

        [JsonProperty("likes", NullValueHandling = NullValueHandling.Ignore)]
        public int? Likes { get; set; }

        [JsonProperty("comments", NullValueHandling = NullValueHandling.Ignore)]
        public int? Comments { get; set; }

        [JsonProperty("views", NullValueHandling = NullValueHandling.Ignore)]
        public int? Views { get; set; }

        [JsonProperty("timestamp", NullValueHandling = NullValueHandling.Ignore)]
        public DateTime? Timestamp { get; set; }
    }

    public partial class Comment
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("text", NullValueHandling = NullValueHandling.Ignore)]
        public string? Text { get; set; }

        [JsonProperty("timestamp", NullValueHandling = NullValueHandling.Ignore)]
        public DateTime? Timestamp { get; set; }

        [JsonProperty("author", NullValueHandling = NullValueHandling.Ignore)]
        public Author? Author { get; set; }

        [JsonProperty("content", NullValueHandling = NullValueHandling.Ignore)]
        public Segment[]? Content { get; set; }
    }

    public partial class Author
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("firstname", NullValueHandling = NullValueHandling.Ignore)]
        public string? Name { get; set; }

        [JsonProperty("username", NullValueHandling = NullValueHandling.Ignore)]
        public string? Username { get; set; }

        [JsonProperty("picture", NullValueHandling = NullValueHandling.Ignore)]
        public Picture? Picture { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public partial class Segment
    {
        // "text", "tag", "person", "url"
        [JsonProperty("type", NullValueHandling = NullValueHandling.Ignore)]
        public string? Type { get; set; }

        [JsonProperty("value", NullValueHandling = NullValueHandling.Ignore)]
        public string? Value { get; set; }

        [JsonProperty("label", NullValueHandling = NullValueHandling.Ignore)]
        public string? Label { get; set; }

        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public partial class PostImage
    {
        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    #endregion
}
