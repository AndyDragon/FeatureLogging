using FeatureLogging.Base;

namespace FeatureLogging.Models;

public class Placeholder : NotifyPropertyChanged
{
    public Placeholder(string name, string value)
    {
        Name = name;
        Value = value;
    }

    private readonly string name = "";
    public string Name
    {
        get => name;
        init => Set(ref name, value);
    }

    private string currentValue = "";
    public string Value
    {
        get => currentValue;
        set => Set(ref currentValue, value);
    }
}
