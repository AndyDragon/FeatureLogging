namespace FeatureLogging.Models;

public enum ValidationLevel
{
    Valid,
    Warning,
    Error,
}

public readonly struct ValidationResult(ValidationLevel level = ValidationLevel.Valid, string? error = null, string? message = null) : IEquatable<ValidationResult>
{
    public bool Valid => Level == ValidationLevel.Valid;

    public ValidationLevel Level { get; } = level;

    public string? Error { get; } = error;

    public string? Message { get; } = message;

    public static bool operator ==(ValidationResult x, ValidationResult y)
    {
        if (x.Level == y.Level)
        {
            if (x.Level == ValidationLevel.Valid)
            {
                return x.Message == y.Message;
            }
            return x.Error == y.Error && x.Message == y.Message;
        }
        return false;
    }

    public static bool operator !=(ValidationResult x, ValidationResult y)
    {
        return !(x == y);
    }

    public override bool Equals(object? obj)
    {
        if (obj is ValidationResult)
        {
            var objAsValidationResult = obj as ValidationResult?;
            return this == objAsValidationResult;
        }
        return false;
    }

    public override int GetHashCode()
    {
        return Level.GetHashCode() + (Error ?? "").GetHashCode() + (Message ?? "").GetHashCode();
    }

    public bool Equals(ValidationResult other)
    {
        return Level == other.Level && Error == other.Error && Message == other.Message;
    }
}
