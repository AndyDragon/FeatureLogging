using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace FeatureLogging.ViewModels
{
    public abstract class NotifyPropertyChanged : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;

        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null)
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

        public bool SetWithDirtyCallback<T>(ref T storage, T value, Action setDirty, string[]? associatedPropertyNames = null, [CallerMemberName()] string? propertyName = null)
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
                setDirty();
                return true;
            }
            return false;
        }
    }
}
