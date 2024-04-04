using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace FeatureLogging
{
    public class ValueVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (!bool.TryParse(parameter as string, out bool positiveValue))
            {
                positiveValue = true;
            }
            if (value is string stringValue)
            {
                return string.IsNullOrEmpty(stringValue) != positiveValue ? Visibility.Visible : Visibility.Collapsed;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
