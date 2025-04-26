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

        protected override void OnActivated(EventArgs e)
        {
            base.OnActivated(e);
            EditBox.Focus();
        }

        private void CloseButton_Click(object sender, System.Windows.RoutedEventArgs e)
        {
            DialogResult = true;
        }
    }
}
