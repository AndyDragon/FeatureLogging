namespace FeatureLogging.Models;

public static class Validation
{
    public static Dictionary<string, List<string>> DisallowList { get; set; } = [];

    #region Field validation

    public static ValidationResult ValidateUser(string hubName, string userName, ValidationLevel failLevel = ValidationLevel.Error)
    {
        var userNameValidationResult = ValidateUserName(userName);
        return !userNameValidationResult.Valid
            ? userNameValidationResult
            : DisallowList.TryGetValue(hubName, out var value) &&
              value.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null
                ? new ValidationResult(failLevel, "User is on the disallow list")
                : new ValidationResult();
    }

    public static ValidationResult ValidateValueNotEmpty(string value, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return string.IsNullOrEmpty(value) 
            ? new ValidationResult(failLevel, "Required value") 
            : new ValidationResult();
    }

    public static ValidationResult ValidateValuesNotEmpty(string[] values, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return values.Any(string.IsNullOrEmpty) 
            ? new ValidationResult(failLevel, "Required values") 
            : new ValidationResult();
    }

    public static ValidationResult ValidateValueNotDefault(string value, string defaultValue, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return string.IsNullOrEmpty(value) || string.Equals(value, defaultValue, StringComparison.OrdinalIgnoreCase)
            ? new ValidationResult(failLevel, "Required value")
            : new ValidationResult();
    }

    public static ValidationResult ValidateUserName(string userName, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return string.IsNullOrEmpty(userName)
            ? new ValidationResult(failLevel, "Required value")
            : userName.StartsWith('@')
                ? new ValidationResult(failLevel, "Don't include the '@' in user names")
                : userName.Length <= 1
                    ? new ValidationResult(failLevel, "User name should be more than 1 character long")
                    : ValidateValueNotEmptyAndContainsNoNewlines(userName, failLevel);
    }

    private static ValidationResult ValidateValueNotEmptyAndContainsNoNewlines(string value, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return string.IsNullOrEmpty(value)
            ? new ValidationResult(failLevel, "Required value")
            : value.Contains('\n')
                ? new ValidationResult(failLevel, "Value cannot contain newline")
                : value.Contains('\r')
                    ? new ValidationResult(failLevel, "Value cannot contain newline")
                    : new ValidationResult();
    }

    internal static ValidationResult ValidateUserProfileUrl(string userProfileUrl, ValidationLevel failLevel = ValidationLevel.Error)
    {
        return string.IsNullOrEmpty(userProfileUrl)
            ? new ValidationResult(failLevel, "Missing the user profile URL")
            : !userProfileUrl.StartsWith("https://vero.co/")
                ? new ValidationResult(failLevel, "User profile URL does not point to VERO")
                : new ValidationResult();
    }
    
    #endregion
}
