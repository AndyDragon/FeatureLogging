using System.Collections.ObjectModel;
using System.ComponentModel;

namespace FeatureLogging
{
    public partial class PlaceholdersViewModel : NotifyPropertyChanged
    {
        public PlaceholdersViewModel(ScriptsViewModel scriptViewModel, Script script)
        {
            ScriptsViewModel = scriptViewModel;
            Placeholders = scriptViewModel.PlaceholdersMap[script];
            LongPlaceholders = scriptViewModel.LongPlaceholdersMap[script];
            this.script = script;
            ScriptLength = ScriptsViewModel.ProcessPlaceholders(script).Length;

            foreach (var placeholder in Placeholders)
            {
                placeholder.PropertyChanged += OnPlaceholderPropertyChanged;
            }
            foreach (var placeholder in LongPlaceholders)
            {
                placeholder.PropertyChanged += OnPlaceholderPropertyChanged;
            }
        }

        private readonly Script script;

        private void OnPlaceholderPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            ScriptLength = ScriptsViewModel.ProcessPlaceholders(script).Length;
        }

        public ScriptsViewModel ScriptsViewModel { get; private set; }

        public ObservableCollection<Placeholder> Placeholders { get; private set; }
        public ObservableCollection<Placeholder> LongPlaceholders { get; private set; }

        private int scriptLength = 0;
        public int ScriptLength
        {
            get => scriptLength;
            set => Set(ref scriptLength, value);
        }
    }
}
