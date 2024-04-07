using MahApps.Metro.Controls;

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
    }
}
