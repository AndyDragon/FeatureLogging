using FeatureLogging.ViewModels;
using Newtonsoft.Json;
using System.Diagnostics;

namespace FeatureLogging;

internal static class UserSettings
{
    private static dynamic? _cachedStore;

    private static void LoadStore()
    {
        if (_cachedStore == null)
        {
            var userSettingsPath = MainViewModel.GetUserSettingsPath();
            if (File.Exists(userSettingsPath))
            {
                var json = File.ReadAllText(userSettingsPath);
                _cachedStore = JsonConvert.DeserializeObject(json);
            }
        }
        _cachedStore ??= new Dictionary<string, object>();
    }

    private static void SaveStore()
    {
        var userSettingsPath = MainViewModel.GetUserSettingsPath();
        var json = JsonConvert.SerializeObject(_cachedStore);
        File.WriteAllText(userSettingsPath, json);
    }

    internal static T? Get<T>(string key)
    {
        try
        {
            LoadStore();
            if (_cachedStore?.ContainsKey(key))
            {
                return _cachedStore?[key];
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine("Failed to load the user settings: " + ex.Message);
        }
        return default;
    }

    internal static T Get<T>(string key, T defaultValue) where T : notnull
    {
        try
        {
            LoadStore();
            if (_cachedStore?.ContainsKey(key))
            {
                return _cachedStore?[key] ?? defaultValue;
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine("Failed to load the user settings: " + ex.Message);
        }
        return defaultValue;

    }
    internal static void Store<T>(string key, T value)
    {
        try
        {
            LoadStore();
            if (_cachedStore != null)
            {
                _cachedStore[key] = value;
            }
            SaveStore();
        }
        catch (Exception ex)
        {
            Debug.WriteLine("Failed to store the user settings: " + ex.Message);
            throw;
        }
    }
}

internal class UserSettingsStore
{
    [JsonProperty(PropertyName = "values")]
    public IDictionary<string, object>? Values { get; set; }
}
