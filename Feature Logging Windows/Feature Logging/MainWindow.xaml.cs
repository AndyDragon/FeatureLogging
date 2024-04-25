using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;

namespace FeatureLogging
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void OnActivatedChanged(object sender, EventArgs e)
        {
            if (this.DataContext is MainViewModel viewModel)
            {
                viewModel.WindowActive = IsActive;
            }
        }

        private void OnClosing(object sender, CancelEventArgs e)
        {
            if (this.DataContext is MainViewModel viewModel && viewModel.IsDirty)
            {
                e.Cancel = true;
                viewModel.HandleDirtyAction("closing the app", (completed) =>
                {
                    viewModel.IsDirty = false;
                    e.Cancel = false;
                });
            }
        }

        private void Exit_Clicked(object sender, RoutedEventArgs e)
        {
            Close();
        }

        private void MenuItem_SubmenuOpened(object sender, RoutedEventArgs e)
        {
            if (sender is MenuItem menuItem)
            {
                foreach (var childItem in menuItem.Items)
                {
                    if (childItem is MenuItem childMenuItem)
                    {
                        childMenuItem.GetBindingExpression(MenuItem.HeaderProperty)?.UpdateTarget();
                        childMenuItem.GetBindingExpression(MenuItem.CommandProperty)?.UpdateTarget();
                    }
                }
            }
        }
    }
}