using System.Collections.ObjectModel;
using System.ComponentModel;
using FeatureLogging.Base;
using FeatureLogging.Models;

namespace FeatureLogging.ViewModels;

public sealed class PlaceholdersViewModel : NotifyPropertyChanged
{
    public PlaceholdersViewModel(ScriptsViewModel scriptViewModel, Script script)
    {
        ScriptsViewModel = scriptViewModel;
        this.script = script;
        Placeholders = scriptViewModel.PlaceholdersMap[script];
        LongPlaceholders = scriptViewModel.LongPlaceholdersMap[script];
        foreach (var placeholder in Placeholders)
        {
            placeholder.PropertyChanged += PlaceholderOnPropertyChanged;
        }
        OnPropertyChanged(nameof(ScriptLength));
    }

    private readonly Script script;

    private void PlaceholderOnPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        OnPropertyChanged(nameof(ScriptLength));
    }

    public ScriptsViewModel ScriptsViewModel { get; }
    
    public int ScriptLength => ScriptsViewModel.ProcessPlaceholders(script).Length;

    public ObservableCollection<Placeholder> Placeholders { get; }
    
    public ObservableCollection<Placeholder> LongPlaceholders { get; }
}
