using LiveCharts;

namespace FeatureLogging
{
    public class ChartData(string title, string subTitle, SeriesCollection data) : NotifyPropertyChanged
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
        
        private SeriesCollection data = data;
        public SeriesCollection Data
        {
            get => data;
            set => Set(ref data, value);
        }
    }
}
