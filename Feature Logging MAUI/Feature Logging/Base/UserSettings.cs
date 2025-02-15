using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace FeatureLogging.Base;

internal static class UserSettings
{
    public static event PropertyChangedEventHandler? PropertyChanged;

    public static  void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(null, new PropertyChangedEventArgs(propertyName));
    }
}
