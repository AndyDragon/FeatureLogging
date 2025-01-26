using MauiIcons.Material;

namespace FeatureLogging.ViewModels;

public struct VerdictResult(string message, Color color, MaterialIcons icon) : IEquatable<VerdictResult>
{
    public string Message { get; } = message;

    public Brush Color { get; private set; } = new SolidColorBrush(color);

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
        if (obj is VerdictResult)
        {
            var objAsVerdictResult = obj as VerdictResult?;
            return this == objAsVerdictResult;
        }
        return false;
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
