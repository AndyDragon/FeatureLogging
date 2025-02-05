using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net.Http.Headers;
using System.Net.Http;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows;

using ControlzEx.Theming;
using LiveCharts.Defaults;
using LiveCharts.Wpf;
using LiveCharts;
using MahApps.Metro.IconPacks;
using Microsoft.Win32;
using Newtonsoft.Json.Serialization;
using Newtonsoft.Json;
using Notification.Wpf;

namespace FeatureLogging
{
    public static class Validation
    {
        private static Dictionary<string, List<string>> disallowList = [];

        public static Dictionary<string, List<string>> DisallowList
        {
            get => disallowList;
            set => disallowList = value;
        }

        #region Field validation

        public static ValidationResult ValidateUser(string hubName, string userName)
        {
            var userNameValidationResult = ValidateUserName(userName);
            if (!userNameValidationResult.Valid)
            {
                return userNameValidationResult;
            }
            if (DisallowList.TryGetValue(hubName, out List<string>? value) &&
                value.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null)
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
            if (userName.Length <= 1)
            {
                return new ValidationResult(false, "User name should be more than 1 character long");
            }
            return new ValidationResult(true);
        }

        internal static ValidationResult ValidateValueNotEmptyAndContainsNoNewlines(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return new ValidationResult(false, "Required value");
            }
            if (value.Contains('\n'))
            {
                return new ValidationResult(false, "Value cannot contain newline");
            }
            if (value.Contains('\r'))
            {
                return new ValidationResult(false, "Value cannot contain newline");
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
            scriptViewModel = new ScriptsViewModel(this);

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
                OnPropertyChanged(nameof(FeatureNavigationVisibility));
                OnPropertyChanged(nameof(CanChangePage));
                SaveFeaturesCommand?.OnCanExecuteChanged();
                GenerateReportCommand?.OnCanExecuteChanged();
                SaveReportCommand?.OnCanExecuteChanged();
                View = ViewMode.LogView;
                IsDirty = false;
            }, (_) => !WaitingForPages);

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
                                        UserLevel = MapMembershipLevelFromFile((string)feature["userLevel"]),
                                        UserIsTeammate = (bool)feature["userIsTeammate"],
                                        TagSource = new List<string>(TagSources).Contains((string)feature["tagSource"]) ? (string)feature["tagSource"] : TagSources[0],
                                        PhotoFeaturedOnPage = (bool)feature["photoFeaturedOnPage"],
                                        PhotoFeaturedOnHub = feature.ContainsKey("photoFeaturedOnHub") ? (bool)feature["photoFeaturedOnHub"] : false,
                                        PhotoLastFeaturedOnHub = feature.ContainsKey("photoLastFeaturedOnHub") ? (string)feature["photoLastFeaturedOnHub"] : "",
                                        PhotoLastFeaturedPage = feature.ContainsKey("photoLastFeaturedPage") ? (string)feature["photoLastFeaturedPage"] : "",
                                        FeatureDescription = (string)feature["featureDescription"],
                                        UserHasFeaturesOnPage = (bool)feature["userHasFeaturesOnPage"],
                                        LastFeaturedOnPage = (string)feature["lastFeaturedOnPage"],
                                        FeatureCountOnPage = CalculateFeatureCount(
                                            SelectedPage!.HubName, 
                                            (string)feature["featureCountOnPage"], 
                                            feature.ContainsKey("featureCountOnRawPage") ? (string)feature["featureCountOnRawPage"] : "0"),
                                        UserHasFeaturesOnHub = (bool)feature["userHasFeaturesOnHub"],
                                        LastFeaturedOnHub = (string)feature["lastFeaturedOnHub"],
                                        LastFeaturedPage = (string)feature["lastFeaturedPage"],
                                        FeatureCountOnHub = CalculateFeatureCount(
                                            SelectedPage!.HubName, 
                                            (string)feature["featureCountOnHub"], 
                                            feature.ContainsKey("featureCountOnRawHub") ? (string)feature["featureCountOnRawHub"] : "0"),
                                        TooSoonToFeatureUser = (bool)feature["tooSoonToFeatureUser"],
                                        TinEyeResults = new List<string>(TinEyeResults).Contains((string)feature["tinEyeResults"]) ? (string)feature["tinEyeResults"] : TinEyeResults[0],
                                        AiCheckResults = new List<string>(AiCheckResults).Contains((string)feature["aiCheckResults"]) ? (string)feature["aiCheckResults"] : AiCheckResults[0],
                                        PersonalMessage = feature.ContainsKey("personalMessage") ? (string)feature["personalMessage"] : "",
                                    };
                                    Features.Add(loadedFeature);
                                }
                                base.OnPropertyChanged(nameof(HasFeatures));
                                base.OnPropertyChanged(nameof(FeatureNavigationVisibility));
                                base.OnPropertyChanged(nameof(CanChangePage));
                                SaveFeaturesCommand?.OnCanExecuteChanged();
                                GenerateReportCommand?.OnCanExecuteChanged();
                                SaveReportCommand?.OnCanExecuteChanged();
                                lastFilename = dialog.FileName;
                                View = ViewMode.LogView;
                                IsDirty = false;
                                foreach (var feature in Features)
                                {
                                    feature.IsDirty = false;
                                    feature.OnSortKeyChange();
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
            }, (_) => !WaitingForPages);

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
            }, () => !WaitingForPages && HasFeatures);

            GenerateReportCommand = new Command(() =>
            {
                if (SelectedPage == null)
                {
                    return;
                }

                CopyTextToClipboard(GenerateLogReport(), "Generated report", "Copied the report of features to the clipboard");
            }, () => !WaitingForPages && HasFeatures);

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
            }, () => !WaitingForPages && HasFeatures);

            LaunchSettingsCommand = new Command(() =>
            {
                var panel = new SettingsDialog
                {
                    DataContext = Settings,
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
                panel.ShowDialog();
                OnPropertyChanged(nameof(CullingAppLaunch));
                (LaunchCullingAppCommand as Command)?.OnCanExecuteChanged();
                OnPropertyChanged(nameof(AiCheckAppLaunch));
                (LaunchAiCheckAppCommand as Command)?.OnCanExecuteChanged();
            });

            LaunchAboutCommand = new Command(() =>
            {
                var panel = new AboutDialog
                {
                    DataContext = new AboutViewModel(),
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
                    var possibleUserAlias = clipboardText[16..].Split('/').FirstOrDefault() ?? "";
                    if (possibleUserAlias.Length > 1)
                    {
                        feature.UserAlias = possibleUserAlias;
                    }
                }
                Features.Add(feature);
                SelectedFeature = feature;
                OnPropertyChanged(nameof(HasFeatures));
                OnPropertyChanged(nameof(FeatureNavigationVisibility));
                OnPropertyChanged(nameof(CanChangePage));
                SaveFeaturesCommand?.OnCanExecuteChanged();
                GenerateReportCommand?.OnCanExecuteChanged();
                SaveReportCommand?.OnCanExecuteChanged();
            }, () => !WaitingForPages);

            RemoveFeatureCommand = new Command(() =>
            {
                if (SelectedFeature is Feature feature)
                {
                    RemoveFeature(feature);
                }
            }, () => SelectedFeature != null);

            PastePostLinkCommand = new Command(() =>
            {
                if (SelectedFeature != null)
                {
                    var clipboardText = Clipboard.ContainsText() ? Clipboard.GetText().Trim() : "";
                    if (clipboardText.StartsWith("https://vero.co/"))
                    {
                        SelectedFeature.PostLink = clipboardText;
                        var possibleUserAlias = clipboardText[16..].Split('/').FirstOrDefault() ?? "";
                        if (possibleUserAlias.Length > 1)
                        {
                            SelectedFeature.UserAlias = possibleUserAlias;
                        }
                    }
                    else
                    {
                        SelectedFeature.PostLink = clipboardText;
                    }
                }
            });

            LoadPostCommand = new Command(() =>
            {
                if (SelectedPage != null && SelectedFeature != null && SelectedFeature.PostLink != null && SelectedFeature.PostLink.StartsWith("https://vero.co/"))
                {
                    LoadedPost = new DownloadedPostViewModel(this);
                    View = ViewMode.PostDownloaderView;
                }
            },
            () =>
            {
                return SelectedPage != null && SelectedFeature != null && SelectedFeature.PostLink != null && SelectedFeature.PostLink.StartsWith("https://vero.co/");
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

            LaunchCullingAppCommand = new Command(
                () =>
                {
                    if (!string.IsNullOrEmpty(Settings.CullingApp) && File.Exists(Settings.CullingApp))
                    {
                        Process.Start(Settings.CullingApp);
                    }
                },
                () =>
                {
                    return !string.IsNullOrEmpty(Settings.CullingApp) && File.Exists(Settings.CullingApp);
                });

            LaunchAiCheckAppCommand = new Command(
                () =>
                {
                    if (!string.IsNullOrEmpty(Settings.AiCheckApp) && File.Exists(Settings.AiCheckApp))
                    {
                        Process.Start(Settings.AiCheckApp);
                    }
                },
                () =>
                {
                    return !string.IsNullOrEmpty(Settings.AiCheckApp) && File.Exists(Settings.AiCheckApp);
                });

            CloseCurrentViewCommand = new Command(() =>
            {
                switch (View)
                {
                    case ViewMode.ScriptView:
                    case ViewMode.StatisticsView:
                    case ViewMode.PostDownloaderView:
                        View = ViewMode.LogView;
                        break;
                    case ViewMode.ImageView:
                        View = ViewMode.PostDownloaderView;
                        break;
                    case ViewMode.ImageValidationView:
                        View = ViewMode.PostDownloaderView;
                        break;
                    default:
                        View = ViewMode.LogView;
                        break;
                }
            });

            RemoveDownloadedPostFeatureCommand = new Command(() =>
            {
                if (SelectedFeature is Feature feature)
                {
                    View = ViewMode.LogView;
                    RemoveFeature(feature);
                }
            },
            () =>
            {
                return SelectedPage != null && SelectedFeature != null && (View == ViewMode.PostDownloaderView || View == ViewMode.ImageValidationView || View == ViewMode.ImageView);
            });

            NavigateToPreviousFeatureCommand = new Command(() =>
            {
                var pickedAndAllowedFeatures = Features.Where(feature => feature.IsPickedAndAllowed)
                                                       .OrderBy(feature => feature, FeatureComparer.Default)
                                                       .ToArray();
                var currentIndex = Array.IndexOf(pickedAndAllowedFeatures, SelectedFeature);
                if (currentIndex == -1)
                {
                    return;
                }
                var newIndex = (currentIndex + pickedAndAllowedFeatures.Length - 1) % pickedAndAllowedFeatures.Length;
                SelectedFeature = pickedAndAllowedFeatures[newIndex];
                SelectedFeature.OpenFeatureInVeroScriptsCommand.Execute(this);
            });

            NavigateToNextFeatureCommand = new Command(() =>
            {
                var pickedAndAllowedFeatures = Features.Where(feature => feature.IsPickedAndAllowed)
                                                       .OrderBy(feature => feature, FeatureComparer.Default)
                                                       .ToArray();
                var currentIndex = Array.IndexOf(pickedAndAllowedFeatures, SelectedFeature);
                if (currentIndex == -1)
                {
                    return;
                }
                var newIndex = (currentIndex + 1) % pickedAndAllowedFeatures.Length;
                SelectedFeature = pickedAndAllowedFeatures[newIndex];
                SelectedFeature.OpenFeatureInVeroScriptsCommand.Execute(this);
            });

            ShowStatisticsViewCommand = new Command(
                () => View = ViewMode.StatisticsView,
                () => View == ViewMode.LogView);

            PickStatisticsFolderCommand = new Command(() =>
            {
                var dialog = new OpenFolderDialog()
                {
                    Title = "Choose the folder with your logs",
                };
                if (dialog.ShowDialog() == true)
                {
                    StatisticsFolder = "";
                    StatisticsFolder = dialog.FolderName;
                }
            });

            #endregion

            #region Dirty state management

            void ItemChanged(object? sender, PropertyChangedEventArgs e)
            {
                if (sender is Feature feature)
                {
                    if (e.PropertyName == nameof(feature.IsDirty))
                    {
                        IsDirty |= feature.IsDirty;
                    }
                    else if (e.PropertyName == nameof(feature.PostLink))
                    {
                        LoadPostCommand.OnCanExecuteChanged();
                    }
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

        public void RemoveFeature(Feature feature)
        {
            if (feature == SelectedFeature)
            {
                SelectedFeature = null;
            }
            Features.Remove(feature);
            OnPropertyChanged(nameof(HasFeatures));
            OnPropertyChanged(nameof(FeatureNavigationVisibility));
            OnPropertyChanged(nameof(CanChangePage));
            SaveFeaturesCommand?.OnCanExecuteChanged();
            GenerateReportCommand?.OnCanExecuteChanged();
            SaveReportCommand?.OnCanExecuteChanged();
        }

        private string CalculateFeatureCount(string hub, string featureCount, string rawFeatureCount)
        {
            featureCount = new List<string>(FeaturedCounts).Contains(featureCount) ? featureCount : FeaturedCounts[0];
            rawFeatureCount = new List<string>(FeaturedCounts).Contains(rawFeatureCount) ? rawFeatureCount : FeaturedCounts[0];
            if (featureCount == "many" || rawFeatureCount == "many")
            {
                return "many";
            }
            if (rawFeatureCount == "0")
            {
                return featureCount;
            }
            var count = int.TryParse(featureCount, out int countValue) ? countValue : 0;
            var rawCount = int.TryParse(rawFeatureCount, out int rawCountValue) ? rawCountValue : 0;
            var total = count + rawCount;
            return hub switch
            {
                "snap" when total > 20 => "many",
                "click" when total > 75 => "many",
                _ when total > 50 => "many",
                _ => $"{total}"
            };
        }

        private string MapMembershipLevelFromFile(string userLevelFromFile)
        {
            if (Memberships.Contains(userLevelFromFile))
            {
                return userLevelFromFile;
            }
            if (OldMembershipMap.TryGetValue(userLevelFromFile, out string? value))
            {
                return value;
            }
            return Memberships[0];
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
                _ = LoadTemplates();
                _ = LoadDisallowList();
                IsDirty = false;
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error occurred: {0}", ex.Message);
                ShowErrorToast(
                    "Failed to load the page catalog",
                    "The application requires the catalog to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadPages(); });
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
                ShowErrorToast(
                    "Failed to load the page templates",
                    "The application requires the templtes to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadTemplates(); });
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

        #region Commands

        public CommandWithParameter NewFeaturesCommand { get; }

        public CommandWithParameter OpenFeaturesCommand { get; }

        public Command SaveFeaturesCommand { get; }

        public Command GenerateReportCommand { get; }

        public Command SaveReportCommand { get; }

        public ICommand LaunchSettingsCommand { get; }

        public ICommand LaunchAboutCommand { get; }

        public ICommand CopyPageTagCommand { get; }

        public Command AddFeatureCommand { get; }

        public Command RemoveFeatureCommand { get; }

        public ICommand PastePostLinkCommand { get; }

        public Command LoadPostCommand { get; }

        public ICommand CopyPageFeatureTagCommand { get; }

        public ICommand CopyRawPageFeatureTagCommand { get; }

        public ICommand CopyHubFeatureTagCommand { get; }

        public ICommand CopyRawHubFeatureTagCommand { get; }

        public ICommand CopyPersonalMessageCommand { get; }

        public ICommand SetThemeCommand { get; }

        public ICommand LaunchCullingAppCommand { get; }

        public ICommand LaunchAiCheckAppCommand { get; }

        public ICommand CloseCurrentViewCommand { get; }

        public Command RemoveDownloadedPostFeatureCommand { get; }

        public ICommand NavigateToPreviousFeatureCommand { get; }

        public ICommand NavigateToNextFeatureCommand { get; }

        public ICommand ShowStatisticsViewCommand { get; }

        public ICommand PickStatisticsFolderCommand { get; }

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
                    NewFeaturesCommand.OnCanExecuteChanged();
                    OpenFeaturesCommand.OnCanExecuteChanged();
                    SaveFeaturesCommand.OnCanExecuteChanged();
                    GenerateReportCommand.OnCanExecuteChanged();
                    SaveReportCommand.OnCanExecuteChanged();
                    AddFeatureCommand.OnCanExecuteChanged();

                }
            }
        }

        #endregion

        #region Dirty state

        private bool isDirty = false;
        public bool IsDirty
        {
            get => isDirty;
            set => Set(ref isDirty, value, [nameof(Title)]);
        }

        public string Title =>
            View == ViewMode.ScriptView
                ? $"Feature Logging{(IsDirty ? " - edited" : string.Empty)}{(string.IsNullOrEmpty(SelectedFeature?.UserName)
                    ? " - scripts"
                    : (" - scripts for: " + SelectedFeature?.UserName))}{(string.IsNullOrEmpty(SelectedFeature?.FeatureDescription)
                    ? ""
                    : " - description: " + SelectedFeature?.FeatureDescription)}"
                : View == ViewMode.PostDownloaderView || View == ViewMode.ImageValidationView || View == ViewMode.ImageView
                    ? $"Feature Logging{(IsDirty ? " - edited" : string.Empty)}{(string.IsNullOrEmpty(SelectedFeature?.UserName)
                        ? " - post viewer"
                        : (" - post viewer: " + SelectedFeature?.UserName))}{(string.IsNullOrEmpty(SelectedFeature?.FeatureDescription)
                        ? ""
                        : " - description: " + SelectedFeature?.FeatureDescription)}"
                    : View == ViewMode.StatisticsView
                        ? $"Feature Logging{(IsDirty ? " - edited" : string.Empty)} - statistics"
                        : $"Feature Logging{(IsDirty ? " - edited" : string.Empty)}";

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

        #region View management

        public enum ViewMode { LogView, ScriptView, StatisticsView, PostDownloaderView, ImageValidationView, ImageView }
        private ViewMode view = ViewMode.LogView;

        public ViewMode View
        {
            get => view;
            set
            {
                if (Set(ref view, value))
                {
                    OnPropertyChanged(nameof(LogViewVisibility));
                    OnPropertyChanged(nameof(ScriptViewVisibility));
                    OnPropertyChanged(nameof(StatisticsViewVisibility));
                    OnPropertyChanged(nameof(PostDownloaderViewVisibility));
                    OnPropertyChanged(nameof(ImageValidationViewVisibility));
                    OnPropertyChanged(nameof(ImageViewVisibility));
                    OnPropertyChanged(nameof(FeatureNavigationVisibility));
                    OnPropertyChanged(nameof(Title));
                    if (view != ViewMode.PostDownloaderView && view != ViewMode.ImageValidationView && view != ViewMode.ImageView)
                    {
                        LoadedPost = null;
                    }
                    if (view != ViewMode.StatisticsView)
                    {
                        StatisticsFolder = "";
                    }
                    RemoveDownloadedPostFeatureCommand.OnCanExecuteChanged();
                }
            }
        }

        public Visibility LogViewVisibility => view == ViewMode.LogView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility ScriptViewVisibility => view == ViewMode.ScriptView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility StatisticsViewVisibility => view == ViewMode.StatisticsView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility PostDownloaderViewVisibility => view == ViewMode.PostDownloaderView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility ImageValidationViewVisibility => view == ViewMode.ImageValidationView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility ImageViewVisibility => view == ViewMode.ImageView ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region External app menu

        public static string CullingAppLaunch => "Launch " + (!string.IsNullOrEmpty(Settings.CullingApp) ? Settings.CullingAppName : "Culling app") + "...";

        public static string AiCheckAppLaunch => "Launch " + (!string.IsNullOrEmpty(Settings.AiCheckApp) ? Settings.AiCheckAppName : "AI Check tool") + "...";

        #endregion

        #region Pages

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
                if (Set(ref page, value, [nameof(StaffLevels)]))
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
            private set => Set(ref pageValidation, value);
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

        #region Features

        public ObservableCollection<Feature> Features { get; } = [];

        private Feature? selectedFeature = null;

        public Feature? SelectedFeature
        {
            get => selectedFeature;
            set
            {
                var oldSelectedFeature = selectedFeature;
                if (Set(ref selectedFeature, value))
                {
                    Feature = SelectedFeature?.Id ?? string.Empty;
                    OnPropertyChanged(nameof(HasSelectedFeature));
                    OnPropertyChanged(nameof(SelectedFeatureVisibility));
                    OnPropertyChanged(nameof(Title));
                    RemoveFeatureCommand.OnCanExecuteChanged();
                    LoadPostCommand.OnCanExecuteChanged();
                    if (oldSelectedFeature != null)
                    {
                        oldSelectedFeature.PropertyChanged -= OnSelectedFeaturePropertyChanged;
                    }
                    if (selectedFeature != null)
                    {
                        selectedFeature.PropertyChanged += OnSelectedFeaturePropertyChanged;
                    }
                }
            }
        }

        private void OnSelectedFeaturePropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            switch (e.PropertyName)
            {
                case "SortKey":
                    MainWindow?.ResortList();
                    break;
            }
        }

        public Visibility SelectedFeatureVisibility => SelectedPage != null && SelectedFeature != null ? Visibility.Visible : Visibility.Collapsed;

        public Visibility FeatureNavigationVisibility => Features.Where(feature => feature.IsPickedAndAllowed).Count() > 1 && View == ViewMode.ScriptView ? Visibility.Visible : Visibility.Collapsed;

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

        public static bool TrySetClipboardText(string text)
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

        #region Statistics Charts

        public class StatisticsPage(string id, string display)
        {
            public string Id { get; } = id;

            public string Display { get; } = display;
        }

        public ObservableCollection<StatisticsPage> StatisticsPages { get; } = [];

        private StatisticsPage? selectedStatisticsPage = null;
        public StatisticsPage? SelectedStatisticsPage
        {
            get => selectedStatisticsPage;
            set
            {
                if (Set(ref selectedStatisticsPage, value))
                {
                    if (selectedStatisticsPage != null)
                    {
                        var selectedLogs = loggingFiles.Where(loggingFile =>
                        {
                            if (selectedStatisticsPage.Id == "all")
                            {
                                return true;
                            }
                            if (!selectedStatisticsPage.Id.Contains(':'))
                            {
                                return loggingFile.Page.StartsWith(selectedStatisticsPage.Id + ":");
                            }
                            return loggingFile.Page.Equals(selectedStatisticsPage.Id);
                        });

                        PickedFeatureChart = new ChartData("Picked", "Total picks", CalculatePickedFeatureData(selectedLogs));
                        FirstFeatureChart = new ChartData("First feature", "First time user is featured", CalculateFirstFeatureData(selectedLogs));
                        UserLevelChart = new ChartData("User level", "Membership of user before feature", CalculateUserLevelData(selectedLogs));
                        PhotoFeaturedChart = new ChartData("Photo featured", "Photo feature on different page on hub", CalculatePhotoFeaturedData(selectedLogs));
                        PageFeatureCountChart = new ChartData("Previous page features", "Number of features the user has on page", CalculatePageFeatureCountData(selectedLogs));
                        HubFeatureCountChart = new ChartData("Previous hub features", "Number of features the user has on entire hub", CalculateHubFeatureCountData(selectedLogs));
                        ChartVisibility = Visibility.Visible;
                    }
                    else
                    {
                        ChartVisibility = Visibility.Collapsed;
                        PickedFeatureChart = null;
                        FirstFeatureChart = null;
                        UserLevelChart = null;
                        PhotoFeaturedChart = null;
                        PageFeatureCountChart = null;
                        HubFeatureCountChart = null;
                    }
                }
            }
        }

        private static SeriesCollection CalculatePickedFeatureData(IEnumerable<LoggingFile> loggingFiles)
        {
            var collection = new SeriesCollection();
            var value = loggingFiles.Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed).Count());
            collection.Add(new PieSeries
            {
                Title = "Picked",
                Values = new ChartValues<ObservableValue> { new(value) },
                DataLabels = true
            });
            return collection;
        }

        private static SeriesCollection CalculateFirstFeatureData(IEnumerable<LoggingFile> loggingFiles)
        {
            var collection = new SeriesCollection();
            var firstFeatureValue = loggingFiles.Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && !feature.UserHasFeaturesOnPage).Count());
            var notFirstFeatureValue = loggingFiles.Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && feature.UserHasFeaturesOnPage).Count());
            collection.Add(new PieSeries
            {
                Title = "First on page",
                Values = new ChartValues<ObservableValue> { new(firstFeatureValue) },
                DataLabels = true
            });
            collection.Add(new PieSeries
            {
                Title = "Not first",
                Values = new ChartValues<ObservableValue> { new(notFirstFeatureValue) },
                DataLabels = true
            });
            return collection;
        }

        private static SeriesCollection CalculateUserLevelData(IEnumerable<LoggingFile> loggingFiles)
        {
            var collection = new SeriesCollection();
            foreach (var level in SnapMemberships)
            {
                var levelCountValue = loggingFiles.Where(loggingFile => loggingFile.Page.StartsWith("snap:"))
                                                  .Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && feature.UserLevel == level).Count());
                if (levelCountValue != 0)
                {
                    collection.Add(new PieSeries
                    {
                        Title = "Snap " + level,
                        Values = new ChartValues<ObservableValue> { new(levelCountValue) },
                        DataLabels = true
                    });
                }
            }
            foreach (var level in ClickMemberships)
            {
                var levelCountValue = loggingFiles.Where(loggingFile => loggingFile.Page.StartsWith("click:"))
                                                  .Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && feature.UserLevel == level).Count());
                if (levelCountValue != 0)
                {
                    collection.Add(new PieSeries
                    {
                        Title = "Click " + level,
                        Values = new ChartValues<ObservableValue> { new(levelCountValue) },
                        DataLabels = true
                    });
                }
            }
            foreach (var level in OtherMemberships)
            {
                var levelCountValue = loggingFiles.Where(loggingFile => loggingFile.Page.StartsWith("other:"))
                                                  .Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && feature.UserLevel == level).Count());
                if (levelCountValue != 0)
                {
                    collection.Add(new PieSeries
                    {
                        Title = "Other " + level,
                        Values = new ChartValues<ObservableValue> { new(levelCountValue) },
                        DataLabels = true
                    });
                }
            }
            return collection;
        }

        private static SeriesCollection CalculatePhotoFeaturedData(IEnumerable<LoggingFile> loggingFiles)
        {
            var collection = new SeriesCollection();
            var photoFeaturedOnHubValue = loggingFiles.Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && !feature.PhotoFeaturedOnHub).Count());
            var photoNotFeaturedOnHubValue = loggingFiles.Sum(loggingFile => loggingFile.Features.Where(feature => feature.IsPickedAndAllowed && feature.PhotoFeaturedOnHub).Count());
            collection.Add(new PieSeries
            {
                Title = "Featured on hub",
                Values = new ChartValues<ObservableValue> { new(photoFeaturedOnHubValue) },
                DataLabels = true
            });
            collection.Add(new PieSeries
            {
                Title = "Not featured",
                Values = new ChartValues<ObservableValue> { new(photoNotFeaturedOnHubValue) },
                DataLabels = true
            });
            return collection;
        }

        private static int GetPageFeatureCount(Feature feature)
        {
            if (feature.UserHasFeaturesOnPage && feature.FeatureCountOnPage == "many")
            {
                return int.MaxValue;
            }
            return feature.UserHasFeaturesOnPage ? int.Parse(feature.FeatureCountOnPage) : 0;
        }

        private static int GetHubFeatureCount(Feature feature)
        {
            if (feature.UserHasFeaturesOnHub && feature.FeatureCountOnHub == "many")
            {
                return int.MaxValue;
            }
            return feature.UserHasFeaturesOnHub ? int.Parse(feature.FeatureCountOnHub) : 0;
        }

        private static int BinFeatureCount(int featureCount, int binSize)
        {
            if (featureCount == int.MaxValue || featureCount == 0)
            {
                return featureCount;
            }
            return ((featureCount - 1) / binSize) * binSize + 1;
        }

        private static SeriesCollection CalculatePageFeatureCountData(IEnumerable<LoggingFile> loggingFiles)
        {
            var buckets = new Dictionary<int, int>();
            foreach (var loggingFile in loggingFiles)
            {
                foreach (var feature in loggingFile.Features)
                {
                    if (feature.IsPickedAndAllowed)
                    {
                        var count = BinFeatureCount(GetPageFeatureCount(feature), 5);
                        if (!buckets.TryGetValue(count, out int value))
                        {
                            value = 0;
                        }
                        buckets[count] = value + 1;
                    }
                }
            }

            var seriesCollection = new SeriesCollection();
            foreach (var key in buckets.Keys.Order())
            {
                seriesCollection.Add(new PieSeries
                {
                    Title = (key == int.MaxValue) ? "many features" : (key == 0) ? "no features" : $"{key}-{key + 4} features",
                    Values = new ChartValues<ObservableValue> { new(buckets[key]) },
                    DataLabels = true
                });
            }

            return seriesCollection;
        }

        private static SeriesCollection CalculateHubFeatureCountData(IEnumerable<LoggingFile> loggingFiles)
        {
            var buckets = new Dictionary<int, int>();
            foreach (var loggingFile in loggingFiles)
            {
                foreach (var feature in loggingFile.Features)
                {
                    if (feature.IsPickedAndAllowed)
                    {
                        var count = BinFeatureCount(GetHubFeatureCount(feature), 5);
                        if (!buckets.TryGetValue(count, out int value))
                        {
                            value = 0;
                        }
                        buckets[count] = value + 1;
                    }
                }
            }

            var seriesCollection = new SeriesCollection();
            foreach (var key in buckets.Keys.Order())
            {
                seriesCollection.Add(new PieSeries
                {
                    Title = (key == int.MaxValue) ? "many features" : (key == 0) ? "no features" : $"{key}-{key + 4} features",
                    Values = new ChartValues<ObservableValue> { new(buckets[key]) },
                    DataLabels = true
                });
            }

            return seriesCollection;
        }

        private readonly List<LoggingFile> loggingFiles = [];
        private string statisticsFolder = "";
        public string StatisticsFolder
        {
            get => statisticsFolder;
            set
            {
                if (Set(ref statisticsFolder, value))
                {
                    if (Directory.Exists(statisticsFolder))
                    {
                        ChartVisibility = Visibility.Collapsed;
                        PickedFeatureChart = null;
                        FirstFeatureChart = null;
                        UserLevelChart = null;
                        PhotoFeaturedChart = null;
                        PageFeatureCountChart = null;
                        HubFeatureCountChart = null;

                        var pages = new Dictionary<string, bool>();
                        var preSortedPages = new List<StatisticsPage>
                        {
                            new("all", "all pages")
                        };
                        pages["all"] = true;
                        Mouse.OverrideCursor = Cursors.Wait;
                        loggingFiles.Clear();
                        var logFiles = Directory.GetFiles(statisticsFolder, "*.json");
                        foreach (var fileName in logFiles)
                        {
                            try
                            {
                                var file = LoggingFile.FromJson(File.ReadAllText(fileName));
                                if (file != null)
                                {
                                    loggingFiles.Add(file);
                                    var page = file.Page.ToLower().Trim();
                                    var hub = page.Split(":").First() ?? "";
                                    if (!pages.ContainsKey(hub))
                                    {
                                        preSortedPages.Add(new StatisticsPage(hub, $"{hub} hub"));
                                        pages[hub] = true;
                                    }
                                    if (!pages.ContainsKey(page))
                                    {
                                        preSortedPages.Add(new StatisticsPage(page, page.Replace(":", " hub, page ")));
                                        pages[page] = true;
                                    }
                                }
                            }
                            catch
                            {
                                // Do nothing, invalid file...
                            }
                        }
                        SelectedStatisticsPage = null;
                        StatisticsPages.Clear();
                        preSortedPages.Sort(StatisticsPageComparer.Default);
                        foreach (var page in preSortedPages)
                        {
                            StatisticsPages.Add(page);
                        }
                        SelectedStatisticsPage = StatisticsPages.FirstOrDefault();
                        Mouse.OverrideCursor = null;
                    }
                    else
                    {
                        StatisticsPages.Clear();
                        ChartVisibility = Visibility.Collapsed;
                        PickedFeatureChart = null;
                        FirstFeatureChart = null;
                        UserLevelChart = null;
                        PhotoFeaturedChart = null;
                        PageFeatureCountChart = null;
                        HubFeatureCountChart = null;
                    }
                }
            }
        }

        private Visibility chartVisibility = Visibility.Collapsed;
        public Visibility ChartVisibility
        {
            get => chartVisibility;
            set => Set(ref chartVisibility, value);
        }

        private ChartData? pickedFeatureChart = null;
        public ChartData? PickedFeatureChart
        {
            get => pickedFeatureChart;
            set => Set(ref pickedFeatureChart, value);
        }

        private ChartData? firstFeatureChart = null;
        public ChartData? FirstFeatureChart
        {
            get => firstFeatureChart;
            set => Set(ref firstFeatureChart, value);
        }

        private ChartData? userLevelChart = null;
        public ChartData? UserLevelChart
        {
            get => userLevelChart;
            set => Set(ref userLevelChart, value);
        }

        private ChartData? photoFeaturedChart = null;
        public ChartData? PhotoFeaturedChart
        {
            get => photoFeaturedChart;
            set => Set(ref photoFeaturedChart, value);
        }

        private ChartData? pageFeatureCountChart = null;
        public ChartData? PageFeatureCountChart
        {
            get => pageFeatureCountChart;
            set => Set(ref pageFeatureCountChart, value);
        }

        private ChartData? hubFeatureCountChart = null;
        public ChartData? HubFeatureCountChart
        {
            get => hubFeatureCountChart;
            set => Set(ref hubFeatureCountChart, value);
        }

        #endregion

        public MainWindow? MainWindow { get; internal set; }

        internal void ShowToast(string title, string? message, NotificationType type, TimeSpan? expirationTime = null)
        {
            notificationManager.Show(
                title,
                message,
                type: type,
                areaName: "WindowArea",
                expirationTime: expirationTime);
        }

        internal async void ShowErrorToast(string title, string? message, NotificationType type, Action action)
        {
            int sleepTime = 0;
            int MaxSleepTime = 1000 * 60 * 60;
            int SleepStep = 500;

            while (sleepTime < MaxSleepTime)
            {
                if (MainWindow != null && MainWindow.IsVisible)
                {
                    var wasClicked = false;
                    notificationManager.Show(
                        title,
                        message,
                        type,
                        areaName: "WindowArea",
                        onClick: () =>
                        {
                            wasClicked = true;
                            action();
                        },
                        ShowXbtn: true,
                        onClose: () =>
                        {
                            if (!wasClicked)
                            {
                                MainWindow?.Close();
                            }
                        },
                        expirationTime: TimeSpan.MaxValue);
                    break;
                }
                sleepTime += SleepStep;
                await Task.Delay(SleepStep);
            }
        }

        internal void TriggerTinEyeSource()
        {
            OnPropertyChanged(nameof(TinEyeSource));
        }
    }

    public class StatisticsPageComparer : IComparer<MainViewModel.StatisticsPage>
    {
        public int Compare(MainViewModel.StatisticsPage? x, MainViewModel.StatisticsPage? y)
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

            // Use pre-calculated sort key.
            return string.Compare(x.Display, y.Display);
        }

        public readonly static StatisticsPageComparer Default = new();
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

            // Use pre-calculated sort key.
            return string.Compare(x.SortKey, y.SortKey);
        }

        public readonly static FeatureComparer Default = new();

        public static string CreateSortingKey(Feature feature)
        {
            var key = "";

            if (feature == null)
            {
                return key;
            }
            if (string.IsNullOrEmpty(feature.UserName))
            {
                return "ZZZ|" + feature.UserAlias;
            }

            // Handle photo featured on page
            key += (feature.PhotoFeaturedOnPage ? "Z|" : "A|");

            // Handle tin eye results
            key += (feature.TinEyeResults == "matches found" ? "Z|" : "A|");

            // Handle ai check results
            key += (feature.AiCheckResults == "ai" ? "Z|" : "A|");

            // Handle too soon to feature
            key += (feature.TooSoonToFeatureUser ? "Z|" : "A|");

            // Handle picked
            key += (feature.IsPicked ? "A|" : "Z|");

            return key + feature.UserName;
        }
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
            EditPersonalMessageCommand = new CommandWithParameter((parameter) =>
            {
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
            PickFeatureCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is MainViewModel vm)
                {
                    IsPicked = !IsPicked;
                }
            });
            DeleteFeatureCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is MainViewModel vm)
                {
                    vm.RemoveFeature(this);
                }
            });
            OpenFeatureInVeroScriptsCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is MainViewModel vm && vm.SelectedPage != null)
                {
                    vm.SelectedFeature = this;
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
                                ["staffLevel"] = vm.StaffLevel,
                                ["userName"] = UserName,
                                ["userAlias"] = UserAlias,
                                ["userLevel"] = UserLevel,
                                ["tagSource"] = TagSource,
                                ["firstFeature"] = !UserHasFeaturesOnPage
                            };
                            bool GetFeatureCount(string featureCountString, out int featureCount)
                            {
                                if (featureCountString == "many")
                                {
                                    featureCount = 99999;
                                    return true;
                                }
                                return int.TryParse(featureCountString, out featureCount);
                            }
                            if (vm.SelectedPage.HubName == "click")
                            {
                                if (GetFeatureCount(FeatureCountOnHub, out int featuresOnHub))
                                {
                                    featureDictionary["newLevel"] = (featuresOnHub + 1) switch
                                    {
                                        5 => "Click Member",
                                        15 => "Click Bronze Member",
                                        30 => "Click Silver Member",
                                        50 => "Click Gold Member",
                                        75 => "Click Platinum Member",
                                        _ => "",
                                    };
                                    featureDictionary["userLevel"] = (featuresOnHub + 1) switch
                                    {
                                        5 => "Click Member",
                                        15 => "Click Bronze Member",
                                        30 => "Click Silver Member",
                                        50 => "Click Gold Member",
                                        75 => "Click Platinum Member",
                                        _ => featureDictionary["userLevel"],
                                    };
                                }
                                else
                                {
                                    featureDictionary["newLevel"] = "";
                                }
                            }
                            else if (vm.SelectedPage.HubName == "snap")
                            {
                                if (GetFeatureCount(FeatureCountOnHub, out int featuresOnHub))
                                {
                                    featureDictionary["newLevel"] = (featuresOnHub + 1) switch
                                    {
                                        5 => "Snap Member (feature comment)",
                                        15 => "Snap VIP Member (feature comment)",
                                        _ => "",
                                    };
                                    featureDictionary["userLevel"] = (featuresOnHub + 1) switch
                                    {
                                        5 => "Snap Member",
                                        15 => "Snap VIP Member",
                                        _ => featureDictionary["userLevel"],
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

                        // TODO andydragon : eventually, remove this and just pass the script...

                        // Launch from application deployment manifest on web.
                        StoreFeatureInShared();
                        vm.View = MainViewModel.ViewMode.ScriptView;
                        vm.ScriptViewModel.PopulateScriptFromFeatureFile();
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
            get => IsPicked && IsAllowed;
        }

        [JsonIgnore]
        public bool IsAllowed
        {
            get => !TooSoonToFeatureUser && !PhotoFeaturedOnPage && TinEyeResults != "matches found" && AiCheckResults != "ai";
        }

        [JsonIgnore]
        public string SortKey
        {
            get => FeatureComparer.CreateSortingKey(this);
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
            set => SetWithDirtyCallback(ref isPicked, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(IsAllowed), nameof(SortKey)]);
        }

        private string postLink = "";
        [JsonProperty(PropertyName = "postLink")]
        public string PostLink
        {
            get => postLink;
            set => SetWithDirtyCallback(ref postLink, value, () => IsDirty = true, [nameof(PostLinkValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult PostLinkValidation => Validation.ValidateValueNotEmpty(postLink);

        private string userName = "";
        [JsonProperty(PropertyName = "userName")]
        public string UserName
        {
            get => userName;
            set => SetWithDirtyCallback(ref userName, value, () => IsDirty = true, [nameof(UserNameValidation), nameof(SortKey), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult UserNameValidation => Validation.ValidateValueNotEmptyAndContainsNoNewlines(userName);

        private string userAlias = "";
        [JsonProperty(PropertyName = "userAlias")]
        public string UserAlias
        {
            get => userAlias;
            set => SetWithDirtyCallback(ref userAlias, value, () => IsDirty = true, [nameof(UserAliasValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult UserAliasValidation => Validation.ValidateUserName(userAlias);

        private string userLevel = "None";
        [JsonProperty(PropertyName = "userLevel")]
        public string UserLevel
        {
            get => userLevel;
            set => SetWithDirtyCallback(ref userLevel, value, () => IsDirty = true, [nameof(UserLevelValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
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
            set => SetWithDirtyCallback(ref photoFeaturedOnPage, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(IsAllowed), nameof(SortKey)]);
        }

        private bool photoFeaturedOnHub = false;
        [JsonProperty(PropertyName = "photoFeaturedOnHub")]
        public bool PhotoFeaturedOnHub
        {
            get => photoFeaturedOnHub;
            set => SetWithDirtyCallback(ref photoFeaturedOnHub, value, () => IsDirty = true, [nameof(SortKey)]);
        }

        private string photoLastFeaturedOnHub = "";
        [JsonProperty(PropertyName = "photoLastFeaturedOnHub")]
        public string PhotoLastFeaturedOnHub
        {
            get => photoLastFeaturedOnHub;
            set => SetWithDirtyCallback(ref photoLastFeaturedOnHub, value, () => IsDirty = true, [nameof(PhotoLastFeaturedOnHubValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult PhotoLastFeaturedOnHubValidation => Validation.ValidateValueNotEmpty(photoLastFeaturedOnHub);

        private string photoLastFeaturedPage = "";
        [JsonProperty(PropertyName = "photoLastFeaturedPage")]
        public string PhotoLastFeaturedPage
        {
            get => photoLastFeaturedPage;
            set => SetWithDirtyCallback(ref photoLastFeaturedPage, value, () => IsDirty = true, [nameof(PhotoLastFeaturedPageValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult PhotoLastFeaturedPageValidation => Validation.ValidateValueNotEmpty(photoLastFeaturedPage);

        private string featureDescription = "";
        [JsonProperty(PropertyName = "featureDescription")]
        public string FeatureDescription
        {
            get => featureDescription;
            set => SetWithDirtyCallback(ref featureDescription, value, () => IsDirty = true);
        }

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
            set => SetWithDirtyCallback(ref lastFeaturedOnPage, value, () => IsDirty = true, [nameof(LastFeaturedOnPageValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
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
            set => SetWithDirtyCallback(ref lastFeaturedOnHub, value, () => IsDirty = true, [nameof(LastFeaturedOnHubValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedOnHubValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnHub);

        private string lastFeaturedPage = "";
        [JsonProperty(PropertyName = "lastFeaturedPage")]
        public string LastFeaturedPage
        {
            get => lastFeaturedPage;
            set => SetWithDirtyCallback(ref lastFeaturedPage, value, () => IsDirty = true, [nameof(LastFeaturedPageValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
        }
        [JsonIgnore]
        public ValidationResult LastFeaturedPageValidation => TooSoonToFeatureUser ? new ValidationResult(true) : Validation.ValidateValueNotEmpty(lastFeaturedPage);

        private string featureCountOnHub = "many";
        [JsonProperty(PropertyName = "featureCountOnHub")]
        public string FeatureCountOnHub
        {
            get => featureCountOnHub;
            set => SetWithDirtyCallback(ref featureCountOnHub, value, () => IsDirty = true);
        }

        private bool tooSoonToFeatureUser = false;
        [JsonProperty(PropertyName = "tooSoonToFeatureUser")]
        public bool TooSoonToFeatureUser
        {
            get => tooSoonToFeatureUser;
            set => SetWithDirtyCallback(ref tooSoonToFeatureUser, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(IsAllowed), nameof(SortKey), nameof(LastFeaturedPageValidation)]);
        }

        private string tinEyeResults = "0 matches";
        [JsonProperty(PropertyName = "tinEyeResults")]
        public string TinEyeResults
        {
            get => tinEyeResults;
            set => SetWithDirtyCallback(ref tinEyeResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(IsAllowed), nameof(SortKey)]);
        }

        private string aiCheckResults = "human";
        [JsonProperty(PropertyName = "aiCheckResults")]
        public string AiCheckResults
        {
            get => aiCheckResults;
            set => SetWithDirtyCallback(ref aiCheckResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(IsAllowed), nameof(SortKey)]);
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

        public bool HasValidationErrors
        {
            get =>
                !PostLinkValidation.Valid ||
                !UserNameValidation.Valid ||
                !UserAliasValidation.Valid ||
                !UserLevelValidation.Valid ||
                (PhotoFeaturedOnPage && !PhotoLastFeaturedPageValidation.Valid) ||
                (PhotoFeaturedOnHub && !PhotoLastFeaturedOnHubValidation.Valid) ||
                (UserHasFeaturesOnPage && !LastFeaturedOnPageValidation.Valid) ||
                (UserHasFeaturesOnHub && (!LastFeaturedOnHubValidation.Valid || !LastFeaturedPageValidation.Valid));
        }

        [JsonIgnore]

        public string ValidationErrorSummary
        {
            get
            {
                List<string> validationErrors = [];
                AddValidationError(validationErrors, PostLinkValidation, "Post link");
                AddValidationError(validationErrors, UserNameValidation, "User name");
                AddValidationError(validationErrors, UserAliasValidation, "User alias");
                AddValidationError(validationErrors, UserLevelValidation, "User level");
                if (PhotoFeaturedOnPage)
                {
                    AddValidationError(validationErrors, PhotoLastFeaturedPageValidation, "Photo last featured on page");
                }
                if (PhotoFeaturedOnHub)
                {
                    AddValidationError(validationErrors, PhotoLastFeaturedOnHubValidation, "Photo last featured on hub");
                }
                if (UserHasFeaturesOnPage)
                {
                    AddValidationError(validationErrors, LastFeaturedOnPageValidation, "User last featured on page");
                }
                if (UserHasFeaturesOnHub)
                {
                    AddValidationError(validationErrors, LastFeaturedOnHubValidation, "User last featured on hub");
                    AddValidationError(validationErrors, LastFeaturedPageValidation, "User last featured page");
                }
                return string.Join(",", validationErrors);
            }
        }

        private static void AddValidationError(List<string> validationErrors, ValidationResult result, string validation)
        {
            if (!result.Valid)
            {
                validationErrors.Add(validation + ": " + (result.Message ?? result.Error ?? "unknown validation error"));
            }
        }

        [JsonIgnore]
        public ICommand PickFeatureCommand { get; }

        [JsonIgnore]
        public ICommand DeleteFeatureCommand { get; }

        [JsonIgnore]
        public ICommand OpenFeatureInVeroScriptsCommand { get; }

        [JsonIgnore]
        public ICommand EditPersonalMessageCommand { get; }

        internal void TriggerThemeChanged()
        {
            OnPropertyChanged(nameof(PostLinkValidation));
            OnPropertyChanged(nameof(UserAliasValidation));
            OnPropertyChanged(nameof(UserNameValidation));
            OnPropertyChanged(nameof(UserLevelValidation));
            OnPropertyChanged(nameof(PhotoLastFeaturedOnHubValidation));
            OnPropertyChanged(nameof(PhotoLastFeaturedPageValidation));
            OnPropertyChanged(nameof(LastFeaturedOnPageValidation));
            OnPropertyChanged(nameof(LastFeaturedOnHubValidation));
            OnPropertyChanged(nameof(LastFeaturedPageValidation));
        }

        internal void OnSortKeyChange()
        {
            OnPropertyChanged(nameof(SortKey));
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
        public bool IncludeHash
        {
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

        private string cullingApp = UserSettings.Get(
            nameof(CullingApp),
            string.Empty);
        public string CullingApp
        {
            get => cullingApp;
            set
            {
                if (Set(ref cullingApp, value))
                {
                    UserSettings.Store(nameof(CullingApp), value);
                }
            }
        }

        private string cullingAppName = UserSettings.Get(
            nameof(CullingAppName),
            string.Empty);
        public string CullingAppName
        {
            get => cullingAppName;
            set
            {
                if (Set(ref cullingAppName, value))
                {
                    UserSettings.Store(nameof(CullingAppName), value);
                }
            }
        }

        private string aiCheckApp = UserSettings.Get(
            nameof(AiCheckApp),
            string.Empty);
        public string AiCheckApp
        {
            get => aiCheckApp;
            set
            {
                if (Set(ref aiCheckApp, value))
                {
                    UserSettings.Store(nameof(AiCheckApp), value);
                }
            }
        }

        private string aiCheckAppName = UserSettings.Get(
            nameof(AiCheckAppName),
            string.Empty);
        public string AiCheckAppName
        {
            get => aiCheckAppName;
            set
            {
                if (Set(ref aiCheckAppName, value))
                {
                    UserSettings.Store(nameof(AiCheckAppName), value);
                }
            }
        }
    }

    public partial class LoggingFile
    {
        [JsonProperty("features", NullValueHandling = NullValueHandling.Ignore)]
        public Feature[] Features { get; set; } = [];

        [JsonProperty("page", NullValueHandling = NullValueHandling.Ignore)]
        public string Page { get; set; } = "";
    }

    public partial class LoggingFile
    {
        public static LoggingFile? FromJson(string json) => JsonConvert.DeserializeObject<LoggingFile>(json);
    }
}
