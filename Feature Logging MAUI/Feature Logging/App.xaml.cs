using FeatureLogging.Base;

namespace FeatureLogging;

public partial class App
{
    public App()
    {
        InitializeComponent();

        RequestedThemeChanged += (_, e) =>
        {
            SetTheme(e.RequestedTheme);
        };
    }

    private void SetTheme(AppTheme theme)
    {
        if (theme == AppTheme.Dark)
        {
            // Apply dark theme resources
            Resources["BackgroundColor"] = Colors.Black;
            Resources["TextColor"] = Colors.White;
        }
        else
        {
            // Apply light theme resources
            Resources["BackgroundColor"] = Colors.White;
            Resources["TextColor"] = Colors.Black;
        }

        // Optionally, you can call a method to update the UI
        UpdateTheme(theme);
    }

    private void UpdateTheme(AppTheme theme)
    {
        // Implement logic to update the UI based on the theme
        if (Windows[0].Page is IThemePage themePage)
        {
            themePage.UpdateTheme(theme);
        }
    }

    protected override Window CreateWindow(IActivationState? activationState)
    {
        return new Window(new AppShell());
    }
}
