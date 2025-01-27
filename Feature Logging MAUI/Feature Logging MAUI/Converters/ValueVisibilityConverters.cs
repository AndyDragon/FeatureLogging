using System.Globalization;

namespace FeatureLogging.Converters
{
    public class ValueVisibilityConverter : IValueConverter
    {
        public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            if (!bool.TryParse(parameter as string, out var positiveValue))
            {
                positiveValue = true;
            }
            if (value is string stringValue)
            {
                return string.IsNullOrEmpty(stringValue) != positiveValue;
            }
            return value;
        }

        public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
