namespace FeatureLogging.ViewModels;

public static class Validation
{
    private static Dictionary<string, List<string>> disallowList = [];

    public static Dictionary<string, List<string>> DisallowList
    {
        get => disallowList;
        set => disallowList = value;
    }

    #region Field validation

    public static ValidationResult ValidateUser(string hubName, string userName, ValidationLevel failLevel = ValidationLevel.Error)
    {
        var userNameValidationResult = ValidateUserName(userName);
        if (!userNameValidationResult.Valid)
        {
            return userNameValidationResult;
        }
        if (DisallowList.TryGetValue(hubName, out List<string>? value) &&
            value.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null)
        {
            return new ValidationResult(failLevel, "User is on the disallow list");
        }
        return new ValidationResult();
    }

    public static ValidationResult ValidateValueNotEmpty(string value, ValidationLevel failLevel = ValidationLevel.Error)
    {
        if (string.IsNullOrEmpty(value))
        {
            return new ValidationResult(failLevel, "Required value");
        }
        return new ValidationResult();
    }

    public static ValidationResult ValidateValueNotDefault(string value, string defaultValue, ValidationLevel failLevel = ValidationLevel.Error)
    {
        if (string.IsNullOrEmpty(value) || string.Equals(value, defaultValue, StringComparison.OrdinalIgnoreCase))
        {
            return new ValidationResult(failLevel, "Required value");
        }
        return new ValidationResult();
    }

    public static ValidationResult ValidateUserName(string userName, ValidationLevel failLevel = ValidationLevel.Error)
    {
        if (string.IsNullOrEmpty(userName))
        {
            return new ValidationResult(failLevel, "Required value");
        }
        if (userName.StartsWith('@'))
        {
            return new ValidationResult(failLevel, "Don't include the '@' in user names");
        }
        if (userName.Length <= 1)
        {
            return new ValidationResult(failLevel, "User name should be more than 1 character long");
        }
        return new ValidationResult();
    }

    internal static ValidationResult ValidateValueNotEmptyAndContainsNoNewlines(string value, ValidationLevel failLevel = ValidationLevel.Error)
    {
        if (string.IsNullOrEmpty(value))
        {
            return new ValidationResult(failLevel, "Required value");
        }
        if (value.Contains('\n'))
        {
            return new ValidationResult(failLevel, "Value cannot contain newline");
        }
        if (value.Contains('\r'))
        {
            return new ValidationResult(failLevel, "Value cannot contain newline");
        }
        return new ValidationResult();
    }

    internal static ValidationResult ValidateUserProfileUrl(string userProfileUrl, ValidationLevel failLevel = ValidationLevel.Error)
    {
        if (string.IsNullOrEmpty(userProfileUrl))
        {
            return new ValidationResult(failLevel, "Missing the user profile URL");
        }
        if (!userProfileUrl.StartsWith("https://vero.co/"))
        {
            return new ValidationResult(failLevel, "User profile URL does not point to VERO");
        }
        return new ValidationResult();
    }
    #endregion
}
