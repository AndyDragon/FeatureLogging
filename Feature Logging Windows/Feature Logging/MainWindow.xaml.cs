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
            if (WindowState == WindowState.Maximized)
            {
                // Use the RestoreBounds as the current values will be 0, 0 and the size of the screen
                Properties.Settings.Default.Top = RestoreBounds.Top;
                Properties.Settings.Default.Left = RestoreBounds.Left;
                Properties.Settings.Default.Height = RestoreBounds.Height;
                Properties.Settings.Default.Width = RestoreBounds.Width;
                Properties.Settings.Default.Maximized = true;
            }
            else
            {
                Properties.Settings.Default.Top = Top;
                Properties.Settings.Default.Left = Left;
                Properties.Settings.Default.Height = Height;
                Properties.Settings.Default.Width = Width;
                Properties.Settings.Default.Maximized = false;
            }
            Properties.Settings.Default.Save();

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

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if (this.DataContext is MainViewModel viewModel)
            {
                viewModel.MainWindow = this;
            }
        }

        private void OnSourceInitialized(object sender, EventArgs e)
        {
            this.Top = Properties.Settings.Default.Top;
            this.Left = Properties.Settings.Default.Left;
            this.Height = Properties.Settings.Default.Height;
            this.Width = Properties.Settings.Default.Width;
            // Very quick and dirty - but it does the job
            if (Properties.Settings.Default.Maximized)
            {
                WindowState = WindowState.Maximized;
            }
        }
    }
}