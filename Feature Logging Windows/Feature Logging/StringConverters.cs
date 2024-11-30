using System.Globalization;
using System.Windows.Data;

namespace FeatureLogging
{
    public class StringJoinConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is string[] stringsValue)
            {
                if (parameter is string stringParameter)
                {
                    if (stringParameter == "bullets")
                    {
                        if (stringsValue.Length != 0)
                        {
                            return "● " + string.Join("\n● ", stringsValue);
                        }
                        return "";
                    }
                    if (stringParameter == "newline")
                    {
                        stringParameter = "\n";
                    }
                    return string.Join(stringParameter, stringsValue);
                }
                return string.Join(", ", stringsValue);
            }
            if (value is IEnumerable<string> enumerableStringsValue)
            {
                if (parameter is string stringParameter)
                {
                    if (stringParameter == "bullets")
                    {
                        if (enumerableStringsValue.Any())
                        {
                            return "● " + string.Join("\n● ", enumerableStringsValue);
                        }
                        return "";
                    }
                    if (stringParameter == "newline")
                    {
                        stringParameter = "\n";
                    }
                    return string.Join(stringParameter, enumerableStringsValue);
                }
                return string.Join(", ", enumerableStringsValue);
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
