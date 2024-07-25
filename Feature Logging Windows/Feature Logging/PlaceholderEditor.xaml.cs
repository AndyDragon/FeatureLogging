using MahApps.Metro.Controls;
using System.Windows;

namespace FeatureLogging
{
    /// <summary>
    /// Interaction logic for PlaceholderEditor.xaml
    /// </summary>
    public partial class PlaceholderEditor : MetroWindow
    {
        private readonly Script script;

        public PlaceholderEditor(ScriptsViewModel viewModel, Script script)
        {
            InitializeComponent();
            this.DataContext = new PlaceholdersViewModel(viewModel, script);
            this.script = script;
        }

        private void OnCopyClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                viewModel.ScriptsViewModel.CopyScriptFromPlaceholders(script);
            }
            DialogResult = true;
            Close();
        }

        private void OnCopyUnchangedClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                viewModel.ScriptsViewModel.CopyScriptFromPlaceholders(script, withPlaceholders: true);
            }
            DialogResult = true;
            Close();
        }
    }
}
