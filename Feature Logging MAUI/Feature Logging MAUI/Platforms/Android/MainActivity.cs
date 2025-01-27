using Android.App;
using Android.Content.PM;
using Android.OS;
using AndroidX.AppCompat.App;

namespace FeatureLogging
{
    [Activity(
        Theme = "@style/Maui.SplashTheme", 
        MainLauncher = true, 
        LaunchMode = LaunchMode.SingleTop, 
        ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density
    )]
    public class MainActivity : MauiAppCompatActivity
    {
        //AndroidX.Core.SplashScreen.SplashScreen.InstallSplashScreen(this);
    }
}
