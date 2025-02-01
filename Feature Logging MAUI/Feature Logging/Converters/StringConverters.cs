using System.Globalization;

namespace FeatureLogging.Converters;

public class StringJoinConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        switch (value)
        {
            case string[] stringsValue when parameter is string stringParameter:
            {
                switch (stringParameter)
                {
                    case "bullets" when stringsValue.Length != 0:
                        return "● " + string.Join("\n● ", stringsValue);
                    case "bullets":
                        return "";
                    case "newline":
                        stringParameter = "\n";
                        break;
                }

                return string.Join(stringParameter, stringsValue);
            }
            case string[] stringsValue:
                return string.Join(", ", stringsValue);
            case IEnumerable<string> enumerableStringsValue when parameter is string stringParameter:
            {
                switch (stringParameter)
                {
                    case "bullets" when enumerableStringsValue.Any():
                        return "● " + string.Join("\n● ", enumerableStringsValue);
                    case "bullets":
                        return "";
                    case "newline":
                        stringParameter = "\n";
                        break;
                }

                return string.Join(stringParameter, enumerableStringsValue);
            }
            case IEnumerable<string> enumerableStringsValue:
                return string.Join(", ", enumerableStringsValue);
            default:
                return value;
        }
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
