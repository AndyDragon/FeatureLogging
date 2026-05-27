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
            ImageEntries.Clear();
            PageComments = [];
            HubComments = [];
            ShowDescription = false;
            ShowComments = false;
            ShowImages = false;
            MoreComments = false;
            PageHashtagCheck = new ValidationResult(ValidationResultType.Valid);
            ExcludedHashtagCheck = new ValidationResult(ValidationResultType.Valid);
            PostDataMode = "unknown";

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
                        progress.Report((40, "Parsing post data", null, null));

                        var parsedPayload = ParsePayload(content);
                        PostDataMode = DerivePostDataMode(parsedPayload);

                        if (parsedPayload.Profile != null)
                        {
                            UserAlias = parsedPayload.Profile.Alias;
                            UserName = parsedPayload.Profile.Name;
                            UserProfileUrl = parsedPayload.Profile.Url;
                            UserBio = parsedPayload.Profile.Bio;

                            if (string.IsNullOrWhiteSpace(vm.SelectedFeature?.UserAlias) && !string.IsNullOrWhiteSpace(UserAlias))
                            {
                                vm.SelectedFeature!.UserAlias = UserAlias!;
                            }
                            if (string.IsNullOrWhiteSpace(vm.SelectedFeature?.UserName) && !string.IsNullOrWhiteSpace(UserName))
                            {
                                vm.SelectedFeature!.UserName = UserName!;
                            }

                            LogEntries.Add(new LogEntry($"Profile source: {parsedPayload.ProfileSource}", defaultLogColor));
                            LogProgress(UserAlias, "User's alias");
                            LogProgress(UserName, "User's name");
                            LogProgress(UserProfileUrl, "User's profile URL");
                            LogProgress(UserBio, "User's BIO");
                        }
                        else
                        {
                            LogEntries.Add(new LogEntry("Profile data was not found in the selected data mode", Colors.Orange));
                        }

                        if (parsedPayload.Post != null)
                        {
                            ShowDescription = true;
                            pageHashTags.Clear();
                            pageHashTags.AddRange(parsedPayload.Post.HashTags);
                            Description = parsedPayload.Post.Description;
                            LogEntries.Add(new LogEntry($"Post source: {parsedPayload.PostSource}", defaultLogColor));

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
                                PageHashtagCheck = new ValidationResult(ValidationResultType.Valid, message: $"Contains page hashtag {pageTagFound}");
                                LogEntries.Add(new LogEntry(PageHashtagCheck.Message!, defaultLogColor));
                            }
                            else
                            {
                                PageHashtagCheck = new ValidationResult(ValidationResultType.Error, "MISSING page hashtag");
                                LogEntries.Add(new LogEntry(PageHashtagCheck.Error!, Colors.Red));
                            }

                            UpdateExcludedTags();

                            foreach (var imageUrl in parsedPayload.Post.ImageUrls)
                            {
                                LogProgress(imageUrl, "Image source");
                                ImageEntries.Add(new ImageEntry(new Uri(imageUrl), userName ?? "unknown", this, notificationManager));
                            }
                            if (ImageEntries.Count > 0)
                            {
                                CurrentImageEntry = 0;
                                ShowImages = true;
                            }
                            else
                            {
                                LogEntries.Add(new LogEntry("No images found in post", Colors.Red));
                            }
                            OnPropertyChanged(nameof(MultipleImages));

                            ApplyComments(parsedPayload.Post, selectedPage);
                        }
                        else
                        {
                            LogEntries.Add(new LogEntry("Post data was not found in the selected data mode", Colors.Orange));
                        }

                        if (parsedPayload.Profile == null && parsedPayload.Post == null)
                        {
                            LogEntries.Add(new LogEntry("Failed to find the profile or post information", Colors.Red));
                            LogEntries.Add(new LogEntry("Post must be handled manually in VERO app", Colors.Red));
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

        private sealed class ParsedProfilePayload
        {
            public required string Alias { get; init; }
            public required string Name { get; init; }
            public required string Url { get; init; }
            public required string Bio { get; init; }
        }

        private sealed class ParsedCommentPayload
        {
            public required string UserName { get; init; }
            public required string AuthorName { get; init; }
            public required string Text { get; init; }
            public DateTime? Timestamp { get; init; }
        }

        private sealed class ParsedPostPayload
        {
            public required string Description { get; init; }
            public required List<string> HashTags { get; init; }
            public required List<string> ImageUrls { get; init; }
            public required List<ParsedCommentPayload> Comments { get; init; }
            public required bool CommentsAvailable { get; init; }
            public required int CommentCount { get; init; }
            public required int LikeCount { get; init; }
        }

        private sealed class ParsedPostLoadPayload
        {
            public ParsedProfilePayload? Profile { get; init; }
            public ParsedPostPayload? Post { get; init; }
            public required string ProfileSource { get; init; }
            public required string PostSource { get; init; }
        }

        private enum DecodeMode
        {
            JsonDoubleQuotedString,
            JavaScriptSingleQuotedString,
        }

        private ParsedPostLoadPayload ParsePayload(string content)
        {
            LogEntries.Add(new LogEntry("Using auto parser (new + legacy fallback)", defaultLogColor));

            ParsedPostLoadPayload? reactPayload = null;
            ParsedPostLoadPayload? legacyPayload = null;
            Exception? reactException = null;
            Exception? legacyException = null;

            try
            {
                reactPayload = ParseReactPayload(content);
            }
            catch (Exception ex)
            {
                reactException = ex;
            }

            try
            {
                legacyPayload = ParseLegacyPayload(content);
            }
            catch (Exception ex)
            {
                legacyException = ex;
            }

            var merged = new ParsedPostLoadPayload
            {
                Profile = reactPayload?.Profile ?? legacyPayload?.Profile,
                Post = reactPayload?.Post ?? legacyPayload?.Post,
                ProfileSource = reactPayload?.Profile != null ? "new" : (legacyPayload?.Profile != null ? "legacy" : "unavailable"),
                PostSource = reactPayload?.Post != null ? "new" : (legacyPayload?.Post != null ? "legacy" : "unavailable")
            };

            if (merged.Profile == null && reactException != null)
            {
                LogEntries.Add(new LogEntry($"New parser did not return profile: {reactException.Message}", Colors.Orange));
            }
            if (merged.Post == null && reactException != null)
            {
                LogEntries.Add(new LogEntry($"New parser did not return post: {reactException.Message}", Colors.Orange));
            }
            if (merged.Profile == null && legacyException != null)
            {
                LogEntries.Add(new LogEntry($"Legacy parser did not return profile: {legacyException.Message}", Colors.Orange));
            }
            if (merged.Post == null && legacyException != null)
            {
                LogEntries.Add(new LogEntry($"Legacy parser did not return post: {legacyException.Message}", Colors.Orange));
            }

            return merged;
        }

        private static string DerivePostDataMode(ParsedPostLoadPayload payload)
        {
            if (payload.ProfileSource == "new" || payload.PostSource == "new")
            {
                return "new";
            }
            if (payload.ProfileSource == "legacy" || payload.PostSource == "legacy")
            {
                return "legacy";
            }
            return "unknown";
        }

        private ParsedPostLoadPayload ParseLegacyPayload(string content)
        {
            var jsonString = ExtractLegacyHydrationJson(content);
            var postData = PostData.FromJson(jsonString) ?? throw new InvalidOperationException("Failed to parse legacy post data");
            var postData2 = PostData2.FromJson(jsonString);

            var profile = postData.LoaderData?.Entry?.Profile?.Profile ?? postData2?.LoaderData?.Entry?.Profile;
            ParsedProfilePayload? parsedProfile = null;
            if (profile != null)
            {
                var firstName = (profile.Name ?? string.Empty).Trim();
                var fallbackUserName = (profile.Username ?? string.Empty).Trim();
                var resolvedName = string.IsNullOrEmpty(firstName) ? fallbackUserName : firstName;
                var alias = string.IsNullOrEmpty(fallbackUserName) ? firstName.Replace(" ", string.Empty) : fallbackUserName;
                parsedProfile = new ParsedProfilePayload
                {
                    Alias = alias,
                    Name = resolvedName,
                    Url = profile.Url?.ToString() ?? string.Empty,
                    Bio = (profile.Bio ?? string.Empty).Replace("\\n", "\n").StripExtraSpaces(true)
                };
            }

            ParsedPostPayload? parsedPost = null;
            var entryPost = postData.LoaderData?.Entry?.Post;
            var post = entryPost?.Post;
            if (post != null)
            {
                var hashTags = new List<string>();
                var description = JoinSegments(post.Caption, hashTags).StripExtraSpaces();
                var imageUrls = (post.Images ?? [])
                    .Select(image => image?.Url?.ToString() ?? string.Empty)
                    .Where(url => url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                    .ToList();

                var comments = new List<ParsedCommentPayload>();
                foreach (var comment in entryPost?.Comments ?? [])
                {
                    var commentUserName = comment?.Author?.Username;
                    if (string.IsNullOrWhiteSpace(commentUserName))
                    {
                        continue;
                    }
                    comments.Add(new ParsedCommentPayload
                    {
                        UserName = commentUserName,
                        AuthorName = string.IsNullOrWhiteSpace(comment.Author?.Name) ? commentUserName : comment.Author!.Name!,
                        Text = JoinSegments(comment.Content).StripExtraSpaces(true),
                        Timestamp = comment.Timestamp
                    });
                }

                parsedPost = new ParsedPostPayload
                {
                    Description = description,
                    HashTags = hashTags,
                    ImageUrls = imageUrls,
                    Comments = comments,
                    CommentsAvailable = entryPost?.Comments != null,
                    CommentCount = post.Comments ?? 0,
                    LikeCount = post.Likes ?? 0
                };
            }

            return new ParsedPostLoadPayload
            {
                Profile = parsedProfile,
                Post = parsedPost,
                ProfileSource = "legacy",
                PostSource = "legacy"
            };
        }

        private ParsedPostLoadPayload ParseReactPayload(string content)
        {
            var reactDataArray = ExtractReactDataArray(content);
            var reactData = new ReactData(reactDataArray);

            var userPost = reactData.LoaderData?.UserPost;
            var postOnly = reactData.LoaderData?.PostOnly;

            var profile = userPost?.Profile ?? postOnly?.Profile;
            ParsedProfilePayload? parsedProfile = null;
            if (profile != null)
            {
                var firstName = (profile.FirstName ?? string.Empty).Trim();
                var fallbackUserName = (profile.UserName ?? string.Empty).Trim();
                var resolvedName = string.IsNullOrEmpty(firstName) ? fallbackUserName : firstName;
                var alias = string.IsNullOrEmpty(fallbackUserName) ? resolvedName.Replace(" ", string.Empty) : fallbackUserName;
                parsedProfile = new ParsedProfilePayload
                {
                    Alias = alias,
                    Name = resolvedName,
                    Url = profile.Url ?? string.Empty,
                    Bio = (profile.Bio ?? string.Empty).Replace("\\n", "\n").StripExtraSpaces(true)
                };
            }

            ParsedPostPayload? parsedPost = null;
            var reactPostContainer = userPost?.Post ?? postOnly?.Post;
            var reactPost = reactPostContainer?.Post;
            if (reactPost != null)
            {
                var hashTags = new List<string>();
                var description = JoinReactContent(reactPost.Caption, hashTags).StripExtraSpaces();
                var imageUrls = reactPost.Images
                    .Select(image => image.Url)
                    .Where(url => !string.IsNullOrWhiteSpace(url) && url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                    .ToList()!;

                var comments = new List<ParsedCommentPayload>();
                foreach (var comment in reactPostContainer?.Comments ?? [])
                {
                    var author = comment.Author;
                    if (author == null || string.IsNullOrWhiteSpace(author.UserName))
                    {
                        continue;
                    }
                    comments.Add(new ParsedCommentPayload
                    {
                        UserName = author.UserName,
                        AuthorName = string.IsNullOrWhiteSpace(author.FirstName) ? author.UserName : author.FirstName,
                        Text = JoinReactContent(comment.Content).StripExtraSpaces(true),
                        Timestamp = comment.Timestamp == DateTime.MinValue ? null : comment.Timestamp
                    });
                }

                parsedPost = new ParsedPostPayload
                {
                    Description = description,
                    HashTags = hashTags,
                    ImageUrls = imageUrls,
                    Comments = comments,
                    CommentsAvailable = reactPostContainer?.Properties.ContainsKey("comments") == true,
                    CommentCount = (int)reactPost.Comments,
                    LikeCount = (int)reactPost.Likes
                };
            }

            return new ParsedPostLoadPayload
            {
                Profile = parsedProfile,
                Post = parsedPost,
                ProfileSource = "new",
                PostSource = "new"
            };
        }

        private static string ExtractLegacyHydrationJson(string content)
        {
            var document = new HtmlDocument();
            document.LoadHtml(content);
            foreach (var script in document.DocumentNode.Descendants("script"))
            {
                var scriptText = script.InnerText.Trim();
                if (string.IsNullOrWhiteSpace(scriptText))
                {
                    continue;
                }
                if (scriptText.StartsWith("window.__staticRouterHydrationData = JSON.parse(\"") && scriptText.EndsWith("\");"))
                {
                    var prefixLength = "window.__staticRouterHydrationData = JSON.parse(\"".Length;
                    var encoded = string.Concat("\"", scriptText.AsSpan(prefixLength, scriptText.Length - (prefixLength + 3)), "\"");
                    return (string)JToken.Parse(encoded)!;
                }
            }

            throw new InvalidOperationException("Could not find hydration data script");
        }

        private static dynamic[] ExtractReactDataArray(string content)
        {
            var strategies = new (string Pattern, DecodeMode Mode)[]
            {
                ("window\\.__reactRouterContext\\.streamController\\.enqueue\\(\"((?:\\\\.|[^\"\\\\])*)\"\\);", DecodeMode.JsonDoubleQuotedString),
                ("__reactRouterContext\\.streamController\\.enqueue\\(\"((?:\\\\.|[^\"\\\\])*)\"\\);", DecodeMode.JsonDoubleQuotedString),
                ("streamController\\.enqueue\\(\"((?:\\\\.|[^\"\\\\])*)\"\\);", DecodeMode.JsonDoubleQuotedString),
                ("streamController\\.enqueue\\('((?:\\\\.|[^'\\\\])*)'\\);", DecodeMode.JavaScriptSingleQuotedString),
                ("streamController\\.enqueue\\(JSON\\.parse\\(\"((?:\\\\.|[^\"\\\\])*)\"\\)\\);", DecodeMode.JsonDoubleQuotedString),
                ("streamController\\.enqueue\\(JSON\\.parse\\('((?:\\\\.|[^'\\\\])*)'\\)\\);", DecodeMode.JavaScriptSingleQuotedString),
            };

            foreach (var strategy in strategies)
            {
                var regex = new Regex(strategy.Pattern, RegexOptions.Singleline);
                var matches = regex.Matches(content);
                foreach (Match match in matches)
                {
                    if (match.Groups.Count < 2)
                    {
                        continue;
                    }
                    var payload = match.Groups[1].Value;
                    var array = ParseReactArray(payload, strategy.Mode);
                    if (array != null && array.Length > 1)
                    {
                        return array;
                    }
                }
            }

            throw new InvalidOperationException("Could not find react data script");
        }

        private static dynamic[]? ParseReactArray(string payload, DecodeMode mode)
        {
            string decoded;
            switch (mode)
            {
                case DecodeMode.JsonDoubleQuotedString:
                    decoded = DecodeJsonEncodedString(payload);
                    break;
                case DecodeMode.JavaScriptSingleQuotedString:
                    decoded = DecodeSingleQuotedJavaScriptString(payload);
                    break;
                default:
                    return null;
            }

            var token = JToken.Parse(decoded);
            if (token is not JArray array)
            {
                return null;
            }
            return array.ToObject<dynamic[]>();
        }

        private static string DecodeJsonEncodedString(string payload)
        {
            return JsonConvert.DeserializeObject<string>($"\"{payload}\"") ?? string.Empty;
        }

        private static string DecodeSingleQuotedJavaScriptString(string payload)
        {
            var output = new StringBuilder();
            for (var i = 0; i < payload.Length; i++)
            {
                var ch = payload[i];
                if (ch != '\\')
                {
                    output.Append(ch);
                    continue;
                }

                i++;
                if (i >= payload.Length)
                {
                    break;
                }

                var escape = payload[i];
                switch (escape)
                {
                    case 'n': output.Append('\n'); break;
                    case 'r': output.Append('\r'); break;
                    case 't': output.Append('\t'); break;
                    case 'b': output.Append('\b'); break;
                    case 'f': output.Append('\f'); break;
                    case '\\': output.Append('\\'); break;
                    case '"': output.Append('"'); break;
                    case '\'': output.Append('\''); break;
                    case '/': output.Append('/'); break;
                    case 'u':
                        if (i + 4 < payload.Length)
                        {
                            var hex = payload.Substring(i + 1, 4);
                            if (int.TryParse(hex, System.Globalization.NumberStyles.HexNumber, null, out var scalar))
                            {
                                output.Append((char)scalar);
                                i += 4;
                            }
                        }
                        break;
                    default:
                        output.Append(escape);
                        break;
                }
            }

            return output.ToString();
        }

        private void ApplyComments(ParsedPostPayload post, LoadedPage selectedPage)
        {
            if (selectedPage.HubName != "snap" && selectedPage.HubName != "click")
            {
                PageComments = [];
                HubComments = [];
                ShowComments = false;
                MoreComments = false;
                return;
            }

            var localPageComments = new List<CommentEntry>();
            var localHubComments = new List<CommentEntry>();
            foreach (var comment in post.Comments)
            {
                var commentUserName = comment.UserName.ToLowerInvariant();
                if (commentUserName.Equals(selectedPage.DisplayName, StringComparison.OrdinalIgnoreCase))
                {
                    localPageComments.Add(new CommentEntry(
                        commentUserName,
                        comment.Timestamp,
                        comment.Text,
                        (page, _) => { vm.SelectedFeature!.PhotoFeaturedOnPage = true; }));
                    PageCommentsValidation = new ValidationResult(ValidationResultType.Error, "Found page comments - possibly already featured on page");
                    ShowComments = true;
                    LogEntries.Add(new LogEntry($"Found page comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {comment.Text}", Colors.Red));
                }
                else if (commentUserName.StartsWith($"{selectedPage.HubName.ToLower()}_", StringComparison.Ordinal))
                {
                    localHubComments.Add(new CommentEntry(
                        commentUserName,
                        comment.Timestamp,
                        comment.Text,
                        (page, timestamp) =>
                        {
                            vm.SelectedFeature!.PhotoFeaturedOnHub = true;
                            vm.SelectedFeature!.PhotoLastFeaturedPage = page[(selectedPage.HubName.Length + 1)..];
                            vm.SelectedFeature!.PhotoLastFeaturedOnHub = timestamp;
                        }));
                    HubCommentsValidation = new ValidationResult(ValidationResultType.Error, "Found hub comments - possibly already featured on another page");
                    ShowComments = true;
                    LogEntries.Add(new LogEntry($"Found hub comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {comment.Text}", Colors.Orange));
                }
            }

            if (!post.CommentsAvailable)
            {
                MoreComments = post.CommentCount != 0;
            }
            else
            {
                MoreComments = post.Comments.Count < post.CommentCount;
            }

            if (MoreComments)
            {
                LogEntries.Add(new LogEntry("More comments!", Colors.Orange));
                ShowComments = true;
            }

            PageComments = [.. localPageComments];
            HubComments = [.. localHubComments];
        }

        private void LogProgress(string? value, string label)
        {
            if (string.IsNullOrEmpty(value))
            {
                LogEntries.Add(new LogEntry($"{label.ToLower()} not found", Colors.Red));
            }
            else
            {
                LogEntries.Add(new LogEntry($"{label}: {value}", defaultLogColor));
            }
        }

        private static string JoinReactContent(IEnumerable<ReactContent>? segments, List<string>? hashTags = null)
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
                        if (!string.IsNullOrWhiteSpace(segment.Value))
                        {
                            hashTags?.Add($"#{segment.Value}");
                        }
                        break;
                    case "person":
                        builder.Append(!string.IsNullOrWhiteSpace(segment.Label) ? $"@{segment.Label}" : segment.Value);
                        break;
                    case "url":
                        builder.Append(!string.IsNullOrWhiteSpace(segment.Label) ? segment.Label : segment.Value);
                        break;
                }
            }
            return builder.ToString().Replace("\\n", "\n");
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
                return new ValidationResult(ValidationResultType.Error, "Missing the user alias");
            }
            return new ValidationResult(ValidationResultType.Valid);
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
                return new ValidationResult(ValidationResultType.Error, "Missing the user name");
            }
            return new ValidationResult(ValidationResultType.Valid);
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
                return new ValidationResult(ValidationResultType.Error, "Missing the user profile URL");
            }
            if (!userProfileUrl.StartsWith("https://vero.co/"))
            {
                return new ValidationResult(ValidationResultType.Error, "User profile URL does not point to VERO");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        #endregion

        #region User BIO

        private string? userBio;
        public string? UserBio
        {
            get => userBio;
            set => Set(ref userBio, value);
        }

        private string postDataMode = "unknown";
        public string PostDataMode
        {
            get => postDataMode;
            set => Set(ref postDataMode, value);
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

        private ValidationResult pageHashtagCheck = new(ValidationResultType.Valid);
        public ValidationResult PageHashtagCheck
        {
            get => pageHashtagCheck;
            set => Set(ref pageHashtagCheck, value);
        }

        private ValidationResult excludedHashtagCheck = new(ValidationResultType.Valid);
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

        private ValidationResult pageCommentsValidation = new(ValidationResultType.Valid);
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

        private ValidationResult hubCommentsValidation = new(ValidationResultType.Valid);
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

        private int currentImageEntry = -1;
        public int CurrentImageEntry
        {
            get => currentImageEntry;
            set => Set(ref currentImageEntry, value);
        }

        private bool showImages = false;
        public bool ShowImages
        {
            get => showImages;
            set => Set(ref showImages, value);
        }

        public bool MultipleImages => ImageEntries.Count > 1;

        #endregion

        #region Image

        private ImageEntry? image;
        public ImageEntry? Image
        {
            get => image;
            set => Set(ref image, value);
        }

        public Command ValidateCommand => new(() => { ValidateImage(Image!); });

        private int imageScalePercent = 100;
        public int ImageScalePercent
        {
            get => imageScalePercent;
            set => Set(ref imageScalePercent, value, [nameof(ImageScale)]);
        }
        public double ImageScale => ImageScalePercent / 100.0;

        public Command ResetImageScaleCommand => new(() => { ImageScalePercent = 100; });

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
                ExcludedHashtagCheck = new ValidationResult(ValidationResultType.Valid, message: "Post does not contain any excluded hashtags");
                foreach (var excludedHashtag in excludedHashtags)
                {
                    if (pageHashTags.IndexOf(excludedHashtag) != -1)
                    {
                        ExcludedHashtagCheck = new ValidationResult(ValidationResultType.Error, error: $"Post contains excluded hashtag {excludedHashtag}");
                        LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, Colors.Red));
                        break;
                    }
                }
                if (ExcludedHashtagCheck.IsValid)
                {
                    LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Message!, defaultLogColor));
                }
            }
            else
            {
                ExcludedHashtagCheck = new ValidationResult(ValidationResultType.Valid, message: "There are no excluded hashtags");
                LogEntries.Add(new LogEntry(ExcludedHashtagCheck.Error!, defaultLogColor));
            }
        }

        public void ViewImage(ImageEntry imageEntry)
        {
            ImageScalePercent = 100;
            Image = imageEntry;
            vm.View = MainViewModel.ViewMode.ImageView;
        }

        public void ValidateImage(ImageEntry imageEntry)
        {
            ImageValidation = new ImageValidationViewModel(vm, imageEntry);
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

            ViewImageCommand = new Command(() =>
            {
                this.postVm.ViewImage(this);
            });
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

        public ICommand ViewImageCommand { get; }

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
}
