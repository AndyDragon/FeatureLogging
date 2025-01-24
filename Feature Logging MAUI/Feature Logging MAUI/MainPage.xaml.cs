using FeatureLogging.ViewModels;
using FeatureLogging.Views;

namespace FeatureLogging
{
    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();
        }

        private async void OnFeatureListItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                await Navigation.PushAsync(new FeatureEditor
                {
                    BindingContext = e.SelectedItem as Feature,
                });
            }
        }

        private void OnContentPageNavigatedTo(object sender, NavigatedToEventArgs e)
        {
            if (BindingContext is MainViewModel vm)
            {
                vm.SelectedFeature = null;
            }
        }
    }
}
