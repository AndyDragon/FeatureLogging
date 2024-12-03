using MahApps.Metro.IconPacks;
using System.Windows.Media;

namespace FeatureLogging
{
    public struct VerdictResult(string message, Color color, PackIconJamIconsKind icon)
    {
        public string Message { get; private set; } = message;

        public Brush Color { get; private set; } = new SolidColorBrush(color);

        public PackIconJamIconsKind Icon { get; private set; } = icon;

        public static bool operator ==(VerdictResult x, VerdictResult y)
        {
            var xPrime = x;
            var yPrime = y;
            return xPrime.Message.Equals(yPrime.Message);
        }

        public static bool operator !=(VerdictResult x, VerdictResult y)
        {
            return !(x == y);
        }

        public override readonly bool Equals(object? obj)
        {
            if (obj is VerdictResult)
            {
                var objAsVerdictResult = obj as VerdictResult?;
                return this == objAsVerdictResult;
            }
            return false;
        }

        public override readonly int GetHashCode()
        {
            return Message.GetHashCode();
        }
    }
}
