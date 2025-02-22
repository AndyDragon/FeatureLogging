﻿using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.Net.Http.Headers;
using System.Text;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Maui.Storage;
using FeatureLogging.Base;
using FeatureLogging.Models;
using FeatureLogging.Views;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace FeatureLogging.ViewModels;

public class MainViewModel : NotifyPropertyChanged
{
    private readonly HttpClient httpClient = new();

    public MainViewModel()
    {
        ScriptViewModel = new ScriptsViewModel(this);
        SettingsViewModel = new SettingsViewModel();

        DeviceDisplay.Current.MainDisplayInfoChanged += (_, _) =>
        {
            OnPropertyChanged(nameof(ScreenWidth));
        };

        _ = LoadPages();
    }

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
                    loadedPages.AddRange(from hubPair in pagesCatalog.Hubs from hubPage in hubPair.Value select new LoadedPage(hubPair.Key, hubPage));
                }
                
                LoadedPages.Clear();
                foreach (var loadedPage in loadedPages.OrderBy(loadedPage => loadedPage, LoadedPageComparer.Default))
                {
                    LoadedPages.Add(loadedPage);
                }
                _ = Toast.Make($"Loaded {LoadedPages.Count} pages from the server").Show();
            }
            SelectedPage = LoadedPages.FirstOrDefault(loadedPage => loadedPage.Id == Page);
            WaitingForPages = false;
            Debugger.Log(100, "Info", "No longer waiting for pages...");
            
            await LoadTemplates();
            await LoadDisallowAndCautionLists();

            IsDirty = false;
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error occurred loading page catalog (will retry): {0}", ex.Message);
            await Toast.Make($"Failed to load the page catalog: {ex.Message}", ToastDuration.Long).Show();
            _ = LoadPages();
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
                ScriptViewModel.TemplatesCatalog = JsonConvert.DeserializeObject<TemplatesCatalog>(content) ?? new TemplatesCatalog();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Error occurred loading the template catalog (will retry): {0}", ex.Message);
            await Toast.Make($"Failed to load the page templates: {ex.Message}", ToastDuration.Long).Show();
            _ = LoadTemplates();
        }
    }

    private async Task LoadDisallowAndCautionLists()
    {
        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var disallowListsUri = new Uri("https://vero.andydragon.com/static/data/disallowlists.json");
            var disallowListsContent = await httpClient.GetStringAsync(disallowListsUri);
            if (!string.IsNullOrEmpty(disallowListsContent))
            {
                Validation.DisallowLists = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(disallowListsContent) ?? [];
            }
            var cautionListsUri = new Uri("https://vero.andydragon.com/static/data/cautionlists.json");
            var cautionListsContent = await httpClient.GetStringAsync(cautionListsUri);
            if (!string.IsNullOrEmpty(cautionListsContent))
            {
                Validation.CautionLists = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(cautionListsContent) ?? [];
            }
        }
        catch (Exception ex)
        {
            // Do nothing, not vital
            Console.WriteLine("Error occurred loading the disallow lists (ignoring): {0}", ex.Message);
        }
    }

    #endregion

    #region Commands

    public SimpleCommand NewFeaturesCommand => new(() =>
    {
        _ = NewFeaturesAsync();
    }, () => !WaitingForPages);
        
    private async Task NewFeaturesAsync(bool ignoreDirty = false)
    {
        if (IsDirty && !ignoreDirty)
        {
            await HandleDirtyActionAsync("creating a new log", _ => NewFeaturesAsync(true));
            return;
        }

        SelectedFeature = null;
        foreach (var feature in Features)
        {
            feature.PropertyChanged -= OnFeaturePropertyChanged;
        }
        Features.Clear();
        OnPropertyChanged(nameof(HasFeatures));
        OnPropertyChanged(nameof(FeatureNavigationAllowed));
        OnPropertyChanged(nameof(CanChangePage));
    }

    public SimpleCommand OpenFeaturesCommand => new(() =>
    {
        _ = OpenFeaturesAsync();
    }, () => !WaitingForPages);
        
    private async Task OpenFeaturesAsync(bool ignoreDirty = false)
    {
        if (IsDirty && !ignoreDirty)
        {
            await HandleDirtyActionAsync("opening a different log", _ => OpenFeaturesAsync(true));
            return;
        }

        var customFileType = new FilePickerFileType(
            new Dictionary<DevicePlatform, IEnumerable<string>>
            {
                { DevicePlatform.iOS, ["public.json"] }, // UTType values
                { DevicePlatform.Android, ["application/json"] }, // MIME type
                { DevicePlatform.WinUI, [".json"] }, // file extension
                { DevicePlatform.Tizen, ["*/*"] },
                { DevicePlatform.macOS, ["public.json"] }, // UTType values
            });

        PickOptions options = new()
        {
            PickerTitle = "Please select a log file",
            FileTypes = customFileType,
        };

        try
        {
            var result = await FilePicker.Default.PickAsync(options);
            if (result != null)
            {
                SelectedFeature = null;
                var file = JsonConvert.DeserializeObject<Dictionary<string, dynamic>>(await File.ReadAllTextAsync(result.FullPath));
                if (file != null)
                {
                    var pageId = file["page"];
                    var foundPage = LoadedPages.FirstOrDefault(loadedPage => loadedPage.Id == pageId);
                    if (foundPage != null)
                    {
                        // Force the page to update.
                        selectedPage = null;
                        SelectedPage = foundPage;
                        foreach (var feature in Features)
                        {
                            feature.PropertyChanged -= OnFeaturePropertyChanged;
                        }
                        Features.Clear();
                        foreach (var fileFeature in file["features"])
                        {
                            var loadedFeature = new Feature(SelectedPage.HubName)
                            {
                                IsPicked = (bool)fileFeature["isPicked"],
                                PostLink = (string)fileFeature["postLink"],
                                UserName = (string)fileFeature["userName"],
                                UserAlias = (string)fileFeature["userAlias"],
                                UserLevel = MapMembershipLevelFromFile((string)fileFeature["userLevel"]),
                                UserIsTeammate = (bool)fileFeature["userIsTeammate"],
                                TagSource = new List<string>(TagSources).Contains((string)fileFeature["tagSource"]) ? (string)fileFeature["tagSource"] : TagSources[0],
                                PhotoFeaturedOnPage = (bool)fileFeature["photoFeaturedOnPage"],
                                PhotoFeaturedOnHub = fileFeature.ContainsKey("photoFeaturedOnHub") && (bool)fileFeature["photoFeaturedOnHub"],
                                PhotoLastFeaturedOnHub = fileFeature.ContainsKey("photoLastFeaturedOnHub") ? (string)fileFeature["photoLastFeaturedOnHub"] : "",
                                PhotoLastFeaturedPage = fileFeature.ContainsKey("photoLastFeaturedPage") ? (string)fileFeature["photoLastFeaturedPage"] : "",
                                FeatureDescription = (string)fileFeature["featureDescription"],
                                UserHasFeaturesOnPage = (bool)fileFeature["userHasFeaturesOnPage"],
                                LastFeaturedOnPage = (string)fileFeature["lastFeaturedOnPage"],
                                FeatureCountOnPage = CalculateFeatureCount(
                                    SelectedPage!.HubName, 
                                    (string)fileFeature["featureCountOnPage"], 
                                    fileFeature.ContainsKey("featureCountOnRawPage") ? (string)fileFeature["featureCountOnRawPage"] : "0"),
                                UserHasFeaturesOnHub = (bool)fileFeature["userHasFeaturesOnHub"],
                                LastFeaturedOnHub = (string)fileFeature["lastFeaturedOnHub"],
                                LastFeaturedPage = (string)fileFeature["lastFeaturedPage"],
                                FeatureCountOnHub = CalculateFeatureCount(
                                    SelectedPage!.HubName, 
                                    (string)fileFeature["featureCountOnHub"], 
                                    fileFeature.ContainsKey("featureCountOnRawHub") ? (string)fileFeature["featureCountOnRawHub"] : "0"),
                                TooSoonToFeatureUser = (bool)fileFeature["tooSoonToFeatureUser"],
                                TinEyeResults = new List<string>(TinEyeResults).Contains((string)fileFeature["tinEyeResults"]) ? (string)fileFeature["tinEyeResults"] : TinEyeResults[0],
                                AiCheckResults = new List<string>(AiCheckResults).Contains((string)fileFeature["aiCheckResults"]) ? (string)fileFeature["aiCheckResults"] : AiCheckResults[0],
                                PersonalMessage = fileFeature.ContainsKey("personalMessage") ? (string)fileFeature["personalMessage"] : "",
                            };
                            loadedFeature.PropertyChanged += OnFeaturePropertyChanged;
                            Features.Add(loadedFeature);
                        }
                        base.OnPropertyChanged(nameof(HasFeatures));
                        base.OnPropertyChanged(nameof(FeatureNavigationAllowed));
                        base.OnPropertyChanged(nameof(CanChangePage));
                        base.OnPropertyChanged(nameof(SaveFeaturesCommand));   
                        base.OnPropertyChanged(nameof(GenerateReportCommand));   
                        base.OnPropertyChanged(nameof(SaveReportCommand));   
                        IsDirty = false;
                        foreach (var feature in Features)
                        {
                            feature.IsDirty = false;
                            feature.OnSortKeyChange();
                        }
                        await Toast.Make($"Loaded {Features.Count} features for the {SelectedPage.DisplayName} page").Show();
                    }
                }
            }
        }
        catch (Exception ex)
        {
            await Toast.Make($"Failed: {ex.Message}", ToastDuration.Long).Show();
        }
    }

    private void ClearDirty()
    {
        IsDirty = false;
        foreach (var feature in Features)
        {
            feature.IsDirty = false;
        }
    }

    public SimpleCommand SaveFeaturesCommand => new(() =>
    {
        _ = SaveFeaturesAsync();
    }, () => !WaitingForPages && HasFeatures);
        
    private async Task SaveFeaturesAsync()
    {
        if (SelectedPage != null)
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
            var json = JsonConvert.SerializeObject(file, Formatting.Indented, jsonSettings).Replace("\": ", "\" : ");

            var fileName = $"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name} - {DateTime.Now:yyyy-MM-dd}.json";
            using var stream = new MemoryStream(Encoding.Default.GetBytes(json));
            var fileSaverResult = await FileSaver.Default.SaveAsync(fileName, stream);
            if (fileSaverResult.IsSuccessful)
            {
                ClearDirty();
                await Toast.Make($"Saved {Features.Count} features for the {SelectedPage.DisplayName} page").Show();
            }
            else
            {
                await Toast.Make($"Failed to save the feature log: {fileSaverResult.Exception.Message})", ToastDuration.Long).Show();
            }
        }
    }

    public SimpleCommand GenerateReportCommand => new(() =>
    {
        if (SelectedPage == null)
        {
            return;
        }

        _ = CopyTextToClipboardAsync(GenerateLogReport(), "Generated report", "Copied the report of features to the clipboard");
    }, () => !WaitingForPages && HasFeatures);

    public SimpleCommand SaveReportCommand => new(() =>
    {
        _ = SaveReportAsync();
    }, () => !WaitingForPages && HasFeatures);
    
    private async Task SaveReportAsync()
    {
        if (SelectedPage == null)
        {
            return;
        }

        var fileName = $"{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name} - {DateTime.Now:yyyy-MM-dd}.features";
        using var stream = new MemoryStream(Encoding.Default.GetBytes(GenerateLogReport()));
        var fileSaverResult = await FileSaver.Default.SaveAsync(fileName, stream);
        if (fileSaverResult.IsSuccessful)
        {
            await Toast.Make($"Saved {Features.Count} features for the {SelectedPage.DisplayName} page to a report").Show();
        }
        else
        {
            await Toast.Make($"Failed to save the feature report: {fileSaverResult.Exception.Message})", ToastDuration.Long).Show();
        }
    }

    public SimpleCommand LaunchSettingsCommand => new(() =>
    {
        MainWindow!.Navigation.PushAsync(new Settings()
        {
            BindingContext = SettingsViewModel
        });
    });

    public SimpleCommand LaunchAboutCommand => new(() =>
    {
        MainWindow!.Navigation.PushAsync(new About()
        {
            BindingContext = new AboutViewModel()
        });
    });
    
    public SimpleCommand AddFeatureCommand => new(() =>
    {
        if (Clipboard.HasText)
        {
            var text = Clipboard.GetTextAsync().Result ?? "";
            if (!string.IsNullOrEmpty(text))
            {
                var duplicateFeature = Features.FirstOrDefault(feature => string.Equals(feature.PostLink, text, StringComparison.OrdinalIgnoreCase));
                if (duplicateFeature != null)
                {
                    _ = Toast.Make("There is already a feature in the list with that post link, selected the existing feature").Show();
                    SelectedFeature = duplicateFeature;
                    return;
                }
            }

            if (text.StartsWith("https://vero.co/"))
            {
                var feature = new Feature(SelectedPage!.HubName)
                {
                    PostLink = text,
                    UserAlias = text["https://vero.co/".Length..].Split("/").FirstOrDefault() ?? "",
                };
                feature.PropertyChanged += OnFeaturePropertyChanged;
                Features.Add(feature);
                OnPropertyChanged(nameof(CanChangePage));
                SelectedFeature = feature;
                SemanticScreenReader.Announce($"Added feature for {feature.UserAlias}");
            }
            else
            {
                var feature = new Feature(SelectedPage!.HubName);
                feature.PropertyChanged += OnFeaturePropertyChanged;
                Features.Add(feature);
                OnPropertyChanged(nameof(CanChangePage));
                SelectedFeature = feature;
                SemanticScreenReader.Announce($"Added blank feature");
            }
        }
        else
        {
            var feature = new Feature(SelectedPage!.HubName);
            feature.PropertyChanged += OnFeaturePropertyChanged;
            Features.Add(feature);
            OnPropertyChanged(nameof(CanChangePage));
            SelectedFeature = feature;
            SemanticScreenReader.Announce($"Added blank feature");
        }
        OnPropertyChanged(nameof(SaveFeaturesCommand));
        OnPropertyChanged(nameof(SaveReportCommand));
        OnPropertyChanged(nameof(GenerateReportCommand));
    }, () => !WaitingForPages && SelectedPage != null);

    public SimpleCommand RemoveFeatureCommand => new(() =>
    {
        if (SelectedFeature is Feature feature)
        {
            SelectedFeature = null;
            feature.PropertyChanged -= OnFeaturePropertyChanged;
            Features.Remove(feature);
            OnPropertyChanged(nameof(HasFeatures));
            OnPropertyChanged(nameof(FeatureNavigationAllowed));
            OnPropertyChanged(nameof(CanChangePage));
            OnPropertyChanged(nameof(SaveFeaturesCommand));
            OnPropertyChanged(nameof(GenerateReportCommand));
            OnPropertyChanged(nameof(SaveReportCommand));
        }
    }, () => SelectedFeature != null);

    public SimpleCommand LoadPostCommand => new(() =>
    {
        if (SelectedFeature is Feature feature)
        {
            if (feature.PostLink.StartsWith("https://vero.co/"))
            {
                LoadedPost = new LoadedPostViewModel(this, SelectedPage!.HubName);
                MainWindow?.Navigation.PushAsync(new LoadedPost
                {
                    BindingContext = LoadedPost
                });
            }
        }
    },
    () => SelectedPage != null && SelectedFeature != null && SelectedFeature.PostLink.StartsWith("https://vero.co/"));

    public SimpleCommand CopyPageFeatureTagCommand => new(() =>
    {
        var prefix = SettingsViewModel.IncludeHash ? "#" : "";
        _ = CopyTextToClipboardAsync(SelectedPage!.HubName == "other" 
            ? $"{prefix}{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature!.UserAlias}" 
            : $"{prefix}{SelectedPage.HubName}_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature!.UserAlias}", 
            "Page feature tag", 
            "Copied the page feature tag to the clipboard");
    }, () => SelectedPage != null && SelectedFeature != null && !string.IsNullOrEmpty(SelectedFeature.UserAlias));

    public SimpleCommand CopyRawPageFeatureTagCommand => new(() =>
    {
        var prefix = SettingsViewModel.IncludeHash ? "#" : "";
        if (SelectedPage!.HubName == "snap")
        {
            _ = CopyTextToClipboardAsync(
                $"{prefix}raw_{SelectedPage.PageName ?? SelectedPage.Name}_{SelectedFeature!.UserAlias}",
                "RAW page feature tag", 
                "Copied the RAW page feature tag to the clipboard");
        }
    }, () => SelectedPage != null && SelectedFeature != null && !string.IsNullOrEmpty(SelectedFeature.UserAlias));

    public SimpleCommand CopyHubFeatureTagCommand => new(() =>
    {
        var prefix = SettingsViewModel.IncludeHash ? "#" : "";
        if (SelectedPage!.HubName != "other")
        {
            _ = CopyTextToClipboardAsync(
                $"{prefix}{SelectedPage.HubName}_featured_{SelectedFeature!.UserAlias}",
                "Hub feature tag", 
                "Copied the hub feature tag to the clipboard");
        }
    }, () => SelectedPage != null && SelectedFeature != null && !string.IsNullOrEmpty(SelectedFeature.UserAlias));

    public SimpleCommand CopyRawHubFeatureTagCommand => new(() =>
    {
        var prefix = SettingsViewModel.IncludeHash ? "#" : "";
        if (SelectedPage!.HubName == "snap")
        {
            _ = CopyTextToClipboardAsync(
                $"{prefix}raw_featured_{SelectedFeature!.UserAlias}", 
                "RAW hub feature tag",
                "Copied the RAW hub feature tag to the clipboard");
        }
    }, () => SelectedPage != null && SelectedFeature != null && !string.IsNullOrEmpty(SelectedFeature.UserAlias));

    public SimpleCommand NavigateToPreviousFeatureCommand => new(() =>
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
        ScriptViewModel.UpdateForFeature();
    });

    public SimpleCommand NavigateToNextFeatureCommand => new(() =>
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
        ScriptViewModel.Feature = pickedAndAllowedFeatures[newIndex];
        ScriptViewModel.UpdateForFeature();
    });

    public SimpleCommandWithParameter EditFeatureCommand => new(feature =>
    {
        SelectedFeature = feature as Feature;
    });

    public SimpleCommandWithParameter DeleteFeatureCommand => new(feature =>
    {
        SelectedFeature = null;
        if (feature is Feature featureToDelete)
        {
            featureToDelete.PropertyChanged -= OnFeaturePropertyChanged;
            Features.Remove(featureToDelete);
        }

        OnPropertyChanged(nameof(HasFeatures));
        OnPropertyChanged(nameof(FeatureNavigationAllowed));
        OnPropertyChanged(nameof(CanChangePage));
        OnPropertyChanged(nameof(SaveFeaturesCommand));
        OnPropertyChanged(nameof(GenerateReportCommand));
        OnPropertyChanged(nameof(SaveReportCommand));
    });

    public SimpleCommandWithParameter ShowScriptsForFeatureCommand => new(feature =>
    {
        if (feature is Feature featureToShow)
        {
            ScriptViewModel.Feature = featureToShow;
            ScriptViewModel.UpdateForFeature();
            _ = MainWindow!.Navigation.PushAsync(new Scripts(this));
        }
    });

    public SimpleCommandWithParameter ShowPersonalMessageForFeatureCommand => new(feature =>
    {
        if (feature is Feature featureToShow)
        {
            _ = MainWindow!.Navigation.PushAsync(new PersonalMessage(new PersonalMessageViewModel(this, featureToShow)));
        }
    });
    
    public SimpleCommandWithParameter CopyPersonalMessageCommand => new(feature =>
    {
        if (SelectedPage != null && feature is Feature featureToCopy)
        {
            var personalMessageTemplate = featureToCopy.UserHasFeaturesOnPage
                ? (string.IsNullOrEmpty(SettingsViewModel.PersonalMessage)
                    ? "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    : SettingsViewModel.PersonalMessage)
                : (string.IsNullOrEmpty(SettingsViewModel.PersonalMessageFirst)
                    ? "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
                    : SettingsViewModel.PersonalMessageFirst);
            var fullMessage = personalMessageTemplate
                .Replace("%%PAGENAME%%", SelectedPage.DisplayName)
                .Replace("%%HUBNAME%%", SelectedPage.HubName)
                .Replace("%%USERNAME%%", featureToCopy.UserName)
                .Replace("%%USERALIAS%%", featureToCopy.UserAlias)
                .Replace("%%PERSONALMESSAGE%%", string.IsNullOrEmpty(featureToCopy.PersonalMessage) ? "[PERSONAL MESSAGE]" : featureToCopy.PersonalMessage);
            _ = CopyTextToClipboardAsync(fullMessage, "Copied to clipboard", "The personal message was copied to the clipboard");
            _ = MainWindow!.Navigation.PopAsync();
        }
    });

    #endregion

    #region Waiting state

    private bool waitingForPages = true;

    private bool WaitingForPages
    {
        get => waitingForPages;
        set => Set(ref waitingForPages, value, [
            nameof(CanChangePage),
            nameof(CanChangeStaffLevel),
            nameof(NewFeaturesCommand),
            nameof(OpenFeaturesCommand),
            nameof(SaveFeaturesCommand),
            nameof(GenerateReportCommand),
            nameof(SaveReportCommand),
            nameof(AddFeatureCommand)
        ]);
    }

    #endregion

    #region Dirty state

    private bool isDirty;

    private bool IsDirty
    {
        get => isDirty;
        set => Set(ref isDirty, value);
    }

    private async Task HandleDirtyActionAsync(string action, Func<bool, Task> onConfirmAction)
    {
        if (await MainWindow!.DisplayAlert(
            "Log not saved",
            $"The current log document has been edited. Would you like to save the log before {action}?",
            "Yes", "No"))
        {
            _ = SaveFeaturesAsync();
            if (!IsDirty)
            {
                await onConfirmAction(true);
            }
        } else {
            await onConfirmAction(false);
        }
    }

    #endregion

    #region Pages

    public ObservableCollection<LoadedPage> LoadedPages { get; } = [];

    private LoadedPage? selectedPage;

    public LoadedPage? SelectedPage
    {
        get => selectedPage;
        set
        {
            if (Set(ref selectedPage, value, [nameof(AddFeatureCommand)]))
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
                excludedTags = SelectedPage != null 
                    ? Preferences.Default.Get(nameof(ExcludedTags) + ":" + SelectedPage.Id, "") 
                    : "";
                OnPropertyChanged(nameof(ExcludedTags));
                StaffLevel = SelectedPage != null 
                    ? Preferences.Default.Get(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevels[0]) 
                    : Preferences.Default.Get(nameof(StaffLevel), StaffLevels[0]);
                if (!StaffLevels.Contains(StaffLevel))
                {
                    StaffLevel = StaffLevels[0];
                }
            }
        }
    }

    public bool CanChangePage => !WaitingForPages && Features.Count == 0;

    public bool ClickHubVisibility => SelectedPage?.HubName == "click";

    public bool SnapHubVisibility => SelectedPage?.HubName == "snap";

    public bool SnapOrClickHubVisibility => SelectedPage?.HubName == "snap" || SelectedPage?.HubName == "click";

    public bool HasSelectedPage => SelectedPage != null;
    public bool NoSelectedPage => SelectedPage == null;

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

    private string page = FixPageHub(Preferences.Default.Get(nameof(Page), ""));

    public string Page
    {
        get => page;
        set
        {
            if (Set(ref page, value, [nameof(StaffLevels)]))
            {
                Preferences.Default.Set(nameof(Page), Page);
                PageValidation = CalculatePageValidation(Page);
                IsDirty = true;
            }
        }
    }

    private ValidationResult pageValidation = CalculatePageValidation(Preferences.Default.Get(nameof(Page), ""));

    public ValidationResult PageValidation
    {
        get => pageValidation;
        private set => Set(ref pageValidation, value);
    }

    #endregion

    #region Features

    private ObservableCollection<Feature> features = [];

    public ObservableCollection<Feature> Features
    {
        get => features;
        set => Set(ref features, value);
    }

    private Feature? selectedFeature;
    public Feature? SelectedFeature
    {
        get => selectedFeature;
        set
        {
            if (Set(ref selectedFeature, value))
            {
                OnPropertyChanged(nameof(HasSelectedFeature));
                OnPropertyChanged(nameof(RemoveFeatureCommand));
                OnPropertyChanged(nameof(LoadPostCommand));

                // Handle the navigation
                if (selectedFeature != null)
                {
                    _ = MainWindow!.Navigation.PushAsync(new FeatureEditor
                    {
                        BindingContext = this,
                    });
                }
                else
                {
                    _ = MainWindow!.Navigation.PopToRootAsync();
                }
            }
        }
    }

    private void OnFeaturePropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        switch (e.PropertyName)
        {
            case "SortKey":
                ResortList();
                break;
            
            case "PostLink":
                if (sender is Feature postLinkFeature && postLinkFeature == SelectedFeature)
                {
                    OnPropertyChanged(nameof(LoadPostCommand));
                }

                break;
            
            case "UserAlias":
                if (sender is Feature userAliasFeature && userAliasFeature == SelectedFeature)
                {
                    OnPropertyChanged(nameof(CopyPageFeatureTagCommand));
                    OnPropertyChanged(nameof(CopyRawPageFeatureTagCommand));
                    OnPropertyChanged(nameof(CopyHubFeatureTagCommand));
                    OnPropertyChanged(nameof(CopyRawHubFeatureTagCommand));
                }

                break;
        }
    }

    private void ResortList()
    {
        var sortedFeatures = Features.OrderBy(feature => feature.SortKey).ToList();
        Features = new ObservableCollection<Feature>(sortedFeatures);
    }

    public bool FeatureNavigationAllowed => Features.Count(feature => feature.IsPickedAndAllowed) > 1;

    public bool HasSelectedFeature => SelectedFeature != null;

    public bool HasFeatures => Features.Count != 0;

    #endregion

    #region Staff level

    private static string[] SnapStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
        "Guest moderator"
    ];

    private static string[] ClickStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    private static string[] OtherStaffLevels => [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    public string[] StaffLevels =>
        SelectedPage?.HubName == "click" ? ClickStaffLevels :
        SelectedPage?.HubName == "snap" ? SnapStaffLevels :
        OtherStaffLevels;

    private string staffLevel = Preferences.Default.Get(nameof(StaffLevel), "Mod");

    public string StaffLevel
    {
        get => staffLevel;
        set
        {
            if (Set(ref staffLevel, value))
            {
                if (SelectedPage != null)
                {
                    Preferences.Default.Set(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevel);
                }
                else
                {
                    Preferences.Default.Set(nameof(StaffLevel), StaffLevel);
                }
            }
        }
    }

    public bool CanChangeStaffLevel => !WaitingForPages;

    #endregion
    
    #region Your alias

    private string yourAlias = Preferences.Default.Get(nameof(YourAlias), "");
    public string YourAlias
    {
        get => yourAlias;
        set
        {
            if (Set(ref yourAlias, value, [nameof(YourAliasValidation)]))
            {
                Preferences.Default.Set(nameof(YourAlias), YourAlias);
                ScriptViewModel.ClearAllPlaceholders();
            }
        }
    }
    public ValidationResult YourAliasValidation => Validation.ValidateUserName(YourAlias);

    #endregion

    #region Your first name

    private string yourFirstName = Preferences.Default.Get(nameof(YourFirstName), "");
    public string YourFirstName
    {
        get => yourFirstName;
        set
        {
            if (Set(ref yourFirstName, value, [nameof(YourFirstNameValidation)]))
            {
                Preferences.Default.Set(nameof(YourFirstName), YourFirstName);
                ScriptViewModel.ClearAllPlaceholders();
            }
        }
    }

    public ValidationResult YourFirstNameValidation => Validation.ValidateValueNotEmpty(YourFirstName);

    #endregion

    #region Excluded tags

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
                    Preferences.Default.Set(nameof(ExcludedTags) + ":" + SelectedPage.Id, ExcludedTags);
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
        SelectedPage?.HubName switch
        {
            "click" => ClickMemberships,
            "snap" => SnapMemberships,
            _ => OtherMemberships
        };

    private Dictionary<string, string> OldMembershipMap =>
        SelectedPage?.HubName switch
        {
            "click" => new Dictionary<string, string>
            {
                { "Member", "Click Member" },
                { "Bronze Member", "Click Bronze Member" },
                { "Silver Member", "Click Silver Member" },
                { "Gold Member", "Click Gold Member" },
                { "Platinum Member", "Click Platinum Member" },
            },
            "snap" => new Dictionary<string, string>
            {
                { "Member", "Snap Member" },
                { "VIP Member", "Snap VIP Member" },
                { "VIP Gold Member", "Snap VIP Gold Member" },
                { "Platinum Member", "Snap Platinum Member" },
                { "Elite Member", "Snap Elite Member" },
                { "Hall of Fame Member", "Snap Hall of Fame Member" },
                { "Diamond Member", "Snap Diamond Member" },
            },
            _ => []
        };

    private string MapMembershipLevelFromFile(string? userLevelFromFile)
    {
        if (userLevelFromFile == null)
        {
            return "None";
        }
        if (Memberships.Contains(userLevelFromFile))
        {
            return userLevelFromFile;
        }
        return OldMembershipMap.TryGetValue(userLevelFromFile, out var value) ? value : Memberships[0];
    }

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

    public bool FromRawTag(string tagSource)
    {
        return SelectedPage?.HubName == "snap" && tagSource is "RAW page tag" or "RAW community tag";
    }

    public bool FromCommunityTag(string tagSource)
    {
        return SelectedPage?.HubName switch
        {
            "click" => tagSource is "Click community tag",
            "snap" => tagSource is "Snap community tag" or "RAW community tag",
            _ => false
        };
    }

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
        CountArray(0, 25);

    #endregion

    #region TinEye results

    public string[] TinEyeResults => ["0 matches", "no matches", "matches found"];

    #endregion

    #region AI check results

    public string[] AiCheckResults => ["human", "ai"];

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
                        ? Preferences.Default.Get("PersonalMessage", "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉")
                        : Preferences.Default.Get("PersonalMessageFirst", "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉");
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
                        ? Preferences.Default.Get("PersonalMessage", "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉")
                        : Preferences.Default.Get("PersonalMessageFirst", "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉");
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
                        ? Preferences.Default.Get("PersonalMessage", "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉")
                        : Preferences.Default.Get("PersonalMessageFirst", "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉");
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

    private static async Task CopyTextToClipboardAsync(string text, string title, string successMessage)
    {
        await TrySetClipboardText(text);
        await Toast.Make($"{title}: {successMessage}").Show();
    }

    public static async Task TrySetClipboardText(string text)
    {
        await Clipboard.SetTextAsync(text);
    }

    #endregion

    #region Script view model

    public ScriptsViewModel ScriptViewModel { get; }

    #endregion

    #region Settings view model

    public SettingsViewModel SettingsViewModel { get; }

    #endregion

    #region Loaded post

    private LoadedPostViewModel? loadedPost;

    private LoadedPostViewModel? LoadedPost
    {
        get => loadedPost;
        set => Set(ref loadedPost, value, [nameof(TinEyeSource)]);
    }

    public string TinEyeSource => LoadedPost?.ImageValidation?.TinEyeUri ?? "about:blank";

    #endregion

    #region Misc

    public FeatureList? MainWindow { get; internal set; }
    
    public double ScreenWidth => Math.Max(800, DeviceDisplay.MainDisplayInfo.Width / DeviceDisplay.MainDisplayInfo.Density);

    internal void TriggerTinEyeSource()
    {
        OnPropertyChanged(nameof(TinEyeSource));
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

    #endregion
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
