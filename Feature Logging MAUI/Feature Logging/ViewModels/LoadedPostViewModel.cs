using System.Collections.ObjectModel;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
#if ANDROID
using Android.Provider;
#endif
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Core;
using FeatureLogging.Base;
using FeatureLogging.Models;
using FeatureLogging.Views;
using HtmlAgilityPack;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using SkiaSharp;
using Browser = Microsoft.Maui.ApplicationModel.Browser;

namespace FeatureLogging.ViewModels;

public class LoadedPostViewModel(MainViewModel vm, string hubName) : NotifyPropertyChanged
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
        ImageEntries.Clear();
        PageComments = [];
        HubComments = [];
        ShowDescription = false;
        ShowComments = false;
        ShowImages = false;
        ShowImageNavigators = false;
        MoreComments = false;
        PageHashtagCheck = new ValidationResult(ValidationLevel.Valid);
        ExcludedHashtagCheck = new ValidationResult(ValidationLevel.Valid);
        PostDataMode = "unknown";

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
            var postUri = new Uri(MainViewModel.SelectedFeature!.PostLink);
            var content = await httpClient.GetStringAsync(postUri);

            if (!string.IsNullOrEmpty(content))
            {
                LogProgress("Loaded the post contents");

                var parsedPayload = ParsePayload(content);
                PostDataMode = DerivePostDataMode(parsedPayload);

                if (parsedPayload.Profile != null)
                {
                    UserAlias = parsedPayload.Profile.Alias;
                    UserName = parsedPayload.Profile.Name;
                    UserProfileUrl = parsedPayload.Profile.Url;
                    UserBio = parsedPayload.Profile.Bio;

                    if (string.IsNullOrWhiteSpace(MainViewModel.SelectedFeature?.UserAlias) && !string.IsNullOrWhiteSpace(UserAlias))
                    {
                        MainViewModel.SelectedFeature!.UserAlias = UserAlias!;
                    }
                    if (string.IsNullOrWhiteSpace(MainViewModel.SelectedFeature?.UserName) && !string.IsNullOrWhiteSpace(UserName))
                    {
                        MainViewModel.SelectedFeature!.UserName = UserName!;
                    }

                    LogProgress($"Profile source: {parsedPayload.ProfileSource}");
                    LogProgress($"User alias: {UserAlias}");
                    LogProgress($"User name: {UserName}");
                    LogProgress($"User profile URL: {UserProfileUrl}");
                    LogProgress($"User BIO: {UserBio}");
                }
                else
                {
                    LogProgress("Profile data was not found in the selected data mode", LogType.Warning);
                }

                if (parsedPayload.Post != null)
                {
                    ShowDescription = true;
                    pageHashTags.Clear();
                    pageHashTags.AddRange(parsedPayload.Post.HashTags);
                    Description = parsedPayload.Post.Description;
                    LogProgress($"Post source: {parsedPayload.PostSource}");

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

                    foreach (var imageUrl in parsedPayload.Post.ImageUrls)
                    {
                        ImageEntries.Add(new ImageEntry(new Uri(imageUrl), this));
                    }
                    if (ImageEntries.Count > 0)
                    {
                        ShowImages = true;
                        CurrentImage = ImageEntries[0];
                        LogProgress($"Found {ImageEntries.Count} images in post");
                    }
                    else
                    {
                        LogProgress("No images found in post", LogType.Error);
                    }
                    ShowImageNavigators = ImageEntries.Count > 1;

                    ApplyComments(parsedPayload.Post);
                }
                else
                {
                    LogProgress("Post data was not found in the selected data mode", LogType.Warning);
                }

                if (parsedPayload.Profile == null && parsedPayload.Post == null)
                {
                    LogProgress("Failed to find the profile or post information", LogType.Error);
                    LogProgress("Post must be handled manually in VERO app", LogType.Error);
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
        LogProgress("Using auto parser (new + legacy fallback)");

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
            LogProgress($"New parser did not return profile: {reactException.Message}", LogType.Warning);
        }
        if (merged.Post == null && reactException != null)
        {
            LogProgress($"New parser did not return post: {reactException.Message}", LogType.Warning);
        }
        if (merged.Profile == null && legacyException != null)
        {
            LogProgress($"Legacy parser did not return profile: {legacyException.Message}", LogType.Warning);
        }
        if (merged.Post == null && legacyException != null)
        {
            LogProgress($"Legacy parser did not return post: {legacyException.Message}", LogType.Warning);
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
            var description = PostDataHelper.JoinSegments(post.Caption, hashTags).StripExtraSpaces();
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
                    Text = PostDataHelper.JoinSegments(comment.Content).StripExtraSpaces(true),
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
        return array.ToObject<dynamic[]>()!;
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

    private void ApplyComments(ParsedPostPayload post)
    {
        if (MainViewModel.SelectedPage!.HubName != "snap" && MainViewModel.SelectedPage!.HubName != "click")
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
            if (commentUserName.Equals(MainViewModel.SelectedPage!.DisplayName, StringComparison.OrdinalIgnoreCase))
            {
                localPageComments.Add(new CommentEntry(
                    commentUserName,
                    comment.Timestamp,
                    comment.Text,
                    (_, _) => { MainViewModel.SelectedFeature!.PhotoFeaturedOnPage = true; }));
                PageCommentsValidation = new ValidationResult(
                    ValidationLevel.Error,
                    "Found page comments - possibly already featured on page");
                ShowComments = true;
                LogProgress(
                    $"Found page comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {comment.Text}",
                    LogType.Error);
            }
            else if (commentUserName.StartsWith($"{MainViewModel.SelectedPage!.HubName.ToLower()}_", StringComparison.Ordinal))
            {
                localHubComments.Add(new CommentEntry(
                    commentUserName,
                    comment.Timestamp,
                    comment.Text,
                    (page, timestamp) =>
                    {
                        MainViewModel.SelectedFeature!.PhotoFeaturedOnHub = true;
                        MainViewModel.SelectedFeature!.PhotoLastFeaturedPage = page[(MainViewModel.SelectedPage!.HubName.Length + 1)..];
                        MainViewModel.SelectedFeature!.PhotoLastFeaturedOnHub = timestamp;
                    }));
                HubCommentsValidation = new ValidationResult(
                    ValidationLevel.Warning,
                    "Found hub comments - possibly already featured on another page");
                ShowComments = true;
                LogProgress(
                    $"Found hub comment: {commentUserName} - {comment.Timestamp?.FormatTimestamp()} - {comment.Text}",
                    LogType.Warning);
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
            LogProgress("More comments!", LogType.Warning);
            ShowComments = true;
        }

        PageComments = [.. localPageComments];
        HubComments = [.. localHubComments];
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
                        hashTags?.Add(segment.Value);
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
                UserAliasValidation = Validation.ValidateUser(hubName, userAlias ?? "");
                OnPropertyChanged(nameof(TransferUserAliasCommand));
            }
        }
    }

    private ValidationResult userAliasValidation = Validation.ValidateUser("", "");

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
                UserNameValidation = Validation.ValidateValueNotEmptyAndContainsNoNewlines(userName ?? "");
                OnPropertyChanged(nameof(TransferUserNameCommand));
            }
        }
    }

    private ValidationResult userNameValidation = Validation.ValidateValueNotEmptyAndContainsNoNewlines("");

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

    private string postDataMode = "unknown";
    public string PostDataMode
    {
        get => postDataMode;
        set => Set(ref postDataMode, value);
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

            if (ExcludedHashtagCheck.IsValid)
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
#if ANDROID
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
#endif
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
