using System.Collections.ObjectModel;
using System.Text.RegularExpressions;
using CommunityToolkit.Maui.Alerts;
using FeatureLogging.Base;
using FeatureLogging.Models;

namespace FeatureLogging.ViewModels
{
    public enum Script
    {
        Feature = 1,
        Comment,
        OriginalPost,
    }

    public partial class ScriptsViewModel(MainViewModel mainViewModel) : NotifyPropertyChanged
    {
        private readonly Dictionary<Script, string> scriptNames = new()
        {
            { Script.Feature, "feature" },
            { Script.Comment, "comment" },
            { Script.OriginalPost, "original post" },
        };

        private Feature? feature;

        public Feature? Feature
        {
            get => feature;
            set
            {
                if (Set(ref feature, value))
                {
                    UpdateScripts();
                }
            }
        }

        // #region Feature loading
        //
        // public void PopulateScriptFromFeatureFile()
        // {
        //     // Try populate from Feature Logging
        //     try
        //     {
        //         var sharedSettingsPath = MainViewModel.GetDataLocationPath();
        //         var featureFile = Path.Combine(sharedSettingsPath, "feature.json");
        //         if (File.Exists(featureFile))
        //         {
        //             // Load the feature, then delete the feature file.
        //             var feature = JsonConvert.DeserializeObject<Dictionary<string, dynamic>>(File.ReadAllText(featureFile)) ?? [];
        //             File.Delete(featureFile);
        //
        //             var featurePage = mainViewModel.LoadedPages.FirstOrDefault(loadedPage => loadedPage.Id == (string)feature["page"]);
        //             if (featurePage != null)
        //             {
        //                 Page = featurePage.Id;
        //                 CanChangePage = false;
        //                 StaffLevel = (string)feature["staffLevel"];
        //                 CanChangeStaffLevel = false;
        //                 UserName = (string)feature["userAlias"];
        //                 Membership = HubMemberships.Contains((string)feature["userLevel"]) ? (string)feature["userLevel"] : HubMemberships[0];
        //                 FirstForPage = feature["firstFeature"];
        //                 if (featurePage.HubName == "click")
        //                 {
        //                     RawTag = false;
        //                     switch ((string)feature["tagSource"])
        //                     {
        //                         default:
        //                             CommunityTag = false;
        //                             HubTag = false;
        //                             break;
        //                         case "Click community tag":
        //                             CommunityTag = true;
        //                             HubTag = false;
        //                             break;
        //                         case "Click hub tag":
        //                             CommunityTag = false;
        //                             HubTag = true;
        //                             break;
        //                     }
        //                 }
        //                 else if (featurePage.HubName == "snap")
        //                 {
        //                     HubTag = false;
        //                     switch ((string)feature["tagSource"])
        //                     {
        //                         default:
        //                             RawTag = false;
        //                             CommunityTag = false;
        //                             break;
        //                         case "RAW page tag":
        //                             RawTag = true;
        //                             CommunityTag = false;
        //                             break;
        //                         case "Snap community tag":
        //                             RawTag = false;
        //                             CommunityTag = true;
        //                             break;
        //                         case "RAW community tag":
        //                             RawTag = true;
        //                             CommunityTag = true;
        //                             break;
        //                         case "Snap membership tag":
        //                             // TODO andydragon : need to handle this...
        //                             RawTag = false;
        //                             CommunityTag = false;
        //                             break;
        //                     }
        //                 }
        //                 else
        //                 {
        //                     RawTag = false;
        //                     CommunityTag = false;
        //                     HubTag = false;
        //                 }
        //                 NewMembership = HubNewMemberships.Contains((string)feature["newLevel"]) ? (string)feature["newLevel"] : HubNewMemberships[0];
        //             }
        //             else
        //             {
        //                 CanChangePage = true;
        //                 CanChangeStaffLevel = true;
        //
        //             }
        //         }
        //     }
        //     catch (Exception ex)
        //     {
        //         // TODO andydragon : handle errors
        //         Console.WriteLine("Error occurred: {0}", ex.Message);
        //     }
        // }
        //
        // #endregion

        #region Commands

        public SimpleCommand CopyFeatureScriptCommand => new(() => CopyScript(Script.Feature, force: true));

        public SimpleCommand CopyFeatureScriptWithPlaceholdersCommand => new(() => CopyScript(Script.Feature, force: true, withPlaceholders: true));

        public SimpleCommand CopyCommentScriptCommand => new(() => CopyScript(Script.Comment, force: true));

        public SimpleCommand CopyCommentScriptWithPlaceholdersCommand => new(() => CopyScript(Script.Comment, force: true, withPlaceholders: true));

        public SimpleCommand CopyOriginalPostScriptCommand => new(() => CopyScript(Script.OriginalPost, force: true));

        public SimpleCommand CopyOriginalPostScriptWithPlaceholdersCommand => new(() => CopyScript(Script.OriginalPost, force: true, withPlaceholders: true));

        public SimpleCommand CopyNewMembershipScriptCommand => new(() => _ = CopyTextToClipboardAsync(NewMembershipScript, "Copied the new membership script to the clipboard"));

        #endregion

        public TemplatesCatalog TemplatesCatalog { get; set; } = new();

        public Dictionary<Script, string> Scripts { get; } = new()
        {
            { Script.Feature, "" },
            { Script.Comment, "" },
            { Script.OriginalPost, "" }
        };

        #region Feature script

        public string FeatureScript
        {
            get => Scripts[Script.Feature];
            set
            {
                if (Scripts[Script.Feature] != value)
                {
                    Scripts[Script.Feature] = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(FeatureScriptPlaceholderVisibility));
                }
            }
        }

        public Visibility FeatureScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Feature) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Comment script

        public string CommentScript
        {
            get => Scripts[Script.Comment];
            set
            {
                if (Scripts[Script.Comment] != value)
                {
                    Scripts[Script.Comment] = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CommentScriptPlaceholderVisibility));
                }
            }
        }

        public Visibility CommentScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Comment) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Original post script

        public string OriginalPostScript
        {
            get => Scripts[Script.OriginalPost];
            set
            {
                if (Scripts[Script.OriginalPost] != value)
                {
                    Scripts[Script.OriginalPost] = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(OriginalPostScriptPlaceholderVisibility));
                }
            }
        }

        public Visibility OriginalPostScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.OriginalPost) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region New membership level

        private static string[] SnapNewMemberships => [
            "None",
            "Snap Member (feature comment)",
            "Snap Member (original post comment)",
            "Snap VIP Member (feature comment)",
            "Snap VIP Member (original post comment)",
        ];

        private static string[] ClickNewMemberships => [
            "None",
            "Click Member",
            "Click Bronze Member",
            "Click Silver Member",
            "Click Gold Member",
            "Click Platinum Member",
        ];

        private static string[] OtherNewMemberships => [
            "None",
        ];

        public string[] HubNewMemberships =>
            mainViewModel.SelectedPage?.HubName == "click" ? ClickNewMemberships :
            mainViewModel.SelectedPage?.HubName == "snap" ? SnapNewMemberships :
            OtherNewMemberships;

        private string newMembership = "None";

        public string NewMembership
        {
            get => newMembership;
            set
            {
                if (Set(ref newMembership, value))
                {
                    OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                    UpdateNewMembershipScripts();
                }
            }
        }

        private string newMembershipScript = "";

        public string NewMembershipScript
        {
            get => newMembershipScript;
            set => Set(ref newMembershipScript, value);
        }

        #endregion

        #region Placeholder management

        public Dictionary<Script, ObservableCollection<Placeholder>> PlaceholdersMap { get; private set; } = new()
        {
            { Script.Feature, new ObservableCollection<Placeholder>() },
            { Script.Comment, new ObservableCollection<Placeholder>() },
            { Script.OriginalPost, new ObservableCollection<Placeholder>() }
        };

        public Dictionary<Script, ObservableCollection<Placeholder>> LongPlaceholdersMap { get; private set; } = new()
        {
            { Script.Feature, new ObservableCollection<Placeholder>() },
            { Script.Comment, new ObservableCollection<Placeholder>() },
            { Script.OriginalPost, new ObservableCollection<Placeholder>() }
        };

        private void ClearAllPlaceholders()
        {
            PlaceholdersMap[Script.Feature].Clear();
            PlaceholdersMap[Script.Comment].Clear();
            PlaceholdersMap[Script.OriginalPost].Clear();
            LongPlaceholdersMap[Script.Feature].Clear();
            LongPlaceholdersMap[Script.Comment].Clear();
            LongPlaceholdersMap[Script.OriginalPost].Clear();
        }

        public bool ScriptHasPlaceholder(Script script)
        {
            return PlaceholderRegex().Matches(Scripts[script]).Count != 0 || LongPlaceholderRegex().Matches(Scripts[script]).Count != 0;
        }

        public bool CheckForPlaceholders(Script script, bool force = false)
        {
            var needEditor = false;

            var placeholders = new List<string>();
            var matches = PlaceholderRegex().Matches(Scripts[script]);
            foreach (Match match in matches.Cast<Match>())
            {
                placeholders.Add(match.Captures.First().Value.Trim(['[', ']']));
            }
            if (placeholders.Count != 0)
            {
                foreach (var placeholderName in placeholders)
                {
                    if (PlaceholdersMap[script].FirstOrDefault(placeholder => placeholder.Name == placeholderName) == null)
                    {
                        var placeholderValue = "";
                        foreach (var otherScript in Enum.GetValues<Script>())
                        {
                            if (otherScript != script)
                            {
                                var otherPlaceholder = PlaceholdersMap[otherScript].FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholderName);
                                if (otherPlaceholder != null && !string.IsNullOrEmpty(otherPlaceholder.Value))
                                {
                                    placeholderValue = otherPlaceholder.Value;
                                }
                            }
                        }
                        needEditor = true;
                        PlaceholdersMap[script].Add(new Placeholder(placeholderName, placeholderValue));
                    }
                }
            }

            var longPlaceholders = new List<string>();
            var longMatches = LongPlaceholderRegex().Matches(Scripts[script]);
            foreach (Match match in longMatches.Cast<Match>())
            {
                longPlaceholders.Add(match.Captures.First().Value.Trim(['[', '{', '}', ']']));
            }
            if (longPlaceholders.Count != 0)
            {
                foreach (var longPlaceholderName in longPlaceholders)
                {
                    if (LongPlaceholdersMap[script].FirstOrDefault(longPlaceholder => longPlaceholder.Name == longPlaceholderName) == null)
                    {
                        var longPlaceholderValue = "";
                        foreach (var otherScript in Enum.GetValues<Script>())
                        {
                            if (otherScript != script)
                            {
                                var otherLongPlaceholder = LongPlaceholdersMap[otherScript].FirstOrDefault(otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholderName);
                                if (otherLongPlaceholder != null && !string.IsNullOrEmpty(otherLongPlaceholder.Value))
                                {
                                    longPlaceholderValue = otherLongPlaceholder.Value;
                                }
                            }
                        }
                        needEditor = true;
                        LongPlaceholdersMap[script].Add(new Placeholder(longPlaceholderName, longPlaceholderValue));
                    }
                }
            }
            if (placeholders.Count != 0 || longPlaceholders.Count != 0)
            {
                return needEditor || force;
            }
            return false;
        }

        internal void TransferPlaceholders(Script script)
        {
            foreach (var placeholder in PlaceholdersMap[script])
            {
                if (!string.IsNullOrEmpty(placeholder.Value))
                {
                    foreach (Script otherScript in Enum.GetValues(typeof(Script)))
                    {
                        if (otherScript != script)
                        {
                            var otherPlaceholder = PlaceholdersMap[otherScript].FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholder.Name);
                            if (otherPlaceholder != null)
                            {
                                otherPlaceholder.Value = placeholder.Value;
                            }
                        }
                    }
                }
            }
            foreach (var longPlaceholder in LongPlaceholdersMap[script])
            {
                if (!string.IsNullOrEmpty(longPlaceholder.Value))
                {
                    foreach (Script otherScript in Enum.GetValues(typeof(Script)))
                    {
                        if (otherScript != script)
                        {
                            var otherLongPlaceholder = LongPlaceholdersMap[otherScript].FirstOrDefault(otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholder.Name);
                            if (otherLongPlaceholder != null)
                            {
                                otherLongPlaceholder.Value = longPlaceholder.Value;
                            }
                        }
                    }
                }
            }
        }

        public string ProcessPlaceholders(Script script)
        {
            var result = Scripts[script];
            foreach (var placeholder in PlaceholdersMap[script])
            {
                result = result.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim());
            }
            foreach (var longPlaceholder in LongPlaceholdersMap[script])
            {
                result = result.Replace("[{" + longPlaceholder.Name + "}]", longPlaceholder.Value.Trim());
            }
            return result;
        }

        #endregion

        #region Script management

        public bool CanCopyScripts =>
            Feature is { UserAliasValidation.Valid: true, UserLevelValidation.Valid: true } &&
            // TODO andydragon
            //mainViewModel.YourAliasValidation.Valid &&
            //mainViewModel.YourFirstNameValidation.Valid &&
            mainViewModel.PageValidation.Valid;

        public bool CanCopyNewMembershipScript =>
            NewMembership != "None" &&
            Feature is { UserAliasValidation.Valid: true, UserLevelValidation.Valid: true } &&
            // TODO andydragon
            //mainViewModel.YourAliasValidation.Valid &&
            //mainViewModel.YourFirstNameValidation.Valid &&
            mainViewModel.PageValidation.Valid;

        private void UpdateScripts()
        {
            var pageName = mainViewModel.Page;
            var sourcePage = mainViewModel.SelectedPage;
            var pageId = pageName;
            var scriptPageName = pageName;
            var scriptPageHash = pageName;
            var scriptPageTitle = pageName;
            if (sourcePage != null)
            {
                pageId = sourcePage.Id;
                pageName = sourcePage.Name;
                scriptPageName = pageName;
                scriptPageHash = pageName;
                scriptPageTitle = pageName;
                if (sourcePage.PageName != null)
                {
                    scriptPageName = sourcePage.PageName;
                }
                if (sourcePage.Title != null)
                {
                    scriptPageTitle = sourcePage.Title;
                }
                if (sourcePage.HashTag != null)
                {
                    scriptPageHash = sourcePage.HashTag;
                }
            }
            if (!CanCopyScripts)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.Valid)
                    {
                        validationErrors += prefix + ": " + (result.Error ?? "unknown") + "\n";
                    }
                }

                CheckValidation("User", Feature?.UserAliasValidation ?? new ValidationResult(ValidationLevel.Error));
                CheckValidation("Level", Feature?.UserLevelValidation ?? new ValidationResult(ValidationLevel.Error));
                // TODO andydragon
                //CheckValidation("You", mainViewModel.YourNameValidation);
                //CheckValidation("Your first name", mainViewModel.YourFirstNameValidation);
                CheckValidation("Page:", mainViewModel.PageValidation);

                FeatureScript = validationErrors;
                CommentScript = "";
                OriginalPostScript = "";
            }
            else
            {
                var featureScriptTemplate = GetTemplate("feature", pageId);
                var commentScriptTemplate = GetTemplate("comment", pageId);
                var originalPostScriptTemplate = GetTemplate("original post", pageId);
                FeatureScript = featureScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                    .Replace("%%USERNAME%%", Feature!.UserAlias)
                    // TODO
                    //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                    //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                    .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
                CommentScript = commentScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                    .Replace("%%USERNAME%%", Feature!.UserAlias)
                    // TODO
                    //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                    //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                    .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
                OriginalPostScript = originalPostScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                    .Replace("%%USERNAME%%", Feature!.UserAlias)
                    // TODO
                    //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                    //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                    .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
            }
        }

        private string GetTemplate(
            string templateName,
            string pageName)
        {
            TemplateEntry? template = null;
            var templatePage = TemplatesCatalog.Pages.FirstOrDefault(templatePageEntry => templatePageEntry.Name == pageName);
            var firstForPage = Feature?.UserHasFeaturesOnPage ?? false;
            var rawTag = Feature?.TagSource is "RAW page tag" or "RAW community tag";
            var communityTag = Feature?.TagSource == "Community tag";

            // Check first feature and raw and community
            if (mainViewModel.SelectedPage?.HubName == "snap" && firstForPage && rawTag && communityTag)
            {
                template = templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first raw community " + templateName);
            }

            // Next check first feature and raw
            if (mainViewModel.SelectedPage?.HubName == "snap" && firstForPage && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first raw " + templateName);
            }

            // Next check first feature and community
            if (mainViewModel.SelectedPage?.HubName == "snap" && firstForPage && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first community " + templateName);
            }

            // Next check first feature
            if (firstForPage)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first " + templateName);
            }

            // Next check raw and community
            if (mainViewModel.SelectedPage?.HubName == "snap" && rawTag && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "raw community " + templateName);
            }

            // Next check raw
            if (mainViewModel.SelectedPage?.HubName == "snap" && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "raw " + templateName);
            }

            // Next check community
            if (mainViewModel.SelectedPage?.HubName == "snap" && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "community " + templateName);
            }

            // Last check standard
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == templateName);

            return template?.Template ?? "";
        }

        private static string GetNewMembershipScriptName(string hubName, string newMembershipLevel)
        {
            return hubName switch
            {
                "snap" => newMembershipLevel switch
                {
                    "Snap Member (feature comment)" => "snap:member feature",
                    "Snap Member (original post comment)" => "snap:member original post",
                    "Snap VIP Member (feature comment)" => "snap:vip member feature",
                    "Snap VIP Member (original post comment)" => "snap:vip member original post",
                    _ => "",
                },
                "click" => newMembershipLevel switch
                {
                    "Click Member" => "click:member",
                    "Click Bronze Member" => "click:bronze_member",
                    "Click Silver Member" => "click:silver_member",
                    "Click Gold Member" => "click:gold_member",
                    "Click Platinum Member" => "click:platinum_member",
                    _ => "",
                },
                _ => ""
            };
        }

        private void UpdateNewMembershipScripts()
        {
            if (!CanCopyNewMembershipScript)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.Valid)
                    {
                        validationErrors += prefix + ": " + (result.Error ?? "unknown") + "\n";
                    }
                }

                if (newMembership != "None")
                {
                    CheckValidation("User", Feature?.UserAliasValidation ?? new ValidationResult(ValidationLevel.Error));
                }

                NewMembershipScript = validationErrors;
            }
            else
            {
                var hubName = mainViewModel.SelectedPage?.HubName;
                var pageName = mainViewModel.Page;
                var scriptPageName = pageName;
                var scriptPageHash = pageName;
                var scriptPageTitle = pageName;
                var sourcePage = mainViewModel.SelectedPage;
                if (sourcePage != null)
                {
                    pageName = sourcePage.Name;
                    scriptPageName = pageName;
                    scriptPageHash = pageName;
                    scriptPageTitle = pageName;
                    if (sourcePage.PageName != null)
                    {
                        scriptPageName = sourcePage.PageName;
                    }
                    if (sourcePage.Title != null)
                    {
                        scriptPageTitle = sourcePage.Title;
                    }
                    if (sourcePage.HashTag != null)
                    {
                        scriptPageHash = sourcePage.HashTag;
                    }
                }
                if (!string.IsNullOrEmpty(hubName))
                {
                    var templateName = GetNewMembershipScriptName(hubName, NewMembership);
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == templateName);
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                        .Replace("%%USERNAME%%", Feature!.UserAlias)
                        // TODO
                        //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                        //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                        .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
                }
                else if (NewMembership == "Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                        .Replace("%%USERNAME%%", Feature!.UserAlias)
                        // TODO
                        //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                        //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                        .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
                }
                else if (NewMembership == "VIP Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                        .Replace("%%USERNAME%%", Feature!.UserAlias)
                        // TODO
                        //.Replace("%%YOURNAME%%", mainViewModel.YourName)
                        //.Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                        .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
                }
            }
        }

        #endregion

        #region Clipboard management

        private static async Task CopyTextToClipboardAsync(string text, string successMessage)
        {
            await MainViewModel.TrySetClipboardText(text);
            await Toast.Make(successMessage).Show();
        }

        private void CopyScript(Script script, bool force = false, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                var unprocessedScript = Scripts[script];
                _ = CopyTextToClipboardAsync(unprocessedScript, "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else if (CheckForPlaceholders(script, force))
            {
                // var editor = new PlaceholderEditor(this, script)
                // {
                //     Owner = Application.Current.MainWindow,
                //     WindowStartupLocation = WindowStartupLocation.CenterOwner,
                // };
                // editor.ShowDialog();
            }
            else
            {
                var processedScript = ProcessPlaceholders(script);
                TransferPlaceholders(script);
                _ = CopyTextToClipboardAsync(processedScript, "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        public void CopyScriptFromPlaceholders(Script script, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                _ = CopyTextToClipboardAsync(Scripts[script], "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else
            {
                TransferPlaceholders(script);
                _ = CopyTextToClipboardAsync(ProcessPlaceholders(script), "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        #endregion

        [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
        private static partial Regex PlaceholderRegex();

        [GeneratedRegex("\\[\\{([^\\}]*)\\}\\]")]
        private static partial Regex LongPlaceholderRegex();
    }
}
