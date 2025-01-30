using FeatureLogging.Base;
using FeatureLogging.Models;

namespace FeatureLogging.ViewModels;

public class PersonalMessageViewModel : NotifyPropertyChanged
{
    public PersonalMessageViewModel(MainViewModel mainViewModel, Feature feature)
    {
        MainViewModel = mainViewModel;
        this.feature = feature;
    }
    
    public MainViewModel MainViewModel { get; }

    private Feature feature;
    public Feature Feature
    {
        get => feature;
        set => Set(ref feature, value);
    }
}
