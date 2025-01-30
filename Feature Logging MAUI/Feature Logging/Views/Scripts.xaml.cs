using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class Scripts : ContentPage
{
    public Scripts(MainViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
}