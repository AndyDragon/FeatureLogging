using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class PersonalMessage : IThemePage
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

    public void UpdateTheme(AppTheme theme)
    {
    }
}
