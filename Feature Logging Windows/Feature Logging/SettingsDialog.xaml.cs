using MahApps.Metro.Controls;
using Microsoft.Win32;
using System.Diagnostics;
using System.IO;

namespace FeatureLogging
{
    /// <summary>
    /// Interaction logic for SettingsDialog.xaml
    /// </summary>
    public partial class SettingsDialog : MetroWindow
    {
        public SettingsDialog()
        {
            InitializeComponent();
        }

        private void CloseButton_Click(object sender, System.Windows.RoutedEventArgs e)
        {
            DialogResult = true;
        }

        private void PickCullingApp_Click(object sender, System.Windows.RoutedEventArgs e)
        {
            OpenFileDialog dialog = new()
            {
                Filter = "Application files (*.exe)|*.exe|All files (*.*)|*.*",
                Title = "Pick the application you use for culling photos",
                CheckFileExists = true
            };
            if (dialog.ShowDialog() == true)
            {
                if (DataContext is Settings settings)
                {
                    settings.CullingApp = dialog.FileName;
                    settings.CullingAppName = FileVersionInfo.GetVersionInfo(dialog.FileName).ProductName ?? Path.GetFileNameWithoutExtension(dialog.FileName);
                }
            }
        }

        private void PickAiCheckApp_Click(object sender, System.Windows.RoutedEventArgs e)
        {
            OpenFileDialog dialog = new()
            {
                Filter = "Application files (*.exe)|*.exe|All files (*.*)|*.*",
                Title = "Pick the application you use for AI checking",
                CheckFileExists = true
            };
            if (dialog.ShowDialog() == true)
            {
                if (DataContext is Settings settings)
                {
                    settings.AiCheckApp = dialog.FileName;
                    settings.AiCheckAppName = FileVersionInfo.GetVersionInfo(dialog.FileName).ProductName ?? Path.GetFileNameWithoutExtension(dialog.FileName);
                }
            }
        }
    }
}
