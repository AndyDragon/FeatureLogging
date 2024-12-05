using System.Globalization;
using System.Windows.Data;
using LiveCharts;

namespace FeatureLogging
{
    public class MinHeightToLegendLocationConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var minHeight = parameter is int ? (int)parameter : 300;
            if (value is double height)
            {
                return (height >= minHeight) ? LegendLocation.Right : LegendLocation.None;
            }
            return LegendLocation.None;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
