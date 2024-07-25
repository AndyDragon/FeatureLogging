using System.Collections.ObjectModel;

namespace FeatureLogging
{
    public partial class PlaceholdersViewModel(ScriptsViewModel scriptViewModel, Script script)
    {
        public ScriptsViewModel ScriptsViewModel { get; private set; } = scriptViewModel;

        public ObservableCollection<Placeholder> Placeholders { get; private set; } = scriptViewModel.PlaceholdersMap[script];
        public ObservableCollection<Placeholder> LongPlaceholders { get; private set; } = scriptViewModel.LongPlaceholdersMap[script];
    }
}
