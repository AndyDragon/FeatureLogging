// using System;
using System.Collections.ObjectModel;
// using System.Diagnostics;
// using System.Net.Http;
using System.Net.Http.Headers;
// using System.Windows;
using CommunityToolkit.Maui.Alerts;
using MauiIcons.Material;
// using System.Windows.Media;
// using MahApps.Metro.IconPacks;
using Newtonsoft.Json;
// using Notification.Wpf;

namespace FeatureLogging.ViewModels;

public class ImageValidationViewModel : NotifyPropertyChanged
{
    private static readonly Color? DefaultLogColor = null;
    private readonly HttpClient httpClient = new();
    private readonly MainViewModel vm;
    private readonly ImageEntry imageEntry;

    public ImageValidationViewModel(MainViewModel vm, ImageEntry imageEntry)
    {
        this.vm = vm;
        this.imageEntry = imageEntry;

        var encodedImageUri = Uri.EscapeDataString(imageEntry.Source.AbsoluteUri);
        TinEyeUri =
            $"https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url={encodedImageUri}";
        _ = LoadImageValidation();
    }

    private async Task LoadImageValidation()
    {
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
                        LogEntries.Add(new LogEntry(JsonConvert.SerializeObject(response, Formatting.Indented),
                            DefaultLogColor, skipBullet: true));
                        if (response.StatusCode is >= 200 and <= 299)
                        {
                            var verdictClass = response.Data.Classes.FirstOrDefault(verdictClass =>
                                verdictClass.Class == "not_ai_generated");
                            if (verdictClass != null)
                            {
                                var highestClass = response.Data.Classes
                                    .Where(vc => !new List<string>
                                    {
                                        "not_ai_generated", "ai_generated", "none", "inconclusive", "inconclusive_video"
                                    }.Contains(vc.Class))
                                    .MaxBy(vc => vc.Score);
                                var highestClassString = highestClass != null
                                    ? $", highest possibility of AI: {highestClass.Class} @ {highestClass.Score:P2}"
                                    : "";
                                var resultString = verdictClass.Score > 0.8 ? "Not AI" :
                                    verdictClass.Score < 0.5 ? "AI" : "Indeterminate";
                                var resultColor = verdictClass.Score > 0.8 ? Colors.Lime :
                                    verdictClass.Score < 0.5 ? Colors.Red : Colors.Yellow;
                                var resultIcon = verdictClass.Score > 0.8 ? MaterialIcons.VerifiedUser :
                                    verdictClass.Score < 0.5 ? MaterialIcons.GppBad : MaterialIcons.PrivacyTip;
                                Verdict = new VerdictResult($"{resultString} ({verdictClass.Score:P2} not AI{highestClassString})", resultColor, resultIcon);
                                VerdictVisibility = Visibility.Visible;
                            }
                            else
                            {
                                LogEntries.Add(new LogEntry($"Could not find result class in results", Colors.Violet));
                                Verdict = new VerdictResult($"Could not determine", Colors.Violet, MaterialIcons.Shield);
                                VerdictVisibility = Visibility.Visible;
                            }
                        }
                    }
                    else
                    {
                        LogEntries.Add(new LogEntry($"Could not parse the AI detection", Colors.Violet));
                        Verdict = new VerdictResult($"Could not determine", Colors.Violet, MaterialIcons.Shield);
                        VerdictVisibility = Visibility.Visible;
                    }
                }
                catch (Exception ex)
                {
                    LogEntries.Add(new LogEntry($"Could not load the AI detection {ex.Message}", Colors.Violet));
                    Verdict = new VerdictResult($"Could not determine", Colors.Violet, MaterialIcons.Shield);
                    VerdictVisibility = Visibility.Visible;
                }
            }
        }
        catch (Exception ex)
        {
            LogEntries.Add(new LogEntry($"Could not request the AI detection {ex.Message}", Colors.Violet));
            Verdict = new VerdictResult($"Could not determine", Colors.Violet, MaterialIcons.Shield);
            VerdictVisibility = Visibility.Visible;
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
                vm.TriggerTinEyeSource();
            }
        }
    }

    #endregion

    #region HIVE results

    private Visibility verdictVisibility = Visibility.Collapsed;

    public Visibility VerdictVisibility
    {
        get => verdictVisibility;
        set => Set(ref verdictVisibility, value);
    }

    private VerdictResult verdict = new("Checking", Colors.Gray, MaterialIcons.Shield);

    public VerdictResult Verdict
    {
        get => verdict;
        set => Set(ref verdict, value);
    }

    #endregion

    #region Commands

    public Command CopyLogCommand => new(() =>
    {
        _ = CopyTextToClipboard(string.Join("\n", LogEntries.Select(entry => entry.Messsage)), "Copied the log messages to the clipboard");
    });

    #endregion

    private static async Task CopyTextToClipboard(string text, string successMessage)
    {
        await MainViewModel.TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
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
