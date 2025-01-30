using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class PersonalMessage : ContentPage
{
    public PersonalMessage(PersonalMessageViewModel viewModel)
    {
        InitializeComponent();
        BindingContext = viewModel;
    }
    
    private void OnCloseButtonClicked(object sender, EventArgs e)
    {
        if (BindingContext is PersonalMessageViewModel viewModel)
        {
            _ = viewModel.MainViewModel.MainWindow!.Navigation.PopAsync();
        }
    }
}
