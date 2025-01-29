using MauiIcons.Material;
using Newtonsoft.Json;
using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Models;

public class Feature : NotifyPropertyChanged
{
    [JsonIgnore]
    public readonly string Id = Guid.NewGuid().ToString();

    [JsonIgnore]
    public bool IsPickedAndAllowed => IsPicked && !TooSoonToFeatureUser && !PhotoFeaturedOnPage && TinEyeResults != "matches found" && AiCheckResults != "ai";

    [JsonIgnore]
    public string SortKey => FeatureComparer.CreateSortingKey(this);

    [JsonIgnore]
    private bool isDirty;
    [JsonIgnore]
    public bool IsDirty
    {
        get => isDirty;
        set => Set(ref isDirty, value);
    }

    private bool isPicked;
    [JsonProperty(PropertyName = "isPicked")]
    public bool IsPicked
    {
        get => isPicked;
        set => SetWithDirtyCallback(ref isPicked, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(SortKey)]);
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

    private bool userIsTeammate;
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

    private bool photoFeaturedOnPage;
    [JsonProperty(PropertyName = "photoFeaturedOnPage")]
    public bool PhotoFeaturedOnPage
    {
        get => photoFeaturedOnPage;
        set => SetWithDirtyCallback(ref photoFeaturedOnPage, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(SortKey)]);
    }

    private bool photoFeaturedOnHub;
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
    public ValidationResult PhotoLastFeaturedOnHubValidation => Validation.ValidateValuesNotEmpty([photoLastFeaturedOnHub, PhotoLastFeaturedPage], ValidationLevel.Warning);

    private string photoLastFeaturedPage = "";
    [JsonProperty(PropertyName = "photoLastFeaturedPage")]
    public string PhotoLastFeaturedPage
    {
        get => photoLastFeaturedPage;
        set => SetWithDirtyCallback(ref photoLastFeaturedPage, value, () => IsDirty = true, [nameof(PhotoLastFeaturedOnHubValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
    }

    private string featureDescription = "";
    [JsonProperty(PropertyName = "featureDescription")]
    public string FeatureDescription
    {
        get => featureDescription;
        set => SetWithDirtyCallback(ref featureDescription, value, () => IsDirty = true, [nameof(FeatureDescriptionValidation)]);
    }
    public ValidationResult FeatureDescriptionValidation => Validation.ValidateValueNotEmpty(featureDescription, ValidationLevel.Warning);

    private bool userHasFeaturesOnPage;
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
    public ValidationResult LastFeaturedOnPageValidation => Validation.ValidateValueNotEmpty(lastFeaturedOnPage, ValidationLevel.Warning);

    private string featureCountOnPage = "many";
    [JsonProperty(PropertyName = "featureCountOnPage")]
    public string FeatureCountOnPage
    {
        get => featureCountOnPage;
        set => SetWithDirtyCallback(ref featureCountOnPage, value, () => IsDirty = true);
    }

    private string featureCountOnRawPage = "0";
    [JsonProperty(PropertyName = "featureCountOnRawPage")]
    public string FeatureCountOnRawPage
    {
        get => featureCountOnRawPage;
        set => SetWithDirtyCallback(ref featureCountOnRawPage, value, () => IsDirty = true);
    }

    private bool userHasFeaturesOnHub;
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
    public ValidationResult LastFeaturedOnHubValidation => Validation.ValidateValuesNotEmpty([lastFeaturedOnHub, lastFeaturedPage], ValidationLevel.Warning);

    private string lastFeaturedPage = "";
    [JsonProperty(PropertyName = "lastFeaturedPage")]
    public string LastFeaturedPage
    {
        get => lastFeaturedPage;
        set => SetWithDirtyCallback(ref lastFeaturedPage, value, () => IsDirty = true, [nameof(LastFeaturedOnHubValidation), nameof(HasValidationErrors), nameof(ValidationErrorSummary)]);
    }

    private string featureCountOnHub = "many";
    [JsonProperty(PropertyName = "featureCountOnHub")]
    public string FeatureCountOnHub
    {
        get => featureCountOnHub;
        set => SetWithDirtyCallback(ref featureCountOnHub, value, () => IsDirty = true);
    }

    private string featureCountOnRawHub = "0";
    [JsonProperty(PropertyName = "featureCountOnRawHub")]
    public string FeatureCountOnRawHub
    {
        get => featureCountOnRawHub;
        set => SetWithDirtyCallback(ref featureCountOnRawHub, value, () => IsDirty = true);
    }

    private bool tooSoonToFeatureUser;
    [JsonProperty(PropertyName = "tooSoonToFeatureUser")]
    public bool TooSoonToFeatureUser
    {
        get => tooSoonToFeatureUser;
        set => SetWithDirtyCallback(ref tooSoonToFeatureUser, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(SortKey), nameof(LastFeaturedOnHubValidation)]);
    }

    private string tinEyeResults = "0 matches";
    [JsonProperty(PropertyName = "tinEyeResults")]
    public string TinEyeResults
    {
        get => tinEyeResults;
        set => SetWithDirtyCallback(ref tinEyeResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(SortKey)]);
    }

    private string aiCheckResults = "human";
    [JsonProperty(PropertyName = "aiCheckResults")]
    public string AiCheckResults
    {
        get => aiCheckResults;
        set => SetWithDirtyCallback(ref aiCheckResults, value, () => IsDirty = true, [nameof(Icon), nameof(IconColor), nameof(IsPickedAndAllowed), nameof(SortKey)]);
    }

    private string personalMessage = "";
    [JsonProperty(PropertyName = "personalMessage")]
    public string PersonalMessage
    {
        get => personalMessage;
        set => SetWithDirtyCallback(ref personalMessage, value, () => IsDirty = true);
    }

    public void OnSortKeyChange()
    {
        OnPropertyChanged(nameof(SortKey));
    }

    [JsonIgnore]
    public MaterialIcons Icon
    {
        get
        {
            if (PhotoFeaturedOnPage)
            {
                return MaterialIcons.Warning;
            }
            if (TooSoonToFeatureUser)
            {
                return MaterialIcons.Timer;
            }
            if (TinEyeResults == "matches found")
            {
                return MaterialIcons.Shield;
            }
            if (AiCheckResults == "ai")
            {
                return MaterialIcons.Shield;
            }
            if (IsPicked)
            {
                return MaterialIcons.Star;
            }
            return MaterialIcons.Close;
        }
    }

    [JsonIgnore]
    public Color IconColor
    {
        get
        {
            if (PhotoFeaturedOnPage)
            {
                return Colors.Red;
            }
            if (TooSoonToFeatureUser)
            {
                return Colors.Red;
            }
            if (TinEyeResults == "matches found")
            {
                return Colors.Red;
            }
            if (AiCheckResults == "ai")
            {
                return Colors.Red;
            }
            if (IsPicked)
            {
                return Colors.Lime;
            }
            return Colors.Transparent;
        }
    }

    [JsonIgnore]
    public bool HasValidationErrors =>
        !PostLinkValidation.Valid ||
        !UserNameValidation.Valid ||
        !UserAliasValidation.Valid ||
        !UserLevelValidation.Valid ||
        (PhotoFeaturedOnHub && !PhotoLastFeaturedOnHubValidation.Valid) ||
        (UserHasFeaturesOnPage && !LastFeaturedOnPageValidation.Valid) ||
        (UserHasFeaturesOnHub && (!LastFeaturedOnHubValidation.Valid));

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
            }
            return string.Join(",", validationErrors);
        }
    }

    [JsonIgnore]
    public SimpleCommand PickFeatureCommand => new(() =>
    {
        IsPicked = !IsPicked;
    });
    
    [JsonIgnore]
    public SimpleCommandWithParameter EditPersonalMessageCommand => new(parameter =>
    {
        if (parameter is MainViewModel vm && vm.SelectedPage != null)
        {
            vm.SelectedFeature = this;
            // PersonalMessageDialog dialog = new()
            // {
            //     DataContext = vm,
            //     Owner = Application.Current.MainWindow,
            //     WindowStartupLocation = WindowStartupLocation.CenterOwner,
            // };
            // dialog.ShowDialog();
        }
    });

    private static void AddValidationError(List<string> validationErrors, ValidationResult result, string validation)
    {
        if (!result.Valid)
        {
            validationErrors.Add(validation + ": " + (result.Message ?? result.Error ?? "unknown validation error"));
        }
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

        // Use pre-calculated sort key.
        // ReSharper disable once StringCompareIsCultureSpecific.1
        return string.Compare(x.SortKey, y.SortKey);
    }

    public static readonly FeatureComparer Default = new();

    public static string CreateSortingKey(Feature feature)
    {
        var key = "";

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
