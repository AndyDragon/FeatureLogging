using ControlzEx.Theming;
using MahApps.Metro.IconPacks;
using Microsoft.Win32;
using Newtonsoft.Json;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Security.Principal;
using System.Text;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

namespace FeatureLogging
{
    public static class Validation
    {
        private static List<string> disallowList = [];

        public static List<string> DisallowList 
        {
            get => disallowList;
            set => disallowList = value;
        }

        #region Field validation

        public static ValidationResult ValidateUser(string userName)
        {
            var userNameValidationResult = ValidateUserName(userName);
            if (!userNameValidationResult.Valid)
            {
                return userNameValidationResult;
            }
            if (DisallowList.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null)
            {
                return new ValidationResult(false, "User is on the disallow list");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateValueNotEmpty(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return new ValidationResult(false, "Required value");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateValueNotDefault(string value, string defaultValue)
        {
            if (string.IsNullOrEmpty(value) || string.Equals(value, defaultValue, StringComparison.OrdinalIgnoreCase))
            {
                return new ValidationResult(false, "Required value");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateUserName(string userName)
        {
            if (string.IsNullOrEmpty(userName))
            {
                return new ValidationResult(false, "Required value");
            }
            if (userName.StartsWith('@'))
            {
                return new ValidationResult(false, "Don't include the '@' in user names");
            }
            return new ValidationResult(true);
        }

        #endregion
    }

    public partial class MainViewModel : NotifyPropertyChanged
    {
        private readonly HttpClient httpClient = new();
        private readonly NotificationManager notificationManager = new();
        private string lastFilename = string.Empty;

        public MainViewModel()
        {
            _ = LoadPages();

            #region Command implementations

            NewFeaturesCommand = new Command(() => {
                lastFilename = string.Empty;
                SelectedFeature = null;
                Features.Clear();
                OnPropertyChanged(nameof(HasFeatures));
            });

            OpenFeaturesCommand = new Command(() =>
            {
                OpenFileDialog dialog = new()
                {
                    Filter = "Log files (*.json)|*.json|All files (*.*)|*.*",
                    Title = "Open a saved log file",
                    CheckFileExists = true
                };
                if (dialog.ShowDialog() == true)
                {
                    lastFilename = string.Empty;
                    SelectedFeature = null;
                    try
                    {
                        Dictionary<string, dynamic>? file = JsonConvert.DeserializeObject<Dictionary<string, dynamic>>(File.ReadAllText(dialog.FileName));
                        if (file != null)
                        {
                            var pageId = file["page"];
                            var foundPage = LoadedPages.FirstOrDefault(page => page.Id == pageId);
                            if (foundPage != null)
                            {
                                // Force the page to update.
                                selectedPage = null;
                                SelectedPage = foundPage;
                                Features.Clear();
                                foreach (var feature in file["features"])
                                {
                                    var loadedFeature = new Feature
                                    {
                                        IsPicked = (bool)feature["isPicked"],
                                        PostLink = (string)feature["postLink"],
                                        UserName = (string)feature["userName"],
                                        UserAlias = (string)feature["userAlias"],
                                        UserLevel = new List<string>(Memberships).Contains((string)feature["userLevel"]) ? (string)feature["userLevel"] : Memberships[0],
                                        UserIsTeammate = (bool)feature["userIsTeammate"],
                                        TagSource = new List<string>(TagSources).Contains((string)feature["tagSource"]) ? (string)feature["tagSource"] : TagSources[0],
                                        PhotoFeaturedOnPage = (bool)feature["photoFeaturedOnPage"],
                                        FeatureDescription = (string)feature["featureDescription"],
                                        UserHasFeaturesOnPage = (bool)feature["userHasFeaturesOnPage"],
                                        LastFeaturedOnPage = (string)feature["lastFeaturedOnPage"],
                                        FeatureCountOnPage = new List<string>(FeaturedCounts).Contains((string)feature["featureCountOnPage"]) ? (string)feature["featureCountOnPage"] : FeaturedCounts[0],
                                        FeatureCountOnRawPage = new List<string>(FeaturedCounts).Contains((string)feature["featureCountOnRawPage"]) ? (string)feature["featureCountOnRawPage"] : FeaturedCounts[0],
                                        UserHasFeaturesOnHub = (bool)feature["userHasFeaturesOnHub"],
                                        LastFeaturedOnHub = (string)feature["lastFeaturedOnHub"],
                                        LastFeaturedPage = (string)feature["lastFeaturedPage"],
                                        FeatureCountOnHub = new List<string>(FeaturedCounts).Contains((string)feature["featureCountOnHub"]) ? (string)feature["featureCountOnHub"] : FeaturedCounts[0],
                                        FeatureCountOnRawHub = new List<string>(FeaturedCounts).Contains((string)feature["featureCountOnRawHub"]) ? (string)feature["featureCountOnRawHub"] : FeaturedCounts[0],
                                        TooSoonToFeatureUser = (bool)feature["tooSoonToFeatureUser"],
                                        TinEyeResults = new List<string>(TinEyeResults).Contains((string)feature["tinEyeResults"]) ? (string)feature["tinEyeResults"] : TinEyeResults[0],
                                        AiCheckResults = new List<string>(AiCheckResults).Contains((string)feature["aiCheckResults"]) ? (string)feature["aiCheckResults"] : AiCheckResults[0]
                                    };
                                    Features.Add(loadedFeature);
                                }
                                OnPropertyChanged(nameof(HasFeatures));
                                lastFilename = dialog.FileName;
                                notificationManager.Show(
                                    "Loaded the feature log",
                                    $"Loaded {Features.Count} features for the {SelectedPage.DisplayName} page",
                                    NotificationType.Success,
                                    areaName: "WindowArea",
                                    expirationTime: TimeSpan.FromSeconds(3));
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        notificationManager.Show(
                            "Failed to load the feature log:",
                            ex.Message,
                            NotificationType.Error,
                            areaName: "WindowArea");
                    }
                }
            });

            SaveFeaturesCommand = new Command(() =>
            {
                if (SelectedPage != null)
                {
                    if (!string.IsNullOrEmpty(lastFilename))
                    {
                        try
                        {
                            Dictionary<string, dynamic> file = new()
                            {
                                ["page"] = SelectedPage.Id,
                                ["features"] = Features
                            };
                            File.WriteAllText(lastFilename, JsonConvert.SerializeObject(file));
                            notificationManager.Show(
                                "Saved the feature log",
                                $"Saved {Features.Count} features for the {SelectedPage.DisplayName} page",
                                NotificationType.Success,
                                areaName: "WindowArea",
                                expirationTime: TimeSpan.FromSeconds(3));
                        }
                        catch (Exception ex)
                        {
                            notificationManager.Show(
                                "Failed to save the feature log:",
                                ex.Message,
                                NotificationType.Error,
                                areaName: "WindowArea");
                        }
                    }
                    else
                    {
                        SaveFileDialog dialog = new()
                        {
                            Filter = "Log files (*.json)|*.json|All files (*.*)|*.*",
                            Title = "Save the features to a log file",
                            OverwritePrompt = true,
                            FileName = $"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name} - {DateTime.Now:yyyy-MM-dd}",
                        };
                        if (dialog.ShowDialog() == true)
                        {
                            try
                            {
                                Dictionary<string, dynamic> file = new()
                                {
                                    ["page"] = SelectedPage.Id,
                                    ["features"] = Features
                                };
                                File.WriteAllText(dialog.FileName, JsonConvert.SerializeObject(file));
                                lastFilename = dialog.FileName;
                                notificationManager.Show(
                                    "Saved the feature log",
                                    $"Saved {Features.Count} features for the {SelectedPage.DisplayName} page",
                                    NotificationType.Success,
                                    areaName: "WindowArea",
                                    expirationTime: TimeSpan.FromSeconds(3));
                            }
                            catch (Exception ex)
                            {
                                notificationManager.Show(
                                    "Failed to save the feature log:",
                                    ex.Message,
                                    NotificationType.Error,
                                    areaName: "WindowArea");
                            }
                        }
                    }
                }
            });

            GenerateReportCommand = new Command(GenerateLogReport);

            CopyPageTagCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is string pageTag)
                {
                    if (SelectedPage != null)
                    {
                        void ShowCopiedToast(string message)
                        {
                            notificationManager.Show(
                                "Copied tag",
                                $"Copied the {message} to the clipboard",
                                type: NotificationType.Information,
                                areaName: "WindowArea",
                                expirationTime: TimeSpan.FromSeconds(2));
                        }
                        // TODO andydragon : add setting for include hash
                        switch (pageTag)
                        {
                            case "Page tag":
                                Clipboard.SetText($"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}");
                                ShowCopiedToast("page tag");
                                break;
                            case "RAW page tag":
                                Clipboard.SetText($"raw_{SelectedPage.PageName ?? SelectedPage.Name}");
                                ShowCopiedToast("RAW page tag");
                                break;
                            case "Community tag":
                                Clipboard.SetText($"{SelectedPage.HubName}_community");
                                ShowCopiedToast("community tag");
                                break;
                            case "RAW community tag":
                                Clipboard.SetText($"raw_community");
                                ShowCopiedToast("RAW community tag");
                                break;
                            case "Hub tag":
                                Clipboard.SetText($"{SelectedPage.HubName}_hub");
                                ShowCopiedToast("hub tag");
                                break;
                            case "RAW hub tag":
                                Clipboard.SetText($"raw_hub");
                                ShowCopiedToast("RAW hub tag");
                                break;
                        }
                    }
                }
            });

            AddFeatureCommand = new Command(() =>
            {
                var feature = new Feature();
                var clipboardText = Clipboard.ContainsText() ? Clipboard.GetText().Trim() : "";
                if (clipboardText.StartsWith("https://vero.co/"))
                {
                    feature.PostLink = clipboardText;
                    feature.UserAlias = clipboardText[16..].Split('/').FirstOrDefault() ?? "";
                }
                Features.Add(feature);
                SelectedFeature = feature;
                OnPropertyChanged(nameof(HasFeatures));
            });

            RemoveFeatureCommand = new Command(() =>
            {
                if (SelectedFeature is Feature feature)
                {
                    SelectedFeature = null;
                    Features.Remove(feature);
                    OnPropertyChanged(nameof(HasFeatures));
                }
            });

            RemoveAllFeaturesCommand = new Command(() =>
            {
                SelectedFeature = null;
                Features.Clear();
                OnPropertyChanged(nameof(HasFeatures));
            });

            PastePostLinkCommand = new Command(() =>
            {
                if (SelectedFeature != null)
                {
                    var clipboardText = Clipboard.ContainsText() ? Clipboard.GetText().Trim() : "";
                    if (clipboardText.StartsWith("https://vero.co/"))
                    {
                        SelectedFeature.PostLink = clipboardText;
                        SelectedFeature.UserAlias = clipboardText[16..].Split('/').FirstOrDefault() ?? "";
                    }
                    else
                    {
                        SelectedFeature.PostLink = clipboardText;
                    }
                }
            });

            CopyPageFeatureTagCommand = new Command(() => 
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    if (SelectedPage.HubName == "other")
                    {
                        Clipboard.SetText($"{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}");
                    }
                    else
                    {
                        Clipboard.SetText($"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}");
                    }
                }
            });

            CopyRawPageFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    if (SelectedPage.HubName == "snap")
                    {
                        Clipboard.SetText($"raw_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}");
                    }
                }
            });

            CopyHubFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    if (SelectedPage.HubName != "other")
                    {
                        Clipboard.SetText($"{SelectedPage.HubName}_featured_{SelectedFeature.UserAlias}");
                    }
                }
            });

            CopyRawHubFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    if (SelectedPage.HubName == "snap")
                    {
                        Clipboard.SetText($"raw_featured_{SelectedFeature.UserAlias}");
                    }
                }
            });

            SetThemeCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is Theme theme)
                {
                    Theme = theme;
                }
            });

            #endregion
        }

        #region User settings

        public static string GetDataLocationPath(bool shared = false)
        {
            var user = WindowsIdentity.GetCurrent();
            var dataLocationPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AndyDragonSoftware",
                shared ? "VeroTools" : "FeatureLogging",
                user.Name);
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
                    notificationManager.Show(
                        "Pages loaded",
                        "Loaded " + LoadedPages.Count.ToString() + " pages from the server",
                        type: NotificationType.Information,
                        areaName: "WindowArea",
                        expirationTime: TimeSpan.FromSeconds(3));
                }
                SelectedPage = LoadedPages.FirstOrDefault(page => page.Id == Page);
                _ = LoadDisallowList();
            }
            catch (Exception ex)
            {
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
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
                var templatesUri = new Uri("https://vero.andydragon.com/static/data/disallowlist.json");
                var content = await httpClient.GetStringAsync(templatesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    Validation.DisallowList = JsonConvert.DeserializeObject<List<string>>(content) ?? [];
                }
            }
            catch (Exception ex)
            {
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
        }

        #endregion

        #region Commands

        public ICommand NewFeaturesCommand { get; }

        public ICommand OpenFeaturesCommand { get; }

        public ICommand SaveFeaturesCommand { get; }

        public ICommand GenerateReportCommand { get; }

        public ICommand CopyPageTagCommand { get; }

        public ICommand AddFeatureCommand { get; }

        public ICommand RemoveFeatureCommand { get; }

        public ICommand RemoveAllFeaturesCommand { get; }

        public ICommand PastePostLinkCommand { get; }

        public ICommand CopyPageFeatureTagCommand { get; }

        public ICommand CopyRawPageFeatureTagCommand { get; }

        public ICommand CopyHubFeatureTagCommand { get; }

        public ICommand CopyRawHubFeatureTagCommand { get; }

        public ICommand SetThemeCommand { get; }

        #endregion

        #region Theme

        private Theme? theme = ThemeManager.Current.DetectTheme();
        public Theme? Theme
        {
            get => theme;
            set
            {
                if (Set(ref theme, value))
                {
                    if (Theme != null)
                    {
                        ThemeManager.Current.ChangeTheme(Application.Current, Theme);
                        UserSettings.Store("theme", Theme.Name);
                        OnPropertyChanged(nameof(PageValidation));
                        OnPropertyChanged(nameof(StatusBarBrush));
                        OnPropertyChanged(nameof(Themes));
                        SelectedFeature?.TriggerThemeChanged();
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

        public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";

        private bool windowActive = false;
        public bool WindowActive
        {
            get => windowActive;
            set
            {
                if (Set(ref windowActive, value))
                {
                    OnPropertyChanged(nameof(StatusBarBrush));
                }
            }
        }

        public Brush? StatusBarBrush => WindowActive
            ? Theme?.Resources["MahApps.Brushes.Accent2"] as Brush
            : Theme?.Resources["MahApps.Brushes.WindowTitle.NonActive"] as Brush;

        #endregion

        #region Pages

        public ObservableCollection<LoadedPage> LoadedPages { get; } = [];

        private LoadedPage? selectedPage = null;

        public LoadedPage? SelectedPage
        {
            get => selectedPage;
            set
            {
                var oldHubName = SelectedPage?.HubName;
                if (Set(ref selectedPage, value))
                {
                    Page = SelectedPage?.Id ?? string.Empty;
                    SelectedFeature = null;
                    if (oldHubName != SelectedPage?.HubName || string.IsNullOrEmpty(Page))
                    {
                        RemoveAllFeaturesCommand.Execute(null);
                    }
                    OnPropertyChanged(nameof(Memberships));
                    OnPropertyChanged(nameof(TagSources));
                    OnPropertyChanged(nameof(ClickHubVisibility));
                    OnPropertyChanged(nameof(SnapHubVisibility));
                    OnPropertyChanged(nameof(SnapOrClickHubVisibility));
                    OnPropertyChanged(nameof(HasSelectedPage));
                }
            }
        }

        public Visibility ClickHubVisibility => SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;

        public Visibility SnapHubVisibility => SelectedPage?.HubName == "snap" ? Visibility.Visible : Visibility.Collapsed;

        public Visibility SnapOrClickHubVisibility => SelectedPage?.HubName == "snap" || SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;

        public bool HasSelectedPage => SelectedPage != null;

        #endregion

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
                if (Set(ref page, value))
                {
                    UserSettings.Store(nameof(Page), Page);
                    PageValidation = CalculatePageValidation(Page);
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

        #region Page tags

        private static string[] SnapPageTags => [
            "Page tag",
            "RAW page tag",
            "Community tag",
            "RAW community tag",
            "Hub tag",
            "RAW hub tag",
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

        #region Features

        public ObservableCollection<Feature> Features { get; } = [];

        private Feature? selectedFeature = null;

        public Feature? SelectedFeature
        {
            get => selectedFeature;
            set
            {
                if (Set(ref selectedFeature, value))
                {
                    Feature = SelectedFeature?.Id ?? string.Empty;
                    OnPropertyChanged(nameof(HasSelectedFeature));
                    OnPropertyChanged(nameof(SelectedFeatureVisibility));
                }
            }
        }
        public Visibility SelectedFeatureVisibility => SelectedPage != null && SelectedFeature != null ? Visibility.Visible : Visibility.Collapsed;

        public bool HasSelectedFeature => SelectedFeature != null;

        public bool HasFeatures => Features.Count != 0;

        #endregion

        #region Feature

        private string feature = string.Empty;
        public string Feature
        {
            get => feature;
            set => Set(ref feature, value);
        }

        #endregion

        #region Membership levels

        private static string[] SnapMemberships => [
            "None",
            "Artist",
            "Member",
            "VIP Member",
            "VIP Gold Member",
            "Platinum Member",
            "Elite Member",
            "Hall of Fame Member",
            "Diamond Member",
        ];

        private static string[] ClickMemberships => [
            "None",
            "Artist",
            "Member",
            "Bronze Member",
            "Silver Member",
            "Gold Member",
            "Platinum Member",
        ];

        private static string[] OtherMemberships => [
            "None",
            "Artist",
        ];

        public string[] Memberships =>
            SelectedPage?.HubName == "click" ? ClickMemberships :
            SelectedPage?.HubName == "snap" ? SnapMemberships :
            OtherMemberships;

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
    
        private void GenerateLogReport()
        {
            if (SelectedPage == null)
            {
                return;
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
                    builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured - {alreadyFeatured}");
                    var teammate = feature.UserIsTeammate ? "yes" : "no";
                    builder.AppendLine($"{indent}teammate - {teammate}");
                    switch (feature.TagSource)
                    {
                        case "Page tag":
                            builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}");
                            break;
                        case "Community tag":
                            builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_community");
                            break;
                        case "Hub tag":
                            builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_hub");
                            break;
                        default:
                            builder.AppendLine($"{indent}hashtag = other");
                            break;
                    }
                    builder.AppendLine($"{indent}tineye: {feature.TinEyeResults}");
                    builder.AppendLine($"{indent}ai check: {feature.AiCheckResults}");
                    builder.AppendLine();

                    if (isPicked) {
                        if (feature.UserHasFeaturesOnPage)
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on your @{SelectedPage.DisplayName} feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
                        else
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on your first @{SelectedPage.DisplayName} feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
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
                    builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured - {alreadyFeatured}");
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
                        case "Community tag":
                            builder.AppendLine($"{indent}hashtag = #{SelectedPage.HubName}_community");
                            break;
                        case "RAW Community tag":
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
                        if (feature.UserHasFeaturesOnPage)
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on this feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
                        else
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on your first @{SelectedPage.DisplayName} feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
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
                    builder.AppendLine($"{indent}feature - {feature.FeatureDescription}, featured - {alreadyFeatured}");
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
                        if (feature.UserHasFeaturesOnPage)
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on this feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
                        else
                        {
                            personalMessagesBuilder.AppendLine($"🎉💫 Congratulations on your first @{SelectedPage.DisplayName} feature {feature.UserName} @{feature.UserAlias}, [PERSONALIZED MESSAGE]");
                        }
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

            Clipboard.SetText(completeText);

            notificationManager.Show(
                "Report generated!",
                $"Copied the report of features to the clipboard",
                type: NotificationType.Information,
                areaName: "WindowArea",
                expirationTime: TimeSpan.FromSeconds(2));
        }

        internal void ShowToast(string title, string? message, NotificationType type, TimeSpan? expirationTime = null)
        {
            notificationManager.Show(
                title,
                message,
                type: type,
                areaName: "WindowArea",
                expirationTime: expirationTime);
        }
    }

    public class FeatureComparer : IComparer<Feature>
    {
        public int Compare(Feature? x, Feature? y)
        {
            // Handle null.
            if (x == null && y == null)
            {
                return 0;
            }
            if (x == null)
            {
                return -1;
            }
            if (y == null)
            {
                return 1;
            }

            // Handle photo featured on page
            if (x.PhotoFeaturedOnPage && y.PhotoFeaturedOnPage)
            {
                return string.Compare(x.UserName, y.UserName);
            }
            if (x.PhotoFeaturedOnPage)
            {
                return 1;
            }
            if (y.PhotoFeaturedOnPage)
            {
                return -1;
            }

            // Handle tin eye results
            if (x.TinEyeResults == "matches found" && y.TinEyeResults == "matches found")
            {
                return string.Compare(x.UserName, y.UserName);
            }
            if (x.TinEyeResults == "matches found")
            {
                return 1;
            }
            if (y.TinEyeResults == "matches found")
            {
                return -1;
            }

            // Handle ai check results
            if (x.AiCheckResults == "ai" && y.AiCheckResults == "ai")
            {
                return string.Compare(x.UserName, y.UserName);
            }
            if (x.AiCheckResults == "ai")
            {
                return 1;
            }
            if (y.AiCheckResults == "ai")
            {
                return -1;
            }

            // Handle too soon to feature
            if (x.TooSoonToFeatureUser && y.TooSoonToFeatureUser)
            {
                return string.Compare(x.UserName, y.UserName);
            }
            if (x.TooSoonToFeatureUser)
            {
                return 1;
            }
            if (y.TooSoonToFeatureUser)
            {
                return -1;
            }

            // Handle picked
            if (x.IsPicked && y.IsPicked)
            {
                return string.Compare(x.UserName, y.UserName);
            }
            if (x.IsPicked)
            {
                return -1;
            }
            if (y.IsPicked)
            {
                return 1;
            }

            return string.Compare(x.UserName, y.UserName);
        }

        public readonly static FeatureComparer Default = new();
    }

    public class ThemeOption(Theme theme, bool isSelected = false)
    {
        public Theme Theme { get; } = theme;

        public bool IsSelected { get; } = isSelected;
    }

    public class Feature : NotifyPropertyChanged
    {
        public Feature()
        {
            OpenFeatureInVeroScriptsCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is MainViewModel vm && vm.SelectedPage != null)
                {
                    try
                    {
                        void StoreFeatureInShared()
                        {
                            // We have debug location, let's use that for testing.
                            var featureDictionary = new Dictionary<string, dynamic>
                            {
                                ["page"] = vm.SelectedPage.Id,
                                ["userName"] = UserName,
                                ["userAlias"] = UserAlias,
                                ["userLevel"] = UserLevel,
                                ["tagSource"] = TagSource,
                                ["firstFeature"] = !UserHasFeaturesOnPage
                            };
                            if (vm.SelectedPage.HubName == "click")
                            {
                                if (int.TryParse(FeatureCountOnHub, out int featuresOnHub))
                                {
                                    var totalFeatures = featuresOnHub;
                                    featureDictionary["newLevel"] = (totalFeatures + 1) switch
                                    {
                                        5 => "Member",
                                        15 => "Bronze Member",
                                        30 => "Silver Member",
                                        50 => "Gold Member",
                                        75 => "Platinum Member",
                                        _ => "",
                                    };
                                }
                                else
                                {
                                    featureDictionary["newLevel"] = "";
                                }
                            }
                            else if (vm.SelectedPage.HubName == "snap")
                            {
                                if (int.TryParse(FeatureCountOnHub, out int featuresOnHub) && int.TryParse(FeatureCountOnRawHub, out int featuresOnRaw))
                                {
                                    var totalFeatures = featuresOnHub + featuresOnRaw;
                                    featureDictionary["newLevel"] = (totalFeatures + 1) switch
                                    {
                                        5 => "Member",
                                        15 => "VIP Member",
                                        _ => "",
                                    };
                                }
                                else
                                {
                                    featureDictionary["newLevel"] = "";
                                }
                            }
                            else
                            {
                                featureDictionary["newLevel"] = "";
                            }

                            var sharedSettingsPath = MainViewModel.GetDataLocationPath(true);
                            var featureFile = Path.Combine(sharedSettingsPath, "feature.json");
                            File.WriteAllText(featureFile, JsonConvert.SerializeObject(featureDictionary));
                        }

#if DEBUG
                        // For debugging, test locally
                        var debugVeroScriptsLocation = UserSettings.Get("debugVeroScriptsLocation", "");
                        if (!string.IsNullOrEmpty(debugVeroScriptsLocation))
                        {
                            StoreFeatureInShared();
                            var applicationPath = Path.Combine(debugVeroScriptsLocation, "Vero Scripts.exe");
                            var processStart = new ProcessStartInfo
                            {
                                FileName = applicationPath,
                                WindowStyle = ProcessWindowStyle.Maximized,
                            };
                            Process.Start(processStart);
                            return;
                        }
#endif
                        // Launch from application deployment manifest on web.
                        StoreFeatureInShared();
                        var applicationDeploymentManifest = "https://vero.andydragon.com/app/veroscripts/windows/Vero%20Scripts.application";
                        Process.Start("rundll32.exe", "dfshim.dll,ShOpenVerbApplication " + applicationDeploymentManifest);
                    }
                    catch (Exception ex)
                    {
                        vm.ShowToast("Failed to launch Vero Scripts", ex.Message, NotificationType.Error);
                    }
                }
            });
        }

        [JsonIgnore]
        public readonly string Id = Guid.NewGuid().ToString();

        private bool isPicked = false;
        [JsonProperty(PropertyName = "isPicked")]
        public bool IsPicked
        {
            get => isPicked;
            set => Set(ref isPicked, value, [nameof(Icon), nameof(IconColor)]);
        }

        private string postLink = "";
        [JsonProperty(PropertyName = "postLink")]
        public string PostLink
        {
            get => postLink;
            set => Set(ref postLink, value, [nameof(PostLinkValidation)]);
        }
        [JsonIgnore]
        public ValidationResult PostLinkValidation => Validation.ValidateValueNotEmpty(postLink);

        private string userName = "";
        [JsonProperty(PropertyName = "userName")]
        public string UserName
        {
            get => userName;
            set => Set(ref userName, value, [nameof(UserNameValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserNameValidation => Validation.ValidateValueNotEmpty(userName);

        private string userAlias = "";
        [JsonProperty(PropertyName = "userAlias")]
        public string UserAlias
        {
            get => userAlias;
            set => Set(ref userAlias, value, [nameof(UserAliasValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserAliasValidation => Validation.ValidateUserName(userAlias);

        private string userLevel = "None";
        [JsonProperty(PropertyName = "userLevel")]
        public string UserLevel
        {
            get => userLevel;
            set => Set(ref userLevel, value, [nameof(UserLevelValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserLevelValidation => Validation.ValidateValueNotDefault(userLevel, "None");

        private bool userIsTeammate = false;
        [JsonProperty(PropertyName = "userIsTeammate")]
        public bool UserIsTeammate
        {
            get => userIsTeammate;
            set => Set(ref userIsTeammate, value);
        }

        private string tagSource = "Page tag";
        [JsonProperty(PropertyName = "tagSource")]
        public string TagSource
        {
            get => tagSource;
            set => Set(ref tagSource, value);
        }

        private bool photoFeaturedOnPage = false;
        [JsonProperty(PropertyName = "photoFeaturedOnPage")]
        public bool PhotoFeaturedOnPage
        {
            get => photoFeaturedOnPage;
            set => Set(ref photoFeaturedOnPage, value, [nameof(Icon), nameof(IconColor)]);
        }

        private string featureDescription = "";
        [JsonProperty(PropertyName = "featureDescription")]
        public string FeatureDescription
        {
            get => featureDescription;
            set => Set(ref featureDescription, value, [nameof(FeatureDescriptionValidation)]);
        }
        [JsonIgnore]
        public ValidationResult FeatureDescriptionValidation => Validation.ValidateValueNotEmpty(featureDescription);

        private bool userHasFeaturesOnPage = false;
        [JsonProperty(PropertyName = "userHasFeaturesOnPage")]
        public bool UserHasFeaturesOnPage
        {
            get => userHasFeaturesOnPage;
            set => Set(ref userHasFeaturesOnPage, value);
        }

        private string lastFeaturedOnPage = "";
        [JsonProperty(PropertyName = "lastFeaturedOnPage")]
        public string LastFeaturedOnPage
        {
            get => lastFeaturedOnPage;
            set => Set(ref lastFeaturedOnPage, value, [nameof(LastFeaturedOnPageValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedOnPageValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnPage);

        private string featureCountOnPage = "many";
        [JsonProperty(PropertyName = "featureCountOnPage")]
        public string FeatureCountOnPage
        {
            get => featureCountOnPage;
            set => Set(ref featureCountOnPage, value);
        }

        private string featureCountOnRawPage = "many";
        [JsonProperty(PropertyName = "featureCountOnRawPage")]
        public string FeatureCountOnRawPage
        {
            get => featureCountOnRawPage;
            set => Set(ref featureCountOnRawPage, value);
        }

        private bool userHasFeaturesOnHub = false;
        [JsonProperty(PropertyName = "userHasFeaturesOnHub")]
        public bool UserHasFeaturesOnHub
        {
            get => userHasFeaturesOnHub;
            set => Set(ref userHasFeaturesOnHub, value);
        }

        private string lastFeaturedOnHub = "";
        [JsonProperty(PropertyName = "lastFeaturedOnHub")]
        public string LastFeaturedOnHub
        {
            get => lastFeaturedOnHub;
            set => Set(ref lastFeaturedOnHub, value, [nameof(LastFeaturedOnHubValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedOnHubValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnHub);

        private string lastFeaturedPage = "";
        [JsonProperty(PropertyName = "lastFeaturedPage")]
        public string LastFeaturedPage
        {
            get => lastFeaturedPage;
            set => Set(ref lastFeaturedPage, value, [nameof(LastFeaturedPageValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedPageValidation => Validation.ValidateValueNotEmpty(lastFeaturedPage);

        private string featureCountOnHub = "many";
        [JsonProperty(PropertyName = "featureCountOnHub")]
        public string FeatureCountOnHub
        {
            get => featureCountOnHub;
            set => Set(ref featureCountOnHub, value);
        }

        private string featureCountOnRawHub = "many";
        [JsonProperty(PropertyName = "featureCountOnRawHub")]
        public string FeatureCountOnRawHub
        {
            get => featureCountOnRawHub;
            set => Set(ref featureCountOnRawHub, value);
        }

        private bool tooSoonToFeatureUser = false;
        [JsonProperty(PropertyName = "tooSoonToFeatureUser")]
        public bool TooSoonToFeatureUser
        {
            get => tooSoonToFeatureUser;
            set => Set(ref tooSoonToFeatureUser, value, [nameof(Icon), nameof(IconColor)]);
        }

        private string tinEyeResults = "0 matches";
        [JsonProperty(PropertyName = "tinEyeResults")]
        public string TinEyeResults
        {
            get => tinEyeResults;
            set => Set(ref tinEyeResults, value, [nameof(Icon), nameof(IconColor)]);
        }

        private string aiCheckResults = "human";
        [JsonProperty(PropertyName = "aiCheckResults")]
        public string AiCheckResults
        {
            get => aiCheckResults;
            set => Set(ref aiCheckResults, value, [nameof(Icon), nameof(IconColor)]);
        }

        [JsonIgnore]
        public PackIconModernKind Icon
        {
            get
            {
                if (PhotoFeaturedOnPage)
                {
                    return PackIconModernKind.Alert;
                }
                if (TooSoonToFeatureUser)
                {
                    return PackIconModernKind.TimerAlert;
                }
                if (TinEyeResults == "matches found")
                {
                    return PackIconModernKind.ShieldAlert;
                }
                if (AiCheckResults == "ai")
                {
                    return PackIconModernKind.ShieldAlert;
                }
                if (IsPicked)
                {
                    return PackIconModernKind.Star;
                }
                return PackIconModernKind.Close;
            }
        }

        [JsonIgnore]
        public Brush IconColor
        {
            get
            {
                if (PhotoFeaturedOnPage)
                {
                    return Brushes.Red;
                }
                if (TooSoonToFeatureUser)
                {
                    return Brushes.Red;
                }
                if (TinEyeResults == "matches found")
                {
                    return Brushes.Red;
                }
                if (AiCheckResults == "ai")
                {
                    return Brushes.Red;
                }
                if (IsPicked)
                {
                    return Brushes.Lime;
                }
                return Brushes.Transparent;
            }
        }

        [JsonIgnore]
        public string IconTooltip
        {
            get
            {
                if (PhotoFeaturedOnPage)
                {
                    return "Photo is already featured on this page";
                }
                if (TooSoonToFeatureUser)
                {
                    return "Too soon to feature this user";
                }
                if (TinEyeResults == "matches found")
                {
                    return "TinEye matches found, possibly stolen photo";
                }
                if (AiCheckResults == "ai")
                {
                    return "AI check verdict is image is AI generated";
                }
                if (IsPicked)
                {
                    return "Photo is picked for feature";
                }
                return "";
            }
        }

        [JsonIgnore]
        public ICommand OpenFeatureInVeroScriptsCommand { get;  }

        internal void TriggerThemeChanged()
        {
            OnPropertyChanged(nameof(PostLinkValidation));
            OnPropertyChanged(nameof(UserAliasValidation));
            OnPropertyChanged(nameof(UserNameValidation));
            OnPropertyChanged(nameof(UserLevelValidation));
            OnPropertyChanged(nameof(FeatureDescriptionValidation));
            OnPropertyChanged(nameof(LastFeaturedOnPageValidation));
            OnPropertyChanged(nameof(LastFeaturedOnHubValidation));
            OnPropertyChanged(nameof(LastFeaturedPageValidation));
        }
    }
}
