using System.Globalization;

namespace FeatureLogging.Converters;

public class ScriptLengthToVisible : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int length)
        {
            return length >= 975;
        }
        return null;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return null;
    }
}

public class ScriptLengthToColor : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int length)
        {
            return length switch
            {
                > 1000 => Colors.Red,
                >= 990 => Colors.Orange,
                _ => Colors.Green
            };
        }
        return null;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return null;
    }
}
