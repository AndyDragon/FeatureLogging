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
    }
}