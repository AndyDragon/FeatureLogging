using ControlzEx.Theming;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace FeatureLogging
{
    public class BooleanToFontWeightConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return boolValue 
                    ? FontWeights.Bold 
                    : FontWeights.Normal;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToAccentColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return boolValue
                    ? ThemeManager.Current.DetectTheme(Application.Current)?.Resources["MahApps.Brushes.Accent"] as Brush ?? SystemColors.ControlTextBrush
                    : ThemeManager.Current.DetectTheme(Application.Current)?.Resources["MahApps.Brushes.Text"] as Brush ?? SystemColors.ControlTextBrush;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToIndicatorColorConverter : IValueConverter
    {
        public Brush? ZeroBrush { get; set; }
        public Brush? ValueBrush { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return boolValue
                    ? ValueBrush ?? Brushes.LimeGreen
                    : ZeroBrush ?? Brushes.White;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToIndicatorOpacityConverter : IValueConverter
    {
        public double? ZeroOpacity { get; set; }
        public double? ValueOpacity { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue)
            {
                return boolValue
                    ? ValueOpacity ?? 1.0
                    : ZeroOpacity ?? 0.2;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class BooleanToBorderColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var color = ThemeManager.Current.DetectTheme(Application.Current)?.Resources["MahApps.Colors.Accent"];
            var trueBrush = new SolidColorBrush(color != null ? (Color)color : SystemColors.ActiveBorderColor)
            {
                Opacity = 0.2
            };
            if (value is bool boolValue)
            {
                return boolValue
                    ? trueBrush
                    : Brushes.Transparent;
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
