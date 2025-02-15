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
        public Brush? WarningBrush { get; set; }
        public Brush? InvalidBrush { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var brushName = "MahApps.Brushes.Text";
            var defaultBrush = SystemColors.ControlTextBrush;
            if (value is ValidationResult validationResult)
            {
                switch (validationResult.Type)
                {
                    case ValidationResultType.Error:
                        brushName = (InvalidBrush != null) ? "- force -" : "MahApps.Brushes.Control.Validation";
                        defaultBrush = (InvalidBrush != null) ? (SolidColorBrush)InvalidBrush : new SolidColorBrush(Colors.Red);
                        break;
                    case ValidationResultType.Warning:
                        brushName = (WarningBrush != null) ? "- force -" : "MahApps.Brushes.Control.Warning";
                        defaultBrush = (WarningBrush != null) ? (SolidColorBrush)WarningBrush : new SolidColorBrush(Colors.Orange);
                        break;
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
            bool inverted = false;
            if (parameter is bool isInverted)
            {
                inverted = isInverted;
            }
            var validationResult = value as ValidationResult?;
            if (validationResult == null || !(validationResult?.IsValid ?? false))
            {
                return inverted ? Visibility.Collapsed : Visibility.Visible;
            }
            return inverted ? Visibility.Visible : Visibility.Collapsed;
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
