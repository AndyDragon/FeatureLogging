using ControlzEx.Theming;
using MahApps.Metro.Controls;
using MahApps.Metro.Controls.Dialogs;
using MahApps.Metro.IconPacks;
using Microsoft.Win32;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Runtime.InteropServices;
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

            NewFeaturesCommand = new CommandWithParameter((ignoreDirty) =>
            {
                if (IsDirty && ignoreDirty == null)
                {
                    HandleDirtyAction("creating a new log", (completed) =>
                    {
                        NewFeaturesCommand?.Execute(true);
                    });
                    return;
                }

                lastFilename = string.Empty;
                SelectedFeature = null;
                Features.Clear();
                OnPropertyChanged(nameof(HasFeatures));
                IsDirty = false;
            });

            OpenFeaturesCommand = new CommandWithParameter((ignoreDirty) =>
            {
                if (IsDirty && ignoreDirty == null)
                {
                    HandleDirtyAction("opening a different log", (completed) =>
                    {
                        OpenFeaturesCommand?.Execute(true);
                    });
                    return;
                }

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
                                        PhotoFeaturedOnHub = feature.ContainsKey("photoFeaturedOnHub") ? (bool)feature["photoFeaturedOnHub"] : false,
                                        PhotoLastFeaturedOnHub = feature.ContainsKey("photoLastFeaturedOnHub") ? (string)feature["photoLastFeaturedOnHub"] : "",
                                        PhotoLastFeaturedPage = feature.ContainsKey("photoLastFeaturedPage") ? (string)feature["photoLastFeaturedPage"] : "",
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
                                        AiCheckResults = new List<string>(AiCheckResults).Contains((string)feature["aiCheckResults"]) ? (string)feature["aiCheckResults"] : AiCheckResults[0],
                                        PersonalMessage = feature.ContainsKey("personalMessage") ? (string)feature["personalMessage"] : "",
                                    };
                                    Features.Add(loadedFeature);
                                }
                                OnPropertyChanged(nameof(HasFeatures));
                                lastFilename = dialog.FileName;
                                IsDirty = false;
                                foreach (var feature in Features)
                                {
                                    feature.IsDirty = false;
                                }
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
                        SaveLog(lastFilename);
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
                            SaveLog(dialog.FileName);
                        }
                    }
                }

                void SaveLog(string fileName)
                {
                    try
                    {
                        Dictionary<string, dynamic> file = new()
                        {
                            ["features"] = Features,
                            ["page"] = SelectedPage.Id,
                        };
                        var jsonSettings = new JsonSerializerSettings
                        {
                            ContractResolver = new OrderedContractResolver(),
                        };
                        File.WriteAllText(fileName, JsonConvert.SerializeObject(file, Formatting.Indented, jsonSettings).Replace("\": ", "\" : "));
                        lastFilename = fileName;
                        IsDirty = false;
                        foreach (var feature in Features)
                        {
                            feature.IsDirty = false;
                        }
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
            });

            GenerateReportCommand = new Command(() =>
            {
                if (SelectedPage == null)
                {
                    return;
                }

                CopyTextToClipboard(GenerateLogReport(), "Generated report", "Copied the report of features to the clipboard");
            });

            SaveReportCommand = new Command(() => 
            {
                if (SelectedPage == null)
                {
                    return;
                }

                string initialFileName;
                if (!string.IsNullOrEmpty(lastFilename))
                {
                    initialFileName = Path.ChangeExtension(lastFilename, ".features");
                }
                else
                {
                    initialFileName = $"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name} - {DateTime.Now:yyyy-MM-dd}";
                }
                SaveFileDialog dialog = new()
                {
                    Filter = "Feature report files (*.features)|*.features|All files (*.*)|*.*",
                    Title = "Save the features to a report file",
                    OverwritePrompt = true,
                    FileName = initialFileName,
                };
                if (dialog.ShowDialog() == true)
                {
                    File.WriteAllText(dialog.FileName, GenerateLogReport());
                }
            });

            LaunchSettingsCommand = new Command(() =>
            {
                var panel = new SettingsDialog
                {
                    DataContext = Settings,
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
                panel.ShowDialog();
            });

            CopyPageTagCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is string pageTag)
                {
                    if (SelectedPage != null)
                    {
                        void CopyTag(string tag, string tagType)
                        {
                            CopyTextToClipboard(tag, "Copy tag", $"Copied the {tagType} to the clipboard");
                        }
                        var prefix = Settings.IncludeHash ? "#" : "";
                        switch (pageTag)
                        {
                            case "Page tag":
                                CopyTag($"{prefix}{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}", "page tag");
                                break;
                            case "RAW page tag":
                                CopyTag($"{prefix}raw_{SelectedPage.PageName ?? SelectedPage.Name}", "RAW page tag");
                                break;
                            case "Community tag":
                                CopyTag($"{prefix}{SelectedPage.HubName}_community", "community tag");
                                break;
                            case "RAW community tag":
                                CopyTag($"{prefix}raw_community", "RAW community tag");
                                break;
                            case "Hub tag":
                                CopyTag($"{prefix}{SelectedPage.HubName}_hub", "hub tag");
                                break;
                            case "RAW hub tag":
                                CopyTag($"{prefix}raw_hub", "RAW hub tag");
                                break;
                        }
                    }
                }
            });

            AddFeatureCommand = new Command(() =>
            {
                var clipboardText = Clipboard.ContainsText() ? Clipboard.GetText().Trim() : "";
                var duplicateFeature = Features.FirstOrDefault(feature => feature.PostLink == clipboardText);
                if (duplicateFeature != null)
                {
                    ShowToast(
                        "Found duplicate post link", 
                        "There is already a feature in the list with that post link, selected the existing feature", 
                        NotificationType.Error, 
                        TimeSpan.FromSeconds(3));
                    SelectedFeature = duplicateFeature;
                    return;
                }
                var feature = new Feature();
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
                    var prefix = Settings.IncludeHash ? "#" : "";
                    if (SelectedPage.HubName == "other")
                    {
                        CopyTextToClipboard($"{prefix}{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}", "Page feature tag", "Copied the page feature tag to the clipboard");
                    }
                    else
                    {
                        CopyTextToClipboard($"{prefix}{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}", "Page feature tag", "Copied the page feature tag to the clipboard");
                    }
                }
            });

            CopyRawPageFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    var prefix = Settings.IncludeHash ? "#" : "";
                    if (SelectedPage.HubName == "snap")
                    {
                        CopyTextToClipboard($"{prefix}raw_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature.UserAlias}", "RAW page feature tag", "Copied the RAW page feature tag to the clipboard");
                    }
                }
            });

            CopyHubFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    var prefix = Settings.IncludeHash ? "#" : "";
                    if (SelectedPage.HubName != "other")
                    {
                        CopyTextToClipboard($"{prefix}{SelectedPage.HubName}_featured_{SelectedFeature.UserAlias}", "Hub feature tag", "Copied the hub feature tag to the clipboard");
                    }
                }
            });

            CopyRawHubFeatureTagCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    var prefix = Settings.IncludeHash ? "#" : "";
                    if (SelectedPage.HubName == "snap")
                    {
                        CopyTextToClipboard($"{prefix}raw_featured_{SelectedFeature.UserAlias}", "RAW hub feature tag", "Copied the RAW hub feature tag to the clipboard");
                    }
                }
            });

            CopyPersonalMessageCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null)
                {
                    var personalMessageTemplate = SelectedFeature.UserHasFeaturesOnPage
                        ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                            ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                            : Settings.PersonalMessage)
                        : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                            ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                            : Settings.PersonalMessageFirst);
                    var fullMessage = personalMessageTemplate
                        .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                        .Replace("%%HUBNAME%%", SelectedPage.HubName)
                        .Replace("%%USERNAME%%", SelectedFeature.UserName)
                        .Replace("%%USERALIAS%%", SelectedFeature.UserAlias)
                        .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(SelectedFeature.PersonalMessage) ? "[PERSONAL MESSAGE]" : SelectedFeature.PersonalMessage);
                    CopyTextToClipboard(fullMessage, "Copied to clipboard", "The personal message was copied to the clipboard");
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

            #region Dirty state management

            void ItemChanged(object? sender, PropertyChangedEventArgs e)
            {
                if (sender is Feature feature && e.PropertyName == nameof(feature.IsDirty))
                {
                    IsDirty |= feature.IsDirty;
                }
            }

            Features.CollectionChanged += (sender, e) =>
            {
                if (e.OldItems != null)
                {
                    foreach (INotifyPropertyChanged item in e.OldItems)
                    {
                        item.PropertyChanged -= ItemChanged;
                    }
                }
                if (e.NewItems != null)
                {
                    foreach (INotifyPropertyChanged item in e.NewItems)
                    {
                        item.PropertyChanged += ItemChanged;
                    }
                }
                IsDirty = true;
            };

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

        public static Settings Settings => new();

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
                IsDirty = false;
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

        public ICommand SaveReportCommand { get; }

        public ICommand LaunchSettingsCommand { get; }

        public ICommand CopyPageTagCommand { get; }

        public ICommand AddFeatureCommand { get; }

        public ICommand RemoveFeatureCommand { get; }

        public ICommand RemoveAllFeaturesCommand { get; }

        public ICommand PastePostLinkCommand { get; }

        public ICommand CopyPageFeatureTagCommand { get; }

        public ICommand CopyRawPageFeatureTagCommand { get; }

        public ICommand CopyHubFeatureTagCommand { get; }

        public ICommand CopyRawHubFeatureTagCommand { get; }

        public ICommand CopyPersonalMessageCommand { get; }

        public ICommand SetThemeCommand { get; }

        #endregion

        #region Dirty state

        private bool isDirty = false;
        public bool IsDirty
        {
            get => isDirty;
            set => Set(ref isDirty, value, [nameof(Title)]);
        }

        public string Title => $"Feature Logging {(IsDirty ? " - edited" : string.Empty)}";

        public void HandleDirtyAction(string action, Action<bool> onConfirmAction)
        {
            switch (MessageBox.Show(
                Application.Current.MainWindow,
                "The current log document has been edited. Would you like to save the log before " + action + "?", 
                "Log not saved", 
                MessageBoxButton.YesNoCancel,
                MessageBoxImage.Question))
            {
                case MessageBoxResult.Yes:
                    SaveFeaturesCommand.Execute(null);
                    if (!IsDirty)
                    {
                        onConfirmAction(true);
                    }
                    break;

                case MessageBoxResult.No:
                    onConfirmAction(false);
                    break;

                case MessageBoxResult.Cancel:
                    break;
            }
        }

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
                    OnPropertyChanged(nameof(PageTags));
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
                    IsDirty = true;
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

                    if (isPicked) {
                        var personalMessageTemplate = feature.UserHasFeaturesOnPage
                            ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                                ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessage)
                            : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                                ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessageFirst);
                        var fullMessage = personalMessageTemplate
                            .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                            .Replace("%%HUBNAME%%", SelectedPage.HubName)
                            .Replace("%%USERNAME%%", feature.UserName)
                            .Replace("%%USERALIAS%%", feature.UserAlias)
                            .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                        personalMessagesBuilder.AppendLine(fullMessage);
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
                        var personalMessageTemplate = feature.UserHasFeaturesOnPage
                            ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                                ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessage)
                            : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                                ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessageFirst);
                        var fullMessage = personalMessageTemplate
                            .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                            .Replace("%%HUBNAME%%", SelectedPage.HubName)
                            .Replace("%%USERNAME%%", feature.UserName)
                            .Replace("%%USERALIAS%%", feature.UserAlias)
                            .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                        personalMessagesBuilder.AppendLine(fullMessage);
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
                        var personalMessageTemplate = feature.UserHasFeaturesOnPage
                            ? (string.IsNullOrEmpty(Settings.PersonalMessage)
                                ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessage)
                            : (string.IsNullOrEmpty(Settings.PersonalMessageFirst)
                                ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                                : Settings.PersonalMessageFirst);
                        var fullMessage = personalMessageTemplate
                            .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                            .Replace("%%HUBNAME%%", "")
                            .Replace("%%USERNAME%%", feature.UserName)
                            .Replace("%%USERALIAS%%", feature.UserAlias)
                            .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(feature.PersonalMessage) ? "[PERSONAL MESSAGE]" : feature.PersonalMessage);
                        personalMessagesBuilder.AppendLine(fullMessage);
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

        public void CopyTextToClipboard(string text, string title, string successMessage)
        {
            if (TrySetClipboardText(text))
            {
                notificationManager.Show(
                    title,
                    successMessage,
                    type: NotificationType.Information,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                notificationManager.Show(
                    title + " failed",
                    "Could not copy text to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(12));
            }
        }

        private static bool TrySetClipboardText(string text)
        {
            const uint CLIPBRD_E_CANT_OPEN = 0x800401D0;
            var retriesLeft = 9;
            while (retriesLeft >= 0)
            {
                try
                {
                    Clipboard.Clear();
                    Clipboard.SetText(text);
                    return true;
                }
                catch (COMException ex)
                {
                    if ((uint)ex.ErrorCode != CLIPBRD_E_CANT_OPEN)
                    {
                        throw;
                    }
                    --retriesLeft;
                    Thread.Sleep((9 - retriesLeft) * 10);
                }
            }
            return false;
        }

        #endregion

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
            EditPersonalMessageCommand = new CommandWithParameter((parameter) => {
                if (parameter is MainViewModel vm && vm.SelectedPage != null)
                {
                    vm.SelectedFeature = this;
                    PersonalMessageDialog dialog = new()
                    {
                        DataContext = vm,
                        Owner = Application.Current.MainWindow,
                        WindowStartupLocation = WindowStartupLocation.CenterOwner,
                    };
                    dialog.ShowDialog();
                }
            });
            OpenFeatureInVeroScriptsCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is MainViewModel vm && vm.SelectedPage != null)
                {
                    if (PhotoFeaturedOnPage)
                    {
                        vm.ShowToast("Cannot feature photo", "That photo has already been featured on this page", NotificationType.Error, TimeSpan.FromSeconds(12));
                        return;
                    }
                    if (TinEyeResults == "matches found")
                    {
                        vm.ShowToast("Cannot feature photo", "That photo has a TinEye match", NotificationType.Error, TimeSpan.FromSeconds(12));
                        return;
                    }
                    if (AiCheckResults == "ai")
                    {
                        vm.ShowToast("Cannot feature photo", "This photo was flagged as AI", NotificationType.Error, TimeSpan.FromSeconds(12));
                        return;
                    }
                    if (TooSoonToFeatureUser)
                    {
                        vm.ShowToast("Cannot feature photo", "The user has been featured too recently", NotificationType.Error, TimeSpan.FromSeconds(12));
                        return;
                    }
                    if (!IsPicked)
                    {
                        vm.ShowToast("Cannot feature photo", "The photo is not marked as picked, mark the photo as picked and try again", NotificationType.Warning, TimeSpan.FromSeconds(8));
                        return;
                    }
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

        [JsonIgnore]
        public bool IsPickedAndAllowed
        {
            get => IsPicked && !TooSoonToFeatureUser && !PhotoFeaturedOnPage && TinEyeResults != "matches found" && AiCheckResults != "ai";
        }

        [JsonIgnore]
        private bool isDirty = false;
        [JsonIgnore]
        public bool IsDirty
        {
            get => isDirty;
            set => Set(ref isDirty, value);
        }

        private bool isPicked = false;
        [JsonProperty(PropertyName = "isPicked")]
        public bool IsPicked
        {
            get => isPicked;
            set => SetWithDirtyCallback(ref isPicked, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed)]);
        }

        private string postLink = "";
        [JsonProperty(PropertyName = "postLink")]
        public string PostLink
        {
            get => postLink;
            set => SetWithDirtyCallback(ref postLink, value, () => IsDirty = true, [nameof(PostLinkValidation)]);
        }
        [JsonIgnore]
        public ValidationResult PostLinkValidation => Validation.ValidateValueNotEmpty(postLink);

        private string userName = "";
        [JsonProperty(PropertyName = "userName")]
        public string UserName
        {
            get => userName;
            set => SetWithDirtyCallback(ref userName, value, () => IsDirty = true, [nameof(UserNameValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserNameValidation => Validation.ValidateValueNotEmpty(userName);

        private string userAlias = "";
        [JsonProperty(PropertyName = "userAlias")]
        public string UserAlias
        {
            get => userAlias;
            set => SetWithDirtyCallback(ref userAlias, value, () => IsDirty = true, [nameof(UserAliasValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserAliasValidation => Validation.ValidateUserName(userAlias);

        private string userLevel = "None";
        [JsonProperty(PropertyName = "userLevel")]
        public string UserLevel
        {
            get => userLevel;
            set => SetWithDirtyCallback(ref userLevel, value, () => IsDirty = true, [nameof(UserLevelValidation)]);
        }
        [JsonIgnore]
        public ValidationResult UserLevelValidation => Validation.ValidateValueNotDefault(userLevel, "None");

        private bool userIsTeammate = false;
        [JsonProperty(PropertyName = "userIsTeammate")]
        public bool UserIsTeammate
        {
            get => userIsTeammate;
            set => SetWithDirtyCallback(ref userIsTeammate, value, () => IsDirty = true);
        }

        private string tagSource = "Page tag";
        [JsonProperty(PropertyName = "tagSource")]
        public string TagSource
        {
            get => tagSource;
            set => SetWithDirtyCallback(ref tagSource, value, () => IsDirty = true);
        }

        private bool photoFeaturedOnPage = false;
        [JsonProperty(PropertyName = "photoFeaturedOnPage")]
        public bool PhotoFeaturedOnPage
        {
            get => photoFeaturedOnPage;
            set => SetWithDirtyCallback(ref photoFeaturedOnPage, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed)]);
        }

        private bool photoFeaturedOnHub = false;
        [JsonProperty(PropertyName = "photoFeaturedOnHub")]
        public bool PhotoFeaturedOnHub
        {
            get => photoFeaturedOnHub;
            set => SetWithDirtyCallback(ref photoFeaturedOnHub, value, () => IsDirty = true);
        }

        private string photoLastFeaturedOnHub = "";
        [JsonProperty(PropertyName = "photoLastFeaturedOnHub")]
        public string PhotoLastFeaturedOnHub
        {
            get => photoLastFeaturedOnHub;
            set => SetWithDirtyCallback(ref photoLastFeaturedOnHub, value, () => IsDirty = true, [nameof(PhotoLastFeaturedOnHubValidation)]);
        }
        [JsonIgnore]
        public ValidationResult PhotoLastFeaturedOnHubValidation => Validation.ValidateValueNotEmpty(photoLastFeaturedOnHub);

        private string photoLastFeaturedPage = "";
        [JsonProperty(PropertyName = "photoLastFeaturedPage")]
        public string PhotoLastFeaturedPage
        {
            get => photoLastFeaturedPage;
            set => SetWithDirtyCallback(ref photoLastFeaturedPage, value, () => IsDirty = true, [nameof(PhotoLastFeaturedPageValidation)]);
        }
        [JsonIgnore]
        public ValidationResult PhotoLastFeaturedPageValidation => Validation.ValidateValueNotEmpty(photoLastFeaturedPage);

        private string featureDescription = "";
        [JsonProperty(PropertyName = "featureDescription")]
        public string FeatureDescription
        {
            get => featureDescription;
            set => SetWithDirtyCallback(ref featureDescription, value, () => IsDirty = true, [nameof(FeatureDescriptionValidation)]);
        }
        [JsonIgnore]
        public ValidationResult FeatureDescriptionValidation => Validation.ValidateValueNotEmpty(featureDescription);

        private bool userHasFeaturesOnPage = false;
        [JsonProperty(PropertyName = "userHasFeaturesOnPage")]
        public bool UserHasFeaturesOnPage
        {
            get => userHasFeaturesOnPage;
            set => SetWithDirtyCallback(ref userHasFeaturesOnPage, value, () => IsDirty = true);
        }

        private string lastFeaturedOnPage = "";
        [JsonProperty(PropertyName = "lastFeaturedOnPage")]
        public string LastFeaturedOnPage
        {
            get => lastFeaturedOnPage;
            set => SetWithDirtyCallback(ref lastFeaturedOnPage, value, () => IsDirty = true, [nameof(LastFeaturedOnPageValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedOnPageValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnPage);

        private string featureCountOnPage = "many";
        [JsonProperty(PropertyName = "featureCountOnPage")]
        public string FeatureCountOnPage
        {
            get => featureCountOnPage;
            set => SetWithDirtyCallback(ref featureCountOnPage, value, () => IsDirty = true);
        }

        private string featureCountOnRawPage = "many";
        [JsonProperty(PropertyName = "featureCountOnRawPage")]
        public string FeatureCountOnRawPage
        {
            get => featureCountOnRawPage;
            set => SetWithDirtyCallback(ref featureCountOnRawPage, value, () => IsDirty = true);
        }

        private bool userHasFeaturesOnHub = false;
        [JsonProperty(PropertyName = "userHasFeaturesOnHub")]
        public bool UserHasFeaturesOnHub
        {
            get => userHasFeaturesOnHub;
            set => SetWithDirtyCallback(ref userHasFeaturesOnHub, value, () => IsDirty = true);
        }

        private string lastFeaturedOnHub = "";
        [JsonProperty(PropertyName = "lastFeaturedOnHub")]
        public string LastFeaturedOnHub
        {
            get => lastFeaturedOnHub;
            set => SetWithDirtyCallback(ref lastFeaturedOnHub, value, () => IsDirty = true, [nameof(LastFeaturedOnHubValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedOnHubValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnHub);

        private string lastFeaturedPage = "";
        [JsonProperty(PropertyName = "lastFeaturedPage")]
        public string LastFeaturedPage
        {
            get => lastFeaturedPage;
            set => SetWithDirtyCallback(ref lastFeaturedPage, value, () => IsDirty = true, [nameof(LastFeaturedPageValidation)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedPageValidation => Validation.ValidateValueNotEmpty(lastFeaturedPage);

        private string featureCountOnHub = "many";
        [JsonProperty(PropertyName = "featureCountOnHub")]
        public string FeatureCountOnHub
        {
            get => featureCountOnHub;
            set => SetWithDirtyCallback(ref featureCountOnHub, value, () => IsDirty = true);
        }

        private string featureCountOnRawHub = "many";
        [JsonProperty(PropertyName = "featureCountOnRawHub")]
        public string FeatureCountOnRawHub
        {
            get => featureCountOnRawHub;
            set => SetWithDirtyCallback(ref featureCountOnRawHub, value, () => IsDirty = true);
        }

        private bool tooSoonToFeatureUser = false;
        [JsonProperty(PropertyName = "tooSoonToFeatureUser")]
        public bool TooSoonToFeatureUser
        {
            get => tooSoonToFeatureUser;
            set => SetWithDirtyCallback(ref tooSoonToFeatureUser, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed)]);
        }

        private string tinEyeResults = "0 matches";
        [JsonProperty(PropertyName = "tinEyeResults")]
        public string TinEyeResults
        {
            get => tinEyeResults;
            set => SetWithDirtyCallback(ref tinEyeResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed)]);
        }

        private string aiCheckResults = "human";
        [JsonProperty(PropertyName = "aiCheckResults")]
        public string AiCheckResults
        {
            get => aiCheckResults;
            set => SetWithDirtyCallback(ref aiCheckResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed)]);
        }

        private string personalMessage = "";
        [JsonProperty(PropertyName = "personalMessage")]
        public string PersonalMessage
        {
            get => personalMessage;
            set => SetWithDirtyCallback(ref personalMessage, value, () => IsDirty = true);
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

        [JsonIgnore]
        public ICommand EditPersonalMessageCommand { get; }

        internal void TriggerThemeChanged()
        {
            OnPropertyChanged(nameof(PostLinkValidation));
            OnPropertyChanged(nameof(UserAliasValidation));
            OnPropertyChanged(nameof(UserNameValidation));
            OnPropertyChanged(nameof(UserLevelValidation));
            OnPropertyChanged(nameof(FeatureDescriptionValidation));
            OnPropertyChanged(nameof(PhotoLastFeaturedOnHubValidation));
            OnPropertyChanged(nameof(PhotoLastFeaturedPageValidation));
            OnPropertyChanged(nameof(LastFeaturedOnPageValidation));
            OnPropertyChanged(nameof(LastFeaturedOnHubValidation));
            OnPropertyChanged(nameof(LastFeaturedPageValidation));
        }
    }

    public class OrderedContractResolver : DefaultContractResolver
    {
        protected override IList<JsonProperty> CreateProperties(Type type, MemberSerialization memberSerialization)
        {
            var @base = base.CreateProperties(type, memberSerialization);
            var ordered = @base
                .OrderBy(p => p.Order ?? int.MaxValue)
                .ThenBy(p => p.PropertyName)
                .ToList();
            return ordered;
        }
    }

    public class Settings : NotifyPropertyChanged
    {
        private bool includeHash = UserSettings.Get(
            nameof(IncludeHash), 
            false);
        public bool IncludeHash {
            get => includeHash;
            set
            {
                if (Set(ref includeHash, value))
                {
                    UserSettings.Store(nameof(IncludeHash), value);
                }
            }
        }

        private string personalMessage = UserSettings.Get(
            nameof(PersonalMessage),
            "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉");
        public string PersonalMessage
        {
            get => personalMessage;
            set
            {
                if (Set(ref personalMessage, value))
                {
                    UserSettings.Store(nameof(PersonalMessage), value);
                }
            }
        }

        private string personalMessageFirst = UserSettings.Get(
            nameof(PersonalMessageFirst), 
            "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉");
        public string PersonalMessageFirst
        {
            get => personalMessageFirst;
            set
            {
                if (Set(ref personalMessageFirst, value))
                {
                    UserSettings.Store(nameof(PersonalMessageFirst), value);
                }
            }
        }
    }
}
