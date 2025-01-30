using System.Drawing;
using System.Globalization;
using FeatureLogging.Models;
using Color = Microsoft.Maui.Graphics.Color;

namespace FeatureLogging.Converters
{
    internal class ValidationResultColorConverter : IValueConverter
    {
        public Color? ValidColor { get; set; }
        public Color? WarningColor { get; set; }
        public Color? ErrorColor { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not ValidationResult result)
            {
                return ErrorColor ?? Colors.Red;
            }

            return result.Level switch
            {
                ValidationLevel.Warning => WarningColor ?? Colors.Orange,
                ValidationLevel.Error => ErrorColor ?? Colors.Red,
                _ => ValidColor ?? (Application.Current.RequestedTheme == AppTheme.Dark ? Colors.White : Colors.Black)
            };
        }
        
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    internal class ValidationResultVisibilityConverter : IValueConverter
    {
        public bool? ValidVisibility { get; set; }
        public bool? WarningVisibility { get; set; }
        public bool? ErrorVisibility { get; set; }

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not ValidationResult result)
            {
                return ErrorVisibility ?? true;
            }

            return result.Level switch
            {
                ValidationLevel.Warning => WarningVisibility ?? true,
                ValidationLevel.Error => ErrorVisibility ?? true,
                _ => ValidVisibility ?? false
            };
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
    internal class ValidationBooleanColorConverter : IValueConverter
    {
        public Color? ValidColor { get; set; }
        public Color? ErrorColor { get; set; }
        
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not bool result)
            {
                return ErrorColor ?? Colors.Red;
            }

            return !result 
                ? ErrorColor ?? Colors.Red 
                : ValidColor ?? (Application.Current.RequestedTheme == AppTheme.Dark ? Colors.White : Colors.Black);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
    internal class ValidationBooleanVisibilityConverter : IValueConverter
    {
        public bool? ValidVisibility { get; set; }
        
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is not bool result)
            {
                return !(ValidVisibility ?? true);
            }
            
            return !result && (ValidVisibility ?? true);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
