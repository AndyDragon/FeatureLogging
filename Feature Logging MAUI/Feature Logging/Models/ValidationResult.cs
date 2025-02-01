namespace FeatureLogging.Models;

public enum ValidationLevel
{
    Valid,
    Warning,
    Error,
}

public readonly struct ValidationResult(ValidationLevel level = ValidationLevel.Valid, string? message = null) : IEquatable<ValidationResult>
{
    public bool Valid => Level == ValidationLevel.Valid;

    public ValidationLevel Level { get; } = level;

    public string? Message { get; } = message;

    public static bool operator ==(ValidationResult x, ValidationResult y)
    {
        return x.Level == y.Level && x.Message == y.Message;
    }

    public static bool operator !=(ValidationResult x, ValidationResult y)
    {
        return !(x == y);
    }

    public override bool Equals(object? obj)
    {
        return obj is ValidationResult other && this == other;
    }

    public override int GetHashCode()
    {
        return Level.GetHashCode() + (Message ?? "").GetHashCode();
    }

    public bool Equals(ValidationResult other)
    {
        return this == other;
    }
}
