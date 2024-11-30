using ControlzEx.Theming;
using System.IO;
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
            static void HandleExceptionLogging(Exception ex)
            {
                try
                {
                    MessageBox.Show(ex.ToString(), "Fatal application exception, please report to AndyDragon", MessageBoxButton.OK);
                    // Danger! Trying to save a file in the middle of a crash, should work?
                    File.WriteAllText(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Feature Logging.crashlog"), ex.ToString());
                }
                catch
                {
                    // Application is already crashing, don't add to the problem...
                }
            }

            // Handle errors on main thread.
            AppDomain.CurrentDomain.UnhandledException += (sender, e) =>
            {
                if (e.ExceptionObject is Exception ex)
                {
                    HandleExceptionLogging(ex);
                }
            };

            // Handle errors on other threads using the task scheduler.
            TaskScheduler.UnobservedTaskException += (sender, e) =>
            {
                if (e.Exception is Exception ex)
                {
                    HandleExceptionLogging(ex);
                }
            };

            base.OnStartup(e);

            ThemeManager.Current.ThemeSyncMode = ThemeSyncMode.SyncAll;

            ThemeManager.Current.SyncTheme();

            var lastThemeName = UserSettings.Get<string>("theme");
            if (!string.IsNullOrEmpty(lastThemeName))
            {
                ThemeManager.Current.ChangeTheme(this, lastThemeName);
            }
        }
    }
}
