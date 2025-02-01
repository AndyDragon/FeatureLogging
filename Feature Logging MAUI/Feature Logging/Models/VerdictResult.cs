using MauiIcons.Material;

namespace FeatureLogging.Models;

public struct VerdictResult(string message, string details, Color color, MaterialIcons icon) : IEquatable<VerdictResult>
{
    public string Message { get; } = message;

    public string Details { get; } = details;

    public Color Color { get; private set; } = color;

    public MaterialIcons Icon { get; private set; } = icon;

    public static bool operator ==(VerdictResult x, VerdictResult y)
    {
        return x.Message.Equals(y.Message);
    }

    public static bool operator !=(VerdictResult x, VerdictResult y)
    {
        return !(x == y);
    }

    public readonly override bool Equals(object? obj)
    {
        switch (obj)
        {
            case VerdictResult:
            {
                var objAsVerdictResult = obj as VerdictResult?;
                return this == objAsVerdictResult;
            }
            default:
                return false;
        }
    }

    public readonly override int GetHashCode()
    {
        return Message.GetHashCode();
    }

    public bool Equals(VerdictResult other)
    {
        return Message == other.Message;
    }
}
