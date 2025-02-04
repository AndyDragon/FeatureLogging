using System.Collections.ObjectModel;
using System.Net.Http.Headers;
using FeatureLogging.Base;
using FeatureLogging.Models;
using MauiIcons.Material.Rounded;
using Newtonsoft.Json;

namespace FeatureLogging.ViewModels;

public enum VisibleTab
{
    TinEye,
    HiveAi,
}

public class ImageValidationViewModel : NotifyPropertyChanged
{
    private readonly HttpClient httpClient = new();
    private readonly ImageEntry imageEntry;

    public ImageValidationViewModel(MainViewModel mainViewModel, ImageEntry imageEntry)
    {
        MainViewModel = mainViewModel;
        this.imageEntry = imageEntry;

        var encodedImageUri = Uri.EscapeDataString(imageEntry.Source.AbsoluteUri);
        TinEyeUri = $"https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url={encodedImageUri}";
    }

    public async Task TriggerLoad()
    {
        await Task.Delay(TimeSpan.FromSeconds(1));
        await LoadImageValidation();
    }
    
    public MainViewModel MainViewModel { get; }
    
    private VisibleTab visibleTab = VisibleTab.TinEye;
    private VisibleTab VisibleTab
    {
        get => visibleTab;
        set => Set(ref visibleTab, value, [
            nameof(TinEyeTabColor), 
            nameof(HiveAiTabColor), 
            nameof(TinEyeTabTextColor), 
            nameof(HiveAiTabTextColor), 
            nameof(IsTinEyeTab), 
            nameof(IsHiveAiTab)
        ]);
    }

    public bool IsTinEyeTab => visibleTab == VisibleTab.TinEye;
    public Color TinEyeTabColor => VisibleTab == VisibleTab.TinEye 
        ? (Application.Current!.RequestedTheme == AppTheme.Light ? Color.FromRgb(0x20, 0x20, 0x60) : Color.FromRgb(0xb0, 0xb0, 0xd0)) 
        : (Application.Current!.RequestedTheme == AppTheme.Light ? Color.FromRgb(0xff, 0xff, 0xff) : Color.FromRgb(0x20, 0x20, 0x20));
    public Color TinEyeTabTextColor => VisibleTab == VisibleTab.TinEye 
        ? (Application.Current!.RequestedTheme == AppTheme.Light ? Colors.White : Colors.Black) 
        : (Application.Current!.RequestedTheme == AppTheme.Light ? Colors.Black : Colors.White);
    public SimpleCommand SwitchToTinEyeTabCommand => new(() => VisibleTab = VisibleTab.TinEye);

    public bool IsHiveAiTab => visibleTab == VisibleTab.HiveAi;
    public Color HiveAiTabColor => VisibleTab == VisibleTab.HiveAi 
        ? (Application.Current!.RequestedTheme == AppTheme.Light ? Color.FromRgb(0x20, 0x40, 0x60) : Color.FromRgb(0xb0, 0xc0, 0xd0)) 
        : (Application.Current!.RequestedTheme == AppTheme.Light ? Color.FromRgb(0xff, 0xff, 0xff) : Color.FromRgb(0x20, 0x20, 0x20));
    public Color HiveAiTabTextColor => VisibleTab == VisibleTab.HiveAi 
        ? (Application.Current!.RequestedTheme == AppTheme.Light ? Colors.White : Colors.Black) 
        : (Application.Current!.RequestedTheme == AppTheme.Light ? Colors.Black : Colors.White);
    public SimpleCommand SwitchToHivAiTabCommand => new(() => VisibleTab = VisibleTab.HiveAi);

    private async Task LoadImageValidation()
    {
        LogEntries.Clear();

        try
        {
            // Disable client-side caching.
            httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            // Accept JSON result
            httpClient.DefaultRequestHeaders.Accept.Clear();
            httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            var hiveApiUri = new Uri("https://plugin.hivemoderation.com/api/v1/image/ai_detection");
            MultipartFormDataContent form = new()
            {
                { new StringContent(imageEntry.Source.AbsoluteUri), "url" },
                { new StringContent(Guid.NewGuid().ToString()), "request_id" }
            };
            using var result = await httpClient.PostAsync(hiveApiUri, form);
            var content = await result.Content.ReadAsStringAsync();
            if (!string.IsNullOrEmpty(content))
            {
                try
                {
                    var response = HiveResponse.FromJson(content);
                    if (response != null)
                    {
                        var formattedResponse = JsonConvert.SerializeObject(response, Formatting.Indented);
                        var lines = formattedResponse.Split('\n');
                        foreach (var line in lines)
                        {
                            LogEntries.Add(new LogEntry(line, LogType.Info, showBullet: false));
                        }

                        if (response.StatusCode is >= 200 and <= 299)
                        {
                            var verdictClass = response.Data.Classes.FirstOrDefault(verdictClass => verdictClass.Class == "not_ai_generated");
                            if (verdictClass != null)
                            {
                                var highestClass = response.Data.Classes
                                    .Where(vc => !new List<string>{ "not_ai_generated", "ai_generated", "none", "inconclusive", "inconclusive_video" }.Contains(vc.Class))
                                    .Where(vc => vc.Score > 1)
                                    .MaxBy(vc => vc.Score);
                                var highestClassString = highestClass != null
                                    ? $"Highest possibility of AI: {highestClass.Class} @ {highestClass.Score:P2}" : "No indication of AI";
                                var resultString = verdictClass.Score > 0.8 
                                    ? "Not AI" : verdictClass.Score < 0.5 
                                        ? "AI" : "Indeterminate";
                                var resultColor = verdictClass.Score > 0.8 
                                    ? Colors.Green : verdictClass.Score < 0.5 
                                        ? Colors.Red : Colors.Yellow;
                                var resultIcon = verdictClass.Score > 0.8 
                                    ? MaterialRoundedIcons.VerifiedUser : verdictClass.Score < 0.5 
                                        ? MaterialRoundedIcons.GppBad : MaterialRoundedIcons.PrivacyTip;
                                Verdict = new VerdictResult($"{resultString} ({verdictClass.Score:P2} not AI)", highestClassString, resultColor, resultIcon);
                            }
                            else
                            {
                                LogEntries.Add(new LogEntry($"Could not find result class in results", LogType.Special));
                                Verdict = new VerdictResult($"Could not determine", "", Colors.Violet, MaterialRoundedIcons.Shield);
                            }
                        }
                    }
                    else
                    {
                        LogEntries.Add(new LogEntry($"Could not parse the AI detection", LogType.Special));
                        Verdict = new VerdictResult($"Could not determine", "", Colors.Violet, MaterialRoundedIcons.Shield);
                    }
                }
                catch (Exception ex)
                {
                    LogEntries.Add(new LogEntry($"Could not load the AI detection {ex.Message}", LogType.Special));
                    Verdict = new VerdictResult($"Could not determine", "", Colors.Violet, MaterialRoundedIcons.Shield);
                }
            }
        }
        catch (Exception ex)
        {
            LogEntries.Add(new LogEntry($"Could not request the AI detection {ex.Message}", LogType.Special));
            Verdict = new VerdictResult($"Could not determine", "", Colors.Violet, MaterialRoundedIcons.Shield);
        }
    }

    #region Logging

    public ObservableCollection<LogEntry> LogEntries { get; } = [];

    #endregion

    #region TinEye

    private string tinEyeUri = "";

    public string TinEyeUri
    {
        get => tinEyeUri;
        set
        {
            if (Set(ref tinEyeUri, value))
            {
                MainViewModel.TriggerTinEyeSource();
            }
        }
    }

    #endregion

    #region HIVE results

    private VerdictResult verdict = new("Checking...", "", Colors.Gray, MaterialRoundedIcons.Shield);

    public VerdictResult Verdict
    {
        get => verdict;
        private set => Set(ref verdict, value);
    }

    #endregion

    public void TriggerThemeChange()
    {
        OnPropertyChanged(nameof(TinEyeTabColor));
        OnPropertyChanged(nameof(HiveAiTabColor));
        OnPropertyChanged(nameof(TinEyeTabTextColor));
        OnPropertyChanged(nameof(HiveAiTabTextColor));
    }
}

public partial class HiveResponse
{
    [JsonProperty("data")]
    public required Data Data { get; set; }

    [JsonProperty("message")]
    public required string Message { get; set; }

    [JsonProperty("status_code")]
    public long StatusCode { get; set; }
}

public class Data
{
    [JsonProperty("classes")]
    public required DataClass[] Classes { get; set; }
}

public class DataClass
{
    [JsonProperty("class")]
    public required string Class { get; set; }

    [JsonProperty("score")]
    public double Score { get; set; }
}

public partial class HiveResponse
{
    public static HiveResponse? FromJson(string json)
    {
        return JsonConvert.DeserializeObject<HiveResponse>(json);
    }
}
