using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class Scripts : IThemePage
{
    public Scripts(MainViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }

    public void UpdateTheme(AppTheme theme)
    {
    }
}