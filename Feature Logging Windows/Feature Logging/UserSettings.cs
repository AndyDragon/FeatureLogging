using Newtonsoft.Json;
using System.Diagnostics;
using System.IO;

namespace FeatureLogging
{
    internal class UserSettings
    {
        private static dynamic? cachedStore = null;

        private static void LoadStore()
        {
            if (cachedStore == null)
            {
                var userSettingsPath = MainViewModel.GetUserSettingsPath();
                if (File.Exists(userSettingsPath))
                {
                    var json = File.ReadAllText(userSettingsPath);
                    cachedStore = JsonConvert.DeserializeObject(json);
                }
            }
            cachedStore ??= new Dictionary<string, object>();
        }

        private static void SaveStore()
        {
            var userSettingsPath = MainViewModel.GetUserSettingsPath();
            var json = JsonConvert.SerializeObject(cachedStore);
            File.WriteAllText(userSettingsPath, json);
        }

        internal static T? Get<T>(string key)
        {
            try
            {
                LoadStore();
                if (cachedStore?.ContainsKey(key))
                {
                    return cachedStore?[key];
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
                if (cachedStore?.ContainsKey(key))
                {
                    return cachedStore?[key] ?? defaultValue;
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
                if (cachedStore != null)
                {
                    cachedStore[key] = value;
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
}
