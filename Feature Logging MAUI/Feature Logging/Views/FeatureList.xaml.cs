using FeatureLogging.ViewModels;
using MauiIcons.Core;

namespace FeatureLogging.Views;

public partial class FeatureList : ContentPage
{
    public FeatureList()
    {
        InitializeComponent();
        // Temporary Workaround for url styled namespace in xaml
        _ = new MauiIcon();
    }

    private void OnBindingContextChanged(object sender, EventArgs e)
    {
        if (BindingContext is MainViewModel vm)
        {
            vm.MainWindow = this;
        }
    }

    private void OnContentPageNavigatedTo(object sender, NavigatedToEventArgs e)
    {
        if (BindingContext is MainViewModel vm)
        {
            // vm.WindowActive = true;
            vm.SelectedFeature = null;
        }
    }

    private void OnContentPageNavigatedFrom(object sender, NavigatedFromEventArgs e)
    {
        if (BindingContext is MainViewModel vm)
        {
            // vm.WindowActive = false;
        }
    }

    internal void ResortList()
    {
        // this.FeaturesListBox.Items.SortDescriptions.Clear();
        // var sortDescription = new SortDescription()
        // {
        //     Direction = ListSortDirection.Ascending,
        //     PropertyName = "SortKey",
        // };
        // this.FeaturesListBox.Items.SortDescriptions.Add(sortDescription);
    }
}
