using OxyPlot;
using OxyPlot.Series;
using System.Collections.ObjectModel;

namespace FeatureLogging
{
    public class ChartData(string title, string subTitle, PlotModel model) : NotifyPropertyChanged
    {
        private string title = title;
        public string Title 
        {
            get => title;
            set => Set(ref title, value);
        }
        
        private string subTitle = subTitle;
        public string SubTitle
        {
            get => subTitle;
            set => Set(ref subTitle, value);
        }
        
        private PlotModel model = model;
        public PlotModel Model
        {
            get => model;
            set => Set(ref model, value);
        }

        private ObservableCollection<PieSlice> slices = [.. (model.Series[0] as PieSeries)!.Slices];
        public ObservableCollection<PieSlice> Slices
        {
            get => slices;
            set => Set(ref slices, value);
        }
    }
}
