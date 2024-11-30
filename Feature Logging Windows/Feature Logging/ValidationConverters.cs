using ControlzEx.Theming;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;

namespace FeatureLogging
{
    class ValidationResultColorConverter : IValueConverter
    {
        public Brush? ValidBrush { get; set; }
        public Brush? InvalidBrush { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var validationResult = value as ValidationResult?;
            var brushName = "MahApps.Brushes.Text";
            var defaultBrush = SystemColors.ControlTextBrush;
            if (validationResult == null || !(validationResult?.Valid ?? false))
            {
                if (InvalidBrush != null)
                {
                    brushName = "- force -";
                    defaultBrush = (SolidColorBrush)InvalidBrush;
                }
                else
                {
                    brushName = "MahApps.Brushes.Control.Validation";
                    defaultBrush = new SolidColorBrush(Colors.Red);
                }
            } 
            else if (ValidBrush != null)
            {
                brushName = "- force -";
                defaultBrush = (SolidColorBrush)ValidBrush;
            }
            return (ThemeManager.Current.DetectTheme(Application.Current)?.Resources[brushName] as Brush) ?? defaultBrush;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationResultVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var validationResult = value as ValidationResult?;
            if (validationResult == null || !(validationResult?.Valid ?? false))
            {
                return Visibility.Visible;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    class ValidationBooleanColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var result = (value as Boolean?) ?? false;
            var brushName = "MahApps.Brushes.Text";
            var defaultBrush = SystemColors.ControlTextBrush;
            if (!result)
            {
                brushName = "MahApps.Brushes.Control.Validation";
                defaultBrush = new SolidColorBrush(Colors.Red);
            }
            return (ThemeManager.Current.DetectTheme(Application.Current)?.Resources[brushName] as Brush) ?? defaultBrush;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
    class ValidationBooleanVisibilityConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var result = (value as Boolean?) ?? false;
            if (!result)
            {
                return Visibility.Visible;
            }
            return Visibility.Collapsed;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
