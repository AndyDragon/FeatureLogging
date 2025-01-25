using System.Collections.ObjectModel;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace FeatureLogging.ViewModels;

public class MainViewModel : NotifyPropertyChanged
{
    private readonly HttpClient httpClient = new();

    public MainViewModel()
    {
        scriptViewModel = new ScriptsViewModel(this);

        _ = LoadPages();
    }

    #region User settings

    public static string GetDataLocationPath(bool shared = false)
    {
        // var user = WindowsIdentity.GetCurrent();
        var dataLocationPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "AndyDragonSoftware",
            "FeatureLogging");
        if (!Directory.Exists(dataLocationPath))
        {
            Directory.CreateDirectory(dataLocationPath);
        }
        return dataLocationPath;
    }

    public static string GetUserSettingsPath(bool shared = false)
    {
        var dataLocationPath = GetDataLocationPath(shared);
        return Path.Combine(dataLocationPath, "settings.json");
    }

    // public static Settings Settings => new();

    #endregion

    #region Server access

    private async Task LoadPages()
    {
        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var pagesUri = new Uri("https://vero.andydragon.com/static/data/pages.json");
            var content = await httpClient.GetStringAsync(pagesUri);
            if (!string.IsNullOrEmpty(content))
            {
                var loadedPages = new List<LoadedPage>();
                var pagesCatalog = JsonConvert.DeserializeObject<ScriptsCatalog>(content) ?? new ScriptsCatalog();
                if (pagesCatalog.Hubs != null)
                {
                    foreach (var hubPair in pagesCatalog.Hubs)
                    {
                        foreach (var hubPage in hubPair.Value)
                        {
                            loadedPages.Add(new LoadedPage(hubPair.Key, hubPage));
                        }
                    }
                }
                LoadedPages.Clear();
                foreach (var page in loadedPages.OrderBy(page => page, LoadedPageComparer.Default))
                {
                    LoadedPages.Add(page);
                }
                // notificationManager.Show(
                //     "Pages loaded",
                //     "Loaded " + LoadedPages.Count.ToString() + " pages from the server",
                //     type: NotificationType.Information,
                //     areaName: "WindowArea",
                //     expirationTime: TimeSpan.FromSeconds(3));
            }
            SelectedPage = LoadedPages.FirstOrDefault(page => page.Id == Page);
            _ = LoadTemplates();
            _ = LoadDisallowList();
            // IsDirty = false;
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error occurred: {0}", ex.Message);
            // ShowErrorToast(
            //     "Failed to load the page catalog",
            //     "The application requires the catalog to perform its operations: " + ex.Message + "\n\nClick here to retry",
            //     NotificationType.Error,
            //     () => { _ = LoadPages(); });
        }
    }

    private async Task LoadTemplates()
    {
        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var templatesUri = new Uri("https://vero.andydragon.com/static/data/templates.json");
            var content = await httpClient.GetStringAsync(templatesUri);
            if (!string.IsNullOrEmpty(content))
            {
                scriptViewModel.TemplatesCatalog = JsonConvert.DeserializeObject<TemplatesCatalog>(content) ?? new TemplatesCatalog();
            }
            WaitingForPages = false;
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error occurred: {0}", ex.Message);
            // ShowErrorToast(
            //     "Failed to load the page templates",
            //     "The application requires the templtes to perform its operations: " + ex.Message + "\n\nClick here to retry",
            //     NotificationType.Error,
            //     () => { _ = LoadTemplates(); });
        }
    }

    private async Task LoadDisallowList()
    {
        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var templatesUri = new Uri("https://vero.andydragon.com/static/data/disallowlists.json");
            var content = await httpClient.GetStringAsync(templatesUri);
            if (!string.IsNullOrEmpty(content))
            {
                Validation.DisallowList = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(content) ?? [];
            }
        }
        catch (Exception ex)
        {
            // Do nothing, not vital
            Console.WriteLine("Error occurred: {0}", ex.Message);
        }
    }

    #endregion

    #region Waiting state

    private bool waitingForPages = true;
    public bool WaitingForPages
    {
        get => waitingForPages;
        set
        {
            if (Set(ref waitingForPages, value))
            {
                // NewFeaturesCommand.OnCanExecuteChanged();
                // OpenFeaturesCommand.OnCanExecuteChanged();
                // SaveFeaturesCommand.OnCanExecuteChanged();
                // GenerateReportCommand.OnCanExecuteChanged();
                // SaveReportCommand.OnCanExecuteChanged();
                // AddFeatureCommand.OnCanExecuteChanged();
            }
        }
    }

    #endregion

    public ObservableCollection<LoadedPage> LoadedPages { get; } = [];

    private LoadedPage? selectedPage = null;

    public LoadedPage? SelectedPage
    {
        get => selectedPage;
        set
        {
            if (Set(ref selectedPage, value))
            {
                Page = SelectedPage?.Id ?? string.Empty;
                SelectedFeature = null;
                OnPropertyChanged(nameof(Memberships));
                OnPropertyChanged(nameof(TagSources));
                OnPropertyChanged(nameof(ClickHubVisibility));
                OnPropertyChanged(nameof(SnapHubVisibility));
                OnPropertyChanged(nameof(SnapOrClickHubVisibility));
                OnPropertyChanged(nameof(HasSelectedPage));
                OnPropertyChanged(nameof(NoSelectedPage));
                OnPropertyChanged(nameof(PageTags));
                OnPropertyChanged(nameof(FeaturedCounts));
                if (SelectedPage != null)
                {
                    excludedTags = UserSettings.Get(nameof(ExcludedTags) + ":" + SelectedPage.Id, "");
                }
                else
                {
                    excludedTags = "";
                }
                OnPropertyChanged(nameof(ExcludedTags));
                if (SelectedPage != null)
                {
                    StaffLevel = UserSettings.Get<string>(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevels[0]);
                }
                else
                {
                    StaffLevel = UserSettings.Get<string>(nameof(StaffLevel), StaffLevels[0]);
                }
                if (!StaffLevels.Contains(StaffLevel))
                {
                    StaffLevel = StaffLevels[0];
                }
            }
        }
    }

    public bool CanChangePage => Features.Count == 0;

    public Visibility ClickHubVisibility => SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;

    public Visibility SnapHubVisibility => SelectedPage?.HubName == "snap" ? Visibility.Visible : Visibility.Collapsed;

    public Visibility SnapOrClickHubVisibility => SelectedPage?.HubName == "snap" || SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;

    public bool HasSelectedPage => SelectedPage != null;
    public bool NoSelectedPage => SelectedPage == null;

    readonly ObservableCollection<Feature> features = [];
    public ObservableCollection<Feature> Features => features;

    private Feature? selectedFeature = null;
    public Feature? SelectedFeature
    {
        get => selectedFeature;
        set => Set(ref selectedFeature, value);
    }

    public Command AddFeatureCommand => new(() =>
    {
        if (Clipboard.HasText)
        {
            var text = Clipboard.GetTextAsync().Result ?? "";
            if (text.StartsWith("https://vero.co/"))
            {
                var feature = new Feature
                {
                    PostLink = text,
                    UserAlias = text["https://vero.co/".Length..].Split("/").FirstOrDefault() ?? "",
                };
                features.Add(feature);
                SelectedFeature = feature;
                SemanticScreenReader.Announce($"Added feature for {feature.UserAlias}");
            }
            else
            {
                var feature = new Feature();
                features.Add(feature);
                SelectedFeature = feature;
                SemanticScreenReader.Announce($"Added blank feature");
            }
        }
        else
        {
            var feature = new Feature();
            features.Add(feature);
            SelectedFeature = feature;
            SemanticScreenReader.Announce($"Added blank feature");
        }
    });

    #region Page

    private static ValidationResult CalculatePageValidation(string page)
    {
        return Validation.ValidateValueNotEmpty(page);
    }

    static string FixPageHub(string page)
    {
        var parts = page.Split(':', 2);
        if (parts.Length > 1)
        {
            return page;
        }
        return "snap:" + page;
    }

    private string page = FixPageHub(UserSettings.Get(nameof(Page), ""));

    public string Page
    {
        get => page;
        set
        {
            if (Set(ref page, value, [nameof(StaffLevels)]))
            {
                UserSettings.Store(nameof(Page), Page);
                PageValidation = CalculatePageValidation(Page);
                // IsDirty = true;
            }
        }
    }

    private ValidationResult pageValidation = CalculatePageValidation(UserSettings.Get(nameof(Page), ""));

    public ValidationResult PageValidation
    {
        get => pageValidation;
        private set
        {
            if (Set(ref pageValidation, value))
            {
            }
        }
    }

    #endregion

    #region Staff level

    public static string[] SnapStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
        "Guest moderator"
    ];

    public static string[] ClickStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    public static string[] OtherStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    public string[] StaffLevels =>
        SelectedPage?.HubName == "click" ? ClickStaffLevels :
        SelectedPage?.HubName == "snap" ? SnapStaffLevels :
        OtherStaffLevels;

    private string staffLevel = UserSettings.Get(nameof(StaffLevel), "Mod");

    public string StaffLevel
    {
        get => staffLevel;
        set
        {
            if (Set(ref staffLevel, value))
            {
                if (SelectedPage != null)
                {
                    UserSettings.Store(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevel);
                }
                else
                {
                    UserSettings.Store(nameof(StaffLevel), StaffLevel);
                }
            }
        }
    }

    private string excludedTags = "";
    public string ExcludedTags
    {
        get => excludedTags;
        set
        {
            if (Set(ref excludedTags, value))
            {
                if (SelectedPage != null)
                {
                    UserSettings.Store(nameof(ExcludedTags) + ":" + SelectedPage.Id, ExcludedTags);
                }
                LoadedPost?.UpdateExcludedTags();
            }
        }
    }

    #endregion

    #region Page tags

    private static string[] SnapPageTags => [
        "Page tag",
        "RAW page tag",
        "Community tag",
        "RAW community tag",
    ];

    private static string[] ClickPageTags => [
        "Page tag",
        "Community tag",
        "Hub tag",
    ];

    private static string[] OtherPageTags => [
        "Page tag",
    ];

    public string[] PageTags =>
        SelectedPage?.HubName == "click" ? ClickPageTags :
        SelectedPage?.HubName == "snap" ? SnapPageTags :
        OtherPageTags;

    private string pageTag = "Page tag";

    public string PageTag
    {
        get => pageTag;
        set => Set(ref pageTag, value);
    }

    #endregion

    #region Membership levels

    private static string[] SnapMemberships => [
        "None",
        "Artist",
        "Snap Member",
        "Snap VIP Member",
        "Snap VIP Gold Member",
        "Snap Platinum Member",
        "Snap Elite Member",
        "Snap Hall of Fame Member",
        "Snap Diamond Member",
    ];

    private static string[] ClickMemberships => [
        "None",
        "Artist",
        "Click Member",
        "Click Bronze Member",
        "Click Silver Member",
        "Click Gold Member",
        "Click Platinum Member",
    ];

    private static string[] OtherMemberships => [
        "None",
        "Artist",
    ];

    public string[] Memberships =>
        SelectedPage?.HubName == "click" ? ClickMemberships :
        SelectedPage?.HubName == "snap" ? SnapMemberships :
        OtherMemberships;

    public Dictionary<string, string> OldMembershipMap =>
        SelectedPage?.HubName == "click" ? new Dictionary<string, string>
        {
            { "Member", "Click Member" },
            { "Bronze Member", "Click Bronze Member" },
            { "Silver Member", "Click Silver Member" },
            { "Gold Member", "Click Gold Member" },
            { "Platinum Member", "Click Platinum Member" },
        } :
        SelectedPage?.HubName == "snap" ? new Dictionary<string, string>
        {
            { "Member", "Snap Member" },
            { "VIP Member", "Snap VIP Member" },
            { "VIP Gold Member", "Snap VIP Gold Member" },
            { "Platinum Member", "Snap Platinum Member" },
            { "Elite Member", "Snap Elite Member" },
            { "Hall of Fame Member", "Snap Hall of Fame Member" },
            { "Diamond Member", "Snap Diamond Member" },
        } :
        [];

    #endregion

    #region Tag sources

    private static string[] SnapTagSources => [
        "Page tag",
        "RAW page tag",
        "Snap community tag",
        "RAW community tag",
        "Snap membership tag",
    ];

    private static string[] ClickTagSources => [
        "Page tag",
        "Click community tag",
        "Click hub tag",
    ];

    private static string[] OtherTagSources => [
        "Page tag",
    ];

    public string[] TagSources =>
        SelectedPage?.HubName == "click" ? ClickTagSources :
        SelectedPage?.HubName == "snap" ? SnapTagSources :
        OtherTagSources;

    #endregion

    #region Feature counts

    static string[] CountArray(int start, int end)
    {
        var list = new List<string>
        {
            "many"
        };
        for (int index = start; index <= end; index++)
        {
            list.Add(index.ToString());
        }
        return [.. list];
    }

    public string[] FeaturedCounts =>
        SelectedPage?.HubName == "click" ? CountArray(0, 75) :
        SelectedPage?.HubName == "snap" ? CountArray(0, 20) :
        CountArray(0, 20);

    #endregion

    #region TinEye results

    public static string[] TinEyeResults => ["0 matches", "no matches", "matches found"];

    #endregion

    #region AI check results

    public static string[] AiCheckResults => ["human", "ai"];

    #endregion

    #region Report generation

    private string GenerateLogReport()
    {
        if (SelectedPage == null)
        {
            return "";
        }

        var builder = new StringBuilder();
        var personalMessagesBuilder = new StringBuilder();
        if (SelectedPage.HubName == "click")
        {
            builder.AppendLine($"Picks for #{SelectedPage.DisplayName} / #click_community / #click_hub");
            builder.AppendLine();
            var wasLastItemPicked = true;
            foreach (var feature in Features.OrderBy(feature => feature, FeatureComparer.Default))
            {
                var isPicked = feature.IsPicked;
                var indent = "";
                var prefix = "";
                if (feature.PhotoFeaturedOnPage)
                {
                    prefix = "[already featured] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TooSoonToFeatureUser)
                {
                    prefix = "[too soon] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TinEyeResults == "matches found")
                {
                    prefix = "[tineye match] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.AiCheckResults == "ai")
                {
                    prefix = "[AI] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (!feature.IsPicked)
                {
                    prefix = "[not picked] ";
                    indent = "    ";
                    isPicked = false;
                }
                if (!isPicked && wasLastItemPicked)
                {
                    builder.AppendLine("---------------");
                    builder.AppendLine();
                }
                wasLastItemPicked = isPicked;
                builder.AppendLine($"{indent}{prefix}{feature.PostLink}");
                builder.AppendLine($"{indent}user - {feature.UserName} @{feature.UserAlias}");
                builder.AppendLine($"{indent}member level - {feature.UserLevel}");
                if (feature.UserHasFeaturesOnPage)
                {
                    builder.AppendLine($"{indent}last feature on page - {feature.LastFeaturedOnPage} (features on page {feature.FeatureCountOnPage})");
                }
                else
                {
                    builder.AppendLine($"{indent}last feature on page - never (features on page 0)");
                }
                if (feature.UserHasFeaturesOnHub)
                {
                    builder.AppendLine($"{indent}last feature - {feature.LastFeaturedOnHub} {feature.LastFeaturedPage} (features {feature.FeatureCountOnHub})");
                }
                else
                {
                    builder.AppendLine($"{indent}last feature - never (features 0)");
                }
                var alreadyFeatured = feature.PhotoFeaturedOnPage ? "YES" : "no";
                var alreadyFeaturedOnHub = feature.PhotoFeaturedOnHub ? $"{feature.PhotoLastFeaturedOnHub} {feature.PhotoLastFeaturedPage}" : "no";
                builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured on page - {alreadyFeatured}, featured on hub - {alreadyFeaturedOnHub}");
                var teammate = feature.UserIsTeammate ? "yes" : "no";
                builder.AppendLine($"{indent}teammate - {teammate}");
                switch (feature.TagSource)
                {
                    case "Page tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}");
                        break;
                    case "Click community tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_community");
                        break;
                    case "Click hub tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_hub");
                        break;
                    default:
                        builder.AppendLine($"{indent}hashtag = other");
                        break;
                }
                builder.AppendLine($"{indent}tineye: {feature.TinEyeResults}");
                builder.AppendLine($"{indent}ai check: {feature.AiCheckResults}");
                builder.AppendLine();

                if (isPicked)
                {
                    // var personalMessageTemplate = feature.UserHasFeaturesOnPage
                    //     ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                    //         ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessage)
                    //     : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                    //         ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessageFirst);
                    // var fullMessage = personalMessageTemplate
                    //     .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                    //     .Replace("%%HUBNAME%%", SelectedPage.HubName)
                    //     .Replace("%%USERNAME%%", feature.UserName)
                    //     .Replace("%%USERALIAS%%", feature.UserAlias)
                    //     .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                    // personalMessagesBuilder.AppendLine(fullMessage);
                }
            }
        }
        else if (SelectedPage.HubName == "snap")
        {
            builder.AppendLine($"Picks for #{SelectedPage.DisplayName}");
            builder.AppendLine();
            var wasLastItemPicked = true;
            foreach (var feature in Features.OrderBy(feature => feature, FeatureComparer.Default))
            {
                var isPicked = feature.IsPicked;
                var indent = "";
                var prefix = "";
                if (feature.PhotoFeaturedOnPage)
                {
                    prefix = "[already featured] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TooSoonToFeatureUser)
                {
                    prefix = "[too soon] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TinEyeResults == "matches found")
                {
                    prefix = "[tineye match] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.AiCheckResults == "ai")
                {
                    prefix = "[AI] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (!feature.IsPicked)
                {
                    prefix = "[not picked] ";
                    indent = "    ";
                    isPicked = false;
                }
                if (!isPicked && wasLastItemPicked)
                {
                    builder.AppendLine("---------------");
                    builder.AppendLine();
                }
                wasLastItemPicked = isPicked;
                builder.AppendLine($"{indent}{prefix}{feature.PostLink}");
                builder.AppendLine($"{indent}user - {feature.UserName} @{feature.UserAlias}");
                builder.AppendLine($"{indent}member level - {feature.UserLevel}");
                if (feature.UserHasFeaturesOnPage)
                {
                    builder.AppendLine($"{indent}last feature on page - {feature.LastFeaturedOnPage} (features on page {feature.FeatureCountOnPage} Snap + {feature.FeatureCountOnRawPage} RAW)");
                }
                else
                {
                    builder.AppendLine($"{indent}last feature on page - never (features on page 0 Snap + 0 RAW)");
                }
                if (feature.UserHasFeaturesOnHub)
                {
                    builder.AppendLine($"{indent}last feature - {feature.LastFeaturedOnHub} {feature.LastFeaturedPage} (features {feature.FeatureCountOnHub} Snap + {feature.FeatureCountOnRawHub} RAW)");
                }
                else
                {
                    builder.AppendLine($"{indent}last feature - never (features 0 Snap + 0 RAW)");
                }
                var alreadyFeatured = feature.PhotoFeaturedOnPage ? "YES" : "no";
                var alreadyFeaturedOnHub = feature.PhotoFeaturedOnHub ? $"{feature.PhotoLastFeaturedOnHub} {feature.PhotoLastFeaturedPage}" : "no";
                builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured on page - {alreadyFeatured}, featured on hub - {alreadyFeaturedOnHub}");
                var teammate = feature.UserIsTeammate ? "yes" : "no";
                builder.AppendLine($"{indent}teammate - {teammate}");
                switch (feature.TagSource)
                {
                    case "Page tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}");
                        break;
                    case "RAW page tag":
                        builder.AppendLine($"{indent}hashtag = #raw_{SelectedPage.PageName ?? SelectedPage.Name}");
                        break;
                    case "Snap community tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_community");
                        break;
                    case "RAW community tag":
                        builder.AppendLine($"{indent}hashtag = #raw_community");
                        break;
                    default:
                        builder.AppendLine($"{indent}hashtag = other");
                        break;
                }
                builder.AppendLine($"{indent}tineye: {feature.TinEyeResults}");
                builder.AppendLine($"{indent}ai check: {feature.AiCheckResults}");
                builder.AppendLine();

                if (isPicked)
                {
                    // var personalMessageTemplate = feature.UserHasFeaturesOnPage
                    //     ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                    //         ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessage)
                    //     : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                    //         ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessageFirst);
                    // var fullMessage = personalMessageTemplate
                    //     .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                    //     .Replace("%%HUBNAME%%", SelectedPage.HubName)
                    //     .Replace("%%USERNAME%%", feature.UserName)
                    //     .Replace("%%USERALIAS%%", feature.UserAlias)
                    //     .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                    // personalMessagesBuilder.AppendLine(fullMessage);
                }
            }
        }
        else
        {
            builder.AppendLine($"Picks for #{SelectedPage.DisplayName}");
            builder.AppendLine();
            var wasLastItemPicked = true;
            foreach (var feature in Features.OrderBy(feature => feature, FeatureComparer.Default))
            {
                var isPicked = feature.IsPicked;
                var indent = "";
                var prefix = "";
                if (feature.PhotoFeaturedOnPage)
                {
                    prefix = "[already featured] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TooSoonToFeatureUser)
                {
                    prefix = "[too soon] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.TinEyeResults == "matches found")
                {
                    prefix = "[tineye match] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (feature.AiCheckResults == "ai")
                {
                    prefix = "[AI] ";
                    indent = "    ";
                    isPicked = false;
                }
                else if (!feature.IsPicked)
                {
                    prefix = "[not picked] ";
                    indent = "    ";
                    isPicked = false;
                }
                if (!isPicked && wasLastItemPicked)
                {
                    builder.AppendLine("---------------");
                    builder.AppendLine();
                }
                wasLastItemPicked = isPicked;
                builder.AppendLine($"{indent}{prefix}{feature.PostLink}");
                builder.AppendLine($"{indent}user - {feature.UserName} @{feature.UserAlias}");
                builder.AppendLine($"{indent}member level - {feature.UserLevel}");
                var alreadyFeatured = feature.PhotoFeaturedOnPage ? "YES" : "no";
                builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured on page - {alreadyFeatured}");
                var teammate = feature.UserIsTeammate ? "yes" : "no";
                builder.AppendLine($"{indent}teammate - {teammate}");
                switch (feature.TagSource)
                {
                    case "Page tag":
                        builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}");
                        break;
                    default:
                        builder.AppendLine($"{indent}hashtag = other");
                        break;
                }
                builder.AppendLine($"{indent}tineye: {feature.TinEyeResults}");
                builder.AppendLine($"{indent}ai check: {feature.AiCheckResults}");
                builder.AppendLine();

                if (isPicked)
                {
                    // var personalMessageTemplate = feature.UserHasFeaturesOnPage
                    //     ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                    //         ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessage)
                    //     : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                    //         ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    //         : Settings.PersonalMessageFirst);
                    // var fullMessage = personalMessageTemplate
                    //     .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                    //     .Replace("%%HUBNAME%%", "")
                    //     .Replace("%%USERNAME%%", feature.UserName)
                    //     .Replace("%%USERALIAS%%", feature.UserAlias)
                    //     .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                    // personalMessagesBuilder.AppendLine(fullMessage);
                }
            }
        }

        var completeText = builder.ToString();
        completeText += "---------------\n\n";
        if (personalMessagesBuilder.Length != 0)
        {
            completeText += personalMessagesBuilder.ToString();
            completeText += "\n---------------\n";
        }

        return completeText;
    }

    #endregion

    #region Clipboard support

    public static async Task CopyTextToClipboardAsync(string text, string title, string successMessage)
    {
        await TrySetClipboardText(text);
        // notificationManager.Show(
        //     title,
        //     successMessage,
        //     type: NotificationType.Information,
        //     areaName: "WindowArea",
        //     expirationTime: TimeSpan.FromSeconds(3));
    }

    public static async Task TrySetClipboardText(string text)
    {
        await Clipboard.SetTextAsync(text);
    }

    #endregion

    #region Script view model

    private readonly ScriptsViewModel scriptViewModel;

    public ScriptsViewModel ScriptViewModel => scriptViewModel;

    #endregion

    #region Loaded post

    private DownloadedPostViewModel? loadedPost;

    public DownloadedPostViewModel? LoadedPost
    {
        get => loadedPost;
        private set => Set(ref loadedPost, value, [nameof(TinEyeSource)]);
    }

    public string TinEyeSource { get => LoadedPost?.ImageValidation?.TinEyeUri ?? "about:blank"; }

    #endregion

    internal void TriggerTinEyeSource()
    {
        OnPropertyChanged(nameof(TinEyeSource));
    }
}
