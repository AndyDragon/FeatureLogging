using System.Windows.Data;
using System.Windows.Media;

namespace FeatureLogging
{
    class ScriptLengthToVisibility : IValueConverter
    {
        public object? Convert(object? value, Type targetType, object? parameter, System.Globalization.CultureInfo culture)
        {
            if (value is int length)
            {
                if (length >= 975)
                {
                    return System.Windows.Visibility.Visible;
                }
                return System.Windows.Visibility.Collapsed;
            }
            return null;
        }

        public object? ConvertBack(object? value, Type targetType, object? parameter, System.Globalization.CultureInfo culture)
        {
            return null;
        }
    }

    class ScriptLengthToColor : IValueConverter
    {
        public object? Convert(object? value, Type targetType, object? parameter, System.Globalization.CultureInfo culture)
        {
            if (value is int length)
            {
                if (length > 1000)
                {
                    return Brushes.Red;
                }
                if (length >= 990)
                {
                    return Brushes.Orange;
                }
                return Brushes.Green;
            }
            return null;
        }

        public object? ConvertBack(object? value, Type targetType, object? parameter, System.Globalization.CultureInfo culture)
        {
            return null;
        }
    }
}
