using System.Collections.ObjectModel;

namespace FeatureLogging.ViewModels
{
    public class MainViewModel : NotifyPropertyChanged
    {
        readonly ObservableCollection<Feature> features = [];
        public ObservableCollection<Feature> Features => features;

        private Feature? selectedFeature = null;
        public Feature? SelectedFeature {
            get => selectedFeature;
            set => Set(ref selectedFeature, value);
        }

        public Command AddFeatureCommand => new(() =>
        {
            if (Clipboard.HasText)
            {
                var text = Clipboard.GetTextAsync().Result ?? "";
                if (text.StartsWith("https://vero.co/"))
                {
                    var feature = new Feature
                    {
                        PostLink = text,
                        UserAlias = text["https://vero.co/".Length..].Split("/").FirstOrDefault() ?? "",
                    };
                    features.Add(feature);
                    SelectedFeature = feature;
                    SemanticScreenReader.Announce($"Added feature for {feature.UserAlias}");
                }
                else
                {
                    var feature = new Feature();
                    features.Add(feature);
                    SelectedFeature = feature;
                    SemanticScreenReader.Announce($"Added blank feature");
                }
            }
            else
            {
                var feature = new Feature();
                features.Add(feature);
                SelectedFeature = feature;
                SemanticScreenReader.Announce($"Added blank feature");
            }
        });
    }
}
