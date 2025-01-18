using Newtonsoft.Json;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.IO;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;

namespace FeatureLogging
{
    public enum Script
    {
        Feature = 1,
        Comment,
        OriginalPost,
    }

    public partial class ScriptsViewModel : NotifyPropertyChanged
    {
        #region Field validation

        public static ValidationResult ValidateUser(string hubName, string userName)
        {
            var userNameValidationResult = ValidateUserName(userName);
            if (!userNameValidationResult.Valid)
            {
                return userNameValidationResult;
            }
            if (Validation.DisallowList.TryGetValue(hubName, out List<string>? value) && 
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
            return new ValidationResult(true);
        }

        #endregion

        private readonly NotificationManager notificationManager = new();
        private readonly Dictionary<Script, string> scriptNames = new()
        {
            { Script.Feature, "feature" },
            { Script.Comment, "comment" },
            { Script.OriginalPost, "original post" },
        };

        private readonly MainViewModel mainViewModel;

        public ScriptsViewModel(MainViewModel mainViewModel)
        {
            this.mainViewModel = mainViewModel;
            TemplatesCatalog = new TemplatesCatalog();
            Scripts = new Dictionary<Script, string>
            {
                { Script.Feature, "" },
                { Script.Comment, "" },
                { Script.OriginalPost, "" }
            };
            PlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
            {
                { Script.Feature, new ObservableCollection<Placeholder>() },
                { Script.Comment, new ObservableCollection<Placeholder>() },
                { Script.OriginalPost, new ObservableCollection<Placeholder>() }
            };
            LongPlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
            {
                { Script.Feature, new ObservableCollection<Placeholder>() },
                { Script.Comment, new ObservableCollection<Placeholder>() },
                { Script.OriginalPost, new ObservableCollection<Placeholder>() }
            };
            CopyFeatureScriptCommand = new Command(() => CopyScript(Script.Feature, force: true));
            CopyFeatureScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.Feature, force: true, withPlaceholders: true));
            CopyCommentScriptCommand = new Command(() => CopyScript(Script.Comment, force: true));
            CopyCommentScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.Comment, force: true, withPlaceholders: true));
            CopyOriginalPostScriptCommand = new Command(() => CopyScript(Script.OriginalPost, force: true));
            CopyOriginalPostScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.OriginalPost, force: true, withPlaceholders: true));
            CopyNewMembershipScriptCommand = new Command(CopyNewMembershipScript);
        }

        #region Feature loading

        public void PopulateScriptFromFeatureFile()
        {
            // Try populate from Feature Logging
            try
            {
                var sharedSettingsPath = MainViewModel.GetDataLocationPath(true);
                var featureFile = Path.Combine(sharedSettingsPath, "feature.json");
                if (File.Exists(featureFile))
                {
                    // Load the feature, then delete the feature file.
                    var feature = JsonConvert.DeserializeObject<Dictionary<string, dynamic>>(File.ReadAllText(featureFile)) ?? [];
                    File.Delete(featureFile);

                    var page = mainViewModel.LoadedPages.FirstOrDefault(page => page.Id == (string)feature["page"]);
                    if (page != null)
                    {
                        Page = page.Id;
                        CanChangePage = false;
                        StaffLevel = (string)feature["staffLevel"];
                        CanChangeStaffLevel = false;
                        UserName = (string)feature["userAlias"];
                        Membership = HubMemberships.Contains((string)feature["userLevel"]) ? (string)feature["userLevel"] : HubMemberships[0];
                        FirstForPage = feature["firstFeature"];
                        if (page.HubName == "click")
                        {
                            RawTag = false;
                            switch ((string)feature["tagSource"])
                            {
                                case "Page tag":
                                default:
                                    CommunityTag = false;
                                    HubTag = false;
                                    break;
                                case "Click community tag":
                                    CommunityTag = true;
                                    HubTag = false;
                                    break;
                                case "Click hub tag":
                                    CommunityTag = false;
                                    HubTag = true;
                                    break;
                            }
                        }
                        else if (page.HubName == "snap")
                        {
                            HubTag = false;
                            switch ((string)feature["tagSource"])
                            {
                                case "Page tag":
                                default:
                                    RawTag = false;
                                    CommunityTag = false;
                                    break;
                                case "RAW page tag":
                                    RawTag = true;
                                    CommunityTag = false;
                                    break;
                                case "Snap community tag":
                                    RawTag = false;
                                    CommunityTag = true;
                                    break;
                                case "RAW community tag":
                                    RawTag = true;
                                    CommunityTag = true;
                                    break;
                                case "Snap membership tag":
                                    // TODO andydragon : need to handle this...
                                    RawTag = false;
                                    CommunityTag = false;
                                    break;
                            }
                        }
                        else
                        {
                            RawTag = false;
                            CommunityTag = false;
                            HubTag = false;
                        }
                        NewMembership = HubNewMemberships.Contains((string)feature["newLevel"]) ? (string)feature["newLevel"] : HubNewMemberships[0];
                    } 
                    else
                    {
                        CanChangePage = true;
                        CanChangeStaffLevel = true;

                    }
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

        public ICommand CopyFeatureScriptCommand { get; }

        public ICommand CopyFeatureScriptWithPlaceholdersCommand { get; }

        public ICommand CopyCommentScriptCommand { get; }

        public ICommand CopyCommentScriptWithPlaceholdersCommand { get; }

        public ICommand CopyOriginalPostScriptCommand { get; }

        public ICommand CopyOriginalPostScriptWithPlaceholdersCommand { get; }

        public ICommand CopyNewMembershipScriptCommand { get; }

        #endregion

        public TemplatesCatalog TemplatesCatalog { get; set; }

        #region User name

        private string userName = "";

        public string UserName
        {
            get => userName;
            set
            {
                if (Set(ref userName, value))
                {
                    UserNameValidation = ValidateUser(SelectedPage?.HubName ?? "", UserName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult userNameValidation = ValidateUser("", "");

        public ValidationResult UserNameValidation
        {
            get => userNameValidation;
            private set
            {
                if (Set(ref userNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                }
            }
        }

        #endregion

        #region Membership level

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

        public string[] HubMemberships => 
            SelectedPage?.HubName == "click" ? ClickMemberships : 
            SelectedPage?.HubName == "snap" ? SnapMemberships :
            OtherMemberships;

        private string membership = "None";

        public string Membership
        {
            get => membership;
            set
            {
                if (Set(ref membership, value))
                {
                    MembershipValidation = ValidateValueNotDefault(Membership, "None");
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult membershipValidation = ValidateValueNotDefault("None", "None");

        public ValidationResult MembershipValidation
        {
            get => membershipValidation;
            private set
            {
                if (Set(ref membershipValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                }
            }
        }

        #endregion

        #region Your name

        private string yourName = UserSettings.Get(nameof(YourName), "");

        public string YourName
        {
            get => yourName;
            set
            {
                if (Set(ref yourName, value))
                {
                    UserSettings.Store(nameof(YourName), YourName);
                    YourNameValidation = ValidateUserName(YourName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourNameValidation = ValidateUserName(UserSettings.Get(nameof(YourName), ""));

        public ValidationResult YourNameValidation
        {
            get => yourNameValidation;
            private set
            {
                if (Set(ref yourNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                }
            }
        }

        #endregion

        #region Your first name

        private string yourFirstName = UserSettings.Get(nameof(YourFirstName), "");

        public string YourFirstName
        {
            get => yourFirstName;
            set
            {
                if (Set(ref yourFirstName, value))
                {
                    UserSettings.Store(nameof(YourFirstName), YourFirstName);
                    YourFirstNameValidation = ValidateValueNotEmpty(YourFirstName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourFirstNameValidation = ValidateUserName(UserSettings.Get(nameof(YourFirstName), ""));

        public ValidationResult YourFirstNameValidation
        {
            get => yourFirstNameValidation;
            private set
            {
                if (Set(ref yourFirstNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                }
            }
        }

        #endregion

        #region Pages

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
                    if (oldHubName != SelectedPage?.HubName)
                    {
                        Membership = "None";
                        OnPropertyChanged(nameof(HubMemberships));
                        OnPropertyChanged(nameof(ClickHubVisibility));
                        OnPropertyChanged(nameof(SnapHubVisibility));
                        NewMembership = "None";
                        OnPropertyChanged(nameof(HubNewMemberships));
                        OnPropertyChanged(nameof(UserName));
                    }
                }
            }
        }
        public Visibility ClickHubVisibility => SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;
        public Visibility SnapHubVisibility => SelectedPage?.HubName == "snap" ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Page

        private static ValidationResult CalculatePageValidation(string page)
        {
            return ValidateValueNotEmpty(page);
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
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
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
                    OnPropertyChanged(nameof(CanCopyScripts));
                }
            }
        }

        private bool canChangePage = true;

        public bool CanChangePage
        {
            get => canChangePage;
            set => Set(ref canChangePage, value);
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
                    UserSettings.Store(nameof(StaffLevel), StaffLevel);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private bool canChangeStaffLevel = true;

        public bool CanChangeStaffLevel
        {
            get => canChangeStaffLevel;
            set => Set(ref canChangeStaffLevel, value);
        }

        #endregion

        #region First for page

        private bool firstForPage = false;

        public bool FirstForPage
        {
            get => firstForPage;
            set
            {
                if (Set(ref firstForPage, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region RAW tag

        private bool rawTag = false;

        public bool RawTag
        {
            get => rawTag;
            set
            {
                if (Set(ref rawTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Community tag

        private bool communityTag = false;

        public bool CommunityTag
        {
            get => communityTag;
            set
            {
                if (Set(ref communityTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Hub tag

        private bool hubTag = false;

        public bool HubTag
        {
            get => hubTag;
            set
            {
                if (Set(ref hubTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Feature script

        public Dictionary<Script, string> Scripts { get; private set; }

        public string FeatureScript
        {
            get => Scripts[Script.Feature];
            set
            {
                if (Scripts[Script.Feature] != value)
                {
                    Scripts[Script.Feature] = value;
                    OnPropertyChanged(nameof(FeatureScript));
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
                    OnPropertyChanged(nameof(CommentScript));
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
                    OnPropertyChanged(nameof(OriginalPostScript));
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
            SelectedPage?.HubName == "click" ? ClickNewMemberships : 
            SelectedPage?.HubName == "snap" ? SnapNewMemberships :
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

        public Dictionary<Script, ObservableCollection<Placeholder>> PlaceholdersMap { get; private set; }
        public Dictionary<Script, ObservableCollection<Placeholder>> LongPlaceholdersMap { get; private set; }

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
            UserNameValidation.Valid &&
            MembershipValidation.Valid &&
            YourNameValidation.Valid &&
            YourFirstNameValidation.Valid &&
            PageValidation.Valid;

        public bool CanCopyNewMembershipScript =>
            NewMembership != "None" &&
            UserNameValidation.Valid;

        private void UpdateScripts()
        {
            var pageName = Page;
            var pageId = pageName;
            var scriptPageName = pageName;
            var scriptPageHash = pageName;
            var scriptPageTitle = pageName;
            var oldHubName = selectedPage?.HubName;
            var sourcePage = mainViewModel.LoadedPages.FirstOrDefault(page => page.Id == Page);
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
            SelectedPage = sourcePage;
            if (SelectedPage?.HubName != oldHubName) 
            {
                MembershipValidation = ValidateValueNotDefault(Membership, "None");
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

                CheckValidation("User", UserNameValidation);
                CheckValidation("Level", MembershipValidation);
                CheckValidation("You", YourNameValidation);
                CheckValidation("Your first name", YourFirstNameValidation);
                CheckValidation("Page:", PageValidation);

                FeatureScript = validationErrors;
                CommentScript = "";
                OriginalPostScript = "";
            }
            else
            {
                var featureScriptTemplate = GetTemplate("feature", pageId, FirstForPage, RawTag, CommunityTag);
                var commentScriptTemplate = GetTemplate("comment", pageId, FirstForPage, RawTag, CommunityTag);
                var originalPostScriptTemplate = GetTemplate("original post", pageId, FirstForPage, RawTag, CommunityTag);
                FeatureScript = featureScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                CommentScript = commentScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                OriginalPostScript = originalPostScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
            }
        }

        private string GetTemplate(
            string templateName,
            string pageName,
            bool firstForPage,
            bool rawTag,
            bool communityTag)
        {
            TemplateEntry? template = null;
            var templatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == pageName);

            // Check first feature and raw and community
            if (selectedPage?.HubName == "snap" && firstForPage && rawTag && communityTag)
            {
                template = templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw community " + templateName);
            }

            // Next check first feature and raw
            if (selectedPage?.HubName == "snap" && firstForPage && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw " + templateName);
            }

            // Next check first feature and community
            if (selectedPage?.HubName == "snap" && firstForPage && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first community " + templateName);
            }

            // Next check first feature
            if (firstForPage)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
            }

            // Next check raw and community
            if (selectedPage?.HubName == "snap" && rawTag && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw community " + templateName);
            }

            // Next check raw
            if (selectedPage?.HubName == "snap" && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw " + templateName);
            }

            // Next check community
            if (selectedPage?.HubName == "snap" && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
            }

            // Last check standard
            template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == templateName);

            return template?.Template ?? "";
        }

        private string GetNewMembershipScriptName(string hubName, string newMembershipLevel)
        {
            if (hubName == "snap")
            {
                return newMembershipLevel switch
                {
                    "Snap Member (feature comment)" => "snap:member feature",
                    "Snap Member (original post comment)" => "snap:member original post",
                    "Snap VIP Member (feature comment)" => "snap:vip member feature",
                    "Snap VIP Member (original post comment)" => "snap:vip member original post",
                    _ => "",
                };
            }
            else if (hubName == "click")
            {
                return newMembershipLevel switch
                {
                    "Click Member" => "click:member",
                    "Click Bronze Member" => "click:bronze_member",
                    "Click Silver Member" => "click:silver_member",
                    "Click Gold Member" => "click:gold_member",
                    "Click Platinum Member" => "click:platinum_member",
                    _ => "",
                };
            }
            return "";
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
                    CheckValidation("User", UserNameValidation);
                }

                NewMembershipScript = validationErrors;
            }
            else
            {
                var hubName = SelectedPage?.HubName;
                var pageName = Page;
                var pageId = pageName;
                var scriptPageName = pageName;
                var scriptPageHash = pageName;
                var scriptPageTitle = pageName;
                var sourcePage = mainViewModel.LoadedPages.FirstOrDefault(page => page.Id == Page);
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
                if (!string.IsNullOrEmpty(hubName))
                {
                    var templateName = GetNewMembershipScriptName(hubName, NewMembership);
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == templateName);
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                        .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
                else if (NewMembership == "Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                        .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
                else if (NewMembership == "VIP Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                        .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
            }
        }

        #endregion

        #region Clipboard management

        private void CopyTextToClipboard(string text, string successMessage)
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

        public void CopyScript(Script script, bool force = false, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                var unprocessedScript = Scripts[script];
                CopyTextToClipboard(unprocessedScript, "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else if (CheckForPlaceholders(script, force))
            {
                var editor = new PlaceholderEditor(this, script)
                {
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner,
                };
                editor.ShowDialog();
            }
            else
            {
                var processedScript = ProcessPlaceholders(script);
                TransferPlaceholders(script);
                CopyTextToClipboard(processedScript, "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        public void CopyNewMembershipScript()
        {
            CopyTextToClipboard(NewMembershipScript, "Copied the new membership script to the clipboard");
        }

        public void CopyScriptFromPlaceholders(Script script, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                CopyTextToClipboard(Scripts[script], "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else
            {
                TransferPlaceholders(script);
                CopyTextToClipboard(ProcessPlaceholders(script), "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        #endregion

        [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
        private static partial Regex PlaceholderRegex();

        [GeneratedRegex("\\[\\{([^\\}]*)\\}\\]")]
        private static partial Regex LongPlaceholderRegex();
    }
}
