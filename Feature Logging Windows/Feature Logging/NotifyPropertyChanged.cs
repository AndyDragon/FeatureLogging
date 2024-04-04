using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace FeatureLogging
{
    public abstract class NotifyPropertyChanged : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;

        protected void OnPropertyChanged([CallerMemberName] string? propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public bool Set<T>(ref T storage, T value, string[]? associatedPropertyNames = null, [CallerMemberName()] string? propertyName = null)
        {
            if (!object.Equals(storage, value))
            {
                storage = value;
                OnPropertyChanged(propertyName);
                if (associatedPropertyNames != null)
                {
                    foreach (var associatedProperty in associatedPropertyNames)
                    {
                        OnPropertyChanged(associatedProperty);
                    }
                }
                return true;
            }
            return false;
        }
    }
}
