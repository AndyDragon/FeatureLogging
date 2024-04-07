using MahApps.Metro.Controls;

namespace FeatureLogging
{
    /// <summary>
    /// Interaction logic for PersonalMessageDialog.xaml
    /// </summary>
    public partial class PersonalMessageDialog : MetroWindow
    {
        public PersonalMessageDialog()
        {
            InitializeComponent();
        }

        private void CloseButton_Click(object sender, System.Windows.RoutedEventArgs e)
        {
            DialogResult = true;
        }
    }
}
