using FeatureLogging.Base;
using FeatureLogging.Models;

namespace FeatureLogging.ViewModels;

public class PersonalMessageViewModel(MainViewModel mainViewModel, Feature feature) : NotifyPropertyChanged
{
    public MainViewModel MainViewModel { get; } = mainViewModel;

    private Feature feature = feature;
    public Feature Feature
    {
        get => feature;
        set => Set(ref feature, value);
    }
}
