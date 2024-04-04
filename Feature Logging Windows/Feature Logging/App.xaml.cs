using ControlzEx.Theming;
using System.Windows;

namespace FeatureLogging
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            var lastThemeName = UserSettings.Get<string>("theme");
            if (!string.IsNullOrEmpty(lastThemeName))
            {
                ThemeManager.Current.ChangeTheme(this, lastThemeName);
            }
        }
    }
}
