using System.Collections.ObjectModel;
using System.Text.RegularExpressions;
using CommunityToolkit.Maui.Alerts;
using FeatureLogging.Base;
using FeatureLogging.Models;
using FeatureLogging.Views;

namespace FeatureLogging.ViewModels;

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
                UpdateForFeature();
            }
        }
    }

    public void UpdateForFeature()
    {
        OnPropertyChanged(nameof(IsFirstFeature));
        OnPropertyChanged(nameof(FromRawTag));
        OnPropertyChanged(nameof(FromCommunityTag));
        
        UpdateScripts();
        UpdateNewMembershipScripts();
        ClearAllPlaceholders();
        
        if (Feature != null)
        {
            switch (mainViewModel.SelectedPage?.HubName)
            {
                case "snap":
                    switch (Feature.UserHasFeaturesOnHub)
                    {
                        case true:
                        {
                            var featureCount = GetHubFeatureCount("snap", Feature);
                            NewMembership = (featureCount + 1) switch
                            {
                                5 => "Snap Member (feature comment)",
                                15 => "Snap VIP Member (feature comment)",
                                _ => "None",
                            };
                            break;
                        }
                        default:
                            NewMembership = "None";
                            break;
                    }
                    break;
                        
                case "click":
                    switch (Feature.UserHasFeaturesOnHub)
                    {
                        case true:
                        {
                            var featureCount = GetHubFeatureCount("click", Feature);
                            NewMembership = (featureCount + 1) switch
                            {
                                5 => "Click Member",
                                15 => "Click Bronze Member",
                                30 => "Click Silver Member",
                                50 => "Click Gold Member",
                                75 => "Click Platinum Member",
                                _ => "None",
                            };
                            break;
                        }
                        default:
                            NewMembership = "None";
                            break;
                    }
                    break;
            }
        }
        else
        {
            NewMembership = "None";
        }
    }

    private static int GetHubFeatureCount(string hubName, Feature feature)
    {
        switch (hubName)
        {
            case "snap":
            {
                switch (feature)
                {
                    case { UserHasFeaturesOnHub: true, FeatureCountOnHub: "many" }:
                    case { UserHasFeaturesOnHub: true, FeatureCountOnRawHub: "many" }:
                        return int.MaxValue;
                }

                var featureCountOnHub = feature.UserHasFeaturesOnHub ? int.Parse(feature.FeatureCountOnHub) : 0;
                var featureCountOnRawHub = feature.UserHasFeaturesOnHub ? int.Parse(feature.FeatureCountOnRawHub) : 0;
                return featureCountOnHub + featureCountOnRawHub;
            }
            default:
            {
                if (feature is { UserHasFeaturesOnHub: true, FeatureCountOnHub: "many" })
                {
                    return int.MaxValue;
                }
                var featureCountOnHub = feature.UserHasFeaturesOnHub ? int.Parse(feature.FeatureCountOnHub) : 0;
                return featureCountOnHub;
            }
        }
    }

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

    private Dictionary<Script, string> Scripts { get; } = new()
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

    public bool FeatureScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Feature);

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

    public bool CommentScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Comment);

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

    public bool OriginalPostScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.OriginalPost);

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

    public bool IsFirstFeature => !(Feature?.UserHasFeaturesOnPage ?? false);
    public bool FromRawTag => mainViewModel.FromRawTag(Feature?.TagSource ?? "");
    public bool FromCommunityTag => mainViewModel.FromCommunityTag(Feature?.TagSource ?? "");

    public void ClearAllPlaceholders()
    {
        PlaceholdersMap[Script.Feature].Clear();
        PlaceholdersMap[Script.Comment].Clear();
        PlaceholdersMap[Script.OriginalPost].Clear();
        LongPlaceholdersMap[Script.Feature].Clear();
        LongPlaceholdersMap[Script.Comment].Clear();
        LongPlaceholdersMap[Script.OriginalPost].Clear();
    }

    private bool ScriptHasPlaceholder(Script script)
    {
        return PlaceholderRegex().Matches(Scripts[script]).Count != 0 || LongPlaceholderRegex().Matches(Scripts[script]).Count != 0;
    }

    private bool CheckForPlaceholders(Script script, bool force = false)
    {
        var needEditor = false;

        var matches = PlaceholderRegex().Matches(Scripts[script]);
        var placeholders = matches.Select(match => match.Captures.First().Value.Trim('[', ']')).ToList();
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

        var longMatches = LongPlaceholderRegex().Matches(Scripts[script]);
        var longPlaceholders = longMatches.Select(match => match.Captures.First().Value.Trim('[', '{', '}', ']')).ToList();
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

    private void TransferPlaceholders(Script script)
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

    private string ProcessPlaceholders(Script script)
    {
        var result = Scripts[script];
        result = PlaceholdersMap[script].Aggregate(result, (current, placeholder) => current.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim()));
        return LongPlaceholdersMap[script].Aggregate(result, (current, longPlaceholder) => current.Replace("[{" + longPlaceholder.Name + "}]", longPlaceholder.Value.Trim()));
    }

    #endregion

    #region Script management

    public bool CanCopyScripts =>
        Feature is { UserAliasValidation.Valid: true, UserLevelValidation.Valid: true } &&
        mainViewModel.YourAliasValidation.Valid &&
        mainViewModel.YourFirstNameValidation.Valid &&
        mainViewModel.PageValidation.Valid;

    public bool CanCopyNewMembershipScript =>
        NewMembership != "None" &&
        Feature is { UserAliasValidation.Valid: true, UserLevelValidation.Valid: true } &&
        mainViewModel.YourAliasValidation.Valid &&
        mainViewModel.YourFirstNameValidation.Valid &&
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
                    validationErrors += prefix + ": " + (result.Message ?? "unknown") + "\n";
                }
            }

            CheckValidation("User", Feature?.UserAliasValidation ?? new ValidationResult(ValidationLevel.Error));
            CheckValidation("Level", Feature?.UserLevelValidation ?? new ValidationResult(ValidationLevel.Error));
            CheckValidation("You", mainViewModel.YourAliasValidation);
            CheckValidation("Your first name", mainViewModel.YourFirstNameValidation);
            CheckValidation("Page:", mainViewModel.PageValidation);

            FeatureScript = validationErrors;
            CommentScript = "";
            OriginalPostScript = "";
        }
        else
        {
            string PrepareTemplate(string template)
            {
                return template
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                    .Replace("%%USERNAME%%", Feature!.UserAlias)
                    .Replace("%%YOURNAME%%", mainViewModel.YourAlias)
                    .Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                    .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
            }

            FeatureScript = PrepareTemplate(GetTemplate("feature", pageId));
            CommentScript = PrepareTemplate(GetTemplate("comment", pageId));
            OriginalPostScript = PrepareTemplate(GetTemplate("original post", pageId));
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
                    validationErrors += prefix + ": " + (result.Message ?? "unknown") + "\n";
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

            void PrepareTemplate(TemplateEntry? templateEntry)
            {
                NewMembershipScript = (templateEntry?.Template ?? "")
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", Feature!.UserLevel)
                    .Replace("%%USERNAME%%", Feature!.UserAlias)
                    .Replace("%%YOURNAME%%", mainViewModel.YourAlias)
                    .Replace("%%YOURFIRSTNAME%%", mainViewModel.YourFirstName)
                    .Replace("%%STAFFLEVEL%%", mainViewModel.StaffLevel);
            }

            if (!string.IsNullOrEmpty(hubName))
            {
                var templateName = GetNewMembershipScriptName(hubName, NewMembership);
                PrepareTemplate(TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == templateName));
            }
            else if (NewMembership == "Member")
            {
                PrepareTemplate(TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member"));
            }
            else if (NewMembership == "VIP Member")
            {
                PrepareTemplate(TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member"));
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
            var editor = new PlaceholderEditor(this, script);
            mainViewModel.MainWindow?.Navigation.PushAsync(editor);
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

    public void PopView()
    {
        _ = mainViewModel.MainWindow?.Navigation.PopAsync();
    }

    [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
    private static partial Regex PlaceholderRegex();

    [GeneratedRegex("\\[\\{([^\\}]*)\\}\\]")]
    private static partial Regex LongPlaceholderRegex();
}
