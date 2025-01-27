namespace FeatureLogging.Models;

public enum ValidationLevel
{
    Valid,
    Warning,
    Error,
}

public struct ValidationResult(ValidationLevel level = ValidationLevel.Valid, string? error = null, string? message = null)
{
    public readonly bool Valid => Level == ValidationLevel.Valid;

    public ValidationLevel Level { get; private set; } = level;

    public string? Error { get; private set; } = error;

    public string? Message { get; private set; } = message;

    public static bool operator ==(ValidationResult x, ValidationResult y)
    {
        var xPrime = x;
        var yPrime = y;
        if (xPrime.Level == yPrime.Level)
        {
            if (xPrime.Level == ValidationLevel.Valid)
            {
                return xPrime.Message == yPrime.Message;
            }
            return xPrime.Error == yPrime.Error && xPrime.Message == yPrime.Message;
        }
        return false;
    }

    public static bool operator !=(ValidationResult x, ValidationResult y)
    {
        return !(x == y);
    }

    public readonly override bool Equals(object? obj)
    {
        if (obj is ValidationResult)
        {
            var objAsValidationResult = obj as ValidationResult?;
            return this == objAsValidationResult;
        }
        return false;
    }

    public readonly override int GetHashCode()
    {
        return Level.GetHashCode() + (Error ?? "").GetHashCode() + (Message ?? "").GetHashCode();
    }
}
