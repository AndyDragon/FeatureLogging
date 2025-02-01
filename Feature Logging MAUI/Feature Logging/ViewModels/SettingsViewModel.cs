using FeatureLogging.Base;

namespace FeatureLogging.ViewModels;

public class SettingsViewModel : NotifyPropertyChanged
{
    private bool includeHash = UserSettings.Get(
        nameof(IncludeHash), 
        true);
    public bool IncludeHash
    {
        get => includeHash;
        set
        {
            if (Set(ref includeHash, value))
            {
                UserSettings.Store(nameof(IncludeHash), includeHash);
            }
        }
    }
    
    private string personalMessage = UserSettings.Get(
        nameof(PersonalMessage), 
        "\ud83c\udf89\ud83d\udcab Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% \ud83d\udcab\ud83c\udf89");
    public string PersonalMessage
    {
        get => personalMessage;
        set
        {
            if (Set(ref personalMessage, value))
            {
                UserSettings.Store(nameof(PersonalMessage), personalMessage);
            }
        }
    }
    
    private string personalMessageFirst = UserSettings.Get(
        nameof(PersonalMessageFirst), 
        "\ud83c\udf89\ud83d\udcab Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% \ud83d\udcab\ud83c\udf89");
    public string PersonalMessageFirst
    {
        get => personalMessageFirst;
        set
        {
            if (Set(ref personalMessageFirst, value))
            {
                UserSettings.Store(nameof(PersonalMessageFirst), personalMessageFirst);
            }
        }
    }
}
