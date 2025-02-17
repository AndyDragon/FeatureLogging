using System.Globalization;
using System.Windows.Data;
using OxyPlot;
using OxyPlot.Wpf;

namespace FeatureLogging
{
    class OxyColorToBrushConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is OxyColor color)
            {
                return color.ToBrush();
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
