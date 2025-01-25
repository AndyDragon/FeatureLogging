namespace FeatureLogging.ViewModels;

public class Placeholder : NotifyPropertyChanged
{
    public Placeholder(string name)
    {
        Name = name;
    }

    public Placeholder(string name, string value)
    {
        Name = name;
        Value = value;
    }

    private string name = "";
    public string Name
    {
        get => name;
        set => Set(ref name, value);
    }

    private string currentValue = "";
    public string Value
    {
        get => currentValue;
        set => Set(ref this.currentValue, value);
    }
}
