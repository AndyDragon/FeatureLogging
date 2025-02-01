using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class ImageValidation : IThemePage
{
    public ImageValidation()
    {
        InitializeComponent();
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        if (BindingContext is ImageValidationViewModel vm)
        {
            _ = vm.TriggerLoad();
        }
    }

    public void UpdateTheme(AppTheme theme)
    {
        if (BindingContext is ImageValidationViewModel vm)
        {
            vm.TriggerThemeChange();
        }
    }
}