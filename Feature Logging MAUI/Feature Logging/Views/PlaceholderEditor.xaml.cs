using FeatureLogging.Base;
using FeatureLogging.ViewModels;

namespace FeatureLogging.Views;

public partial class PlaceholderEditor : IThemePage
{
    private readonly Script script;
    
    public PlaceholderEditor(ScriptsViewModel viewModel, Script script)
    {
        InitializeComponent();
        BindingContext = new PlaceholdersViewModel(viewModel, script);
        this.script = script;
    }

    private void OnCopyClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ScriptsViewModel.CopyScriptFromPlaceholders(script);
            viewModel.ScriptsViewModel.PopView();
        }
    }

    private void OnCopyUnchangedClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ScriptsViewModel.CopyScriptFromPlaceholders(script, withPlaceholders: true);
            viewModel.ScriptsViewModel.PopView();
        }
    }

    private void OnCancelClicked(object sender, EventArgs e)
    {
        if (BindingContext is PlaceholdersViewModel viewModel)
        {
            viewModel.ScriptsViewModel.PopView();
        }
    }

    public void UpdateTheme(AppTheme theme)
    {
    }
}
