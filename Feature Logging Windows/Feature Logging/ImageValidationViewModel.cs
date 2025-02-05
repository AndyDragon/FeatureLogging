using System.Collections.ObjectModel;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Windows;
using System.Windows.Media;
using MahApps.Metro.IconPacks;
using Newtonsoft.Json;
using Notification.Wpf;

namespace FeatureLogging
{
    public class ImageValidationViewModel : NotifyPropertyChanged
    {
        static readonly Color? defaultLogColor = null;// Colors.Blue;
        private readonly HttpClient httpClient = new();
        private readonly NotificationManager notificationManager = new();
        private readonly MainViewModel vm;
        private readonly ImageEntry imageEntry;

        public ImageValidationViewModel(MainViewModel vm, ImageEntry imageEntry) 
        {
            this.vm = vm;
            this.imageEntry = imageEntry;

            #region Commands

            CopyLogCommand = new Command(() =>
            {
                CopyTextToClipboard(string.Join("\n", LogEntries.Select(entry => entry.Messsage)), "Copied the log messages to the clipboard", notificationManager);
            });

            #endregion

            var encodedImageUri = Uri.EscapeDataString(imageEntry.Source.AbsoluteUri);
            TinEyeUri = $"https://www.tineye.com/search/?pluginver=chrome-2.0.4&sort=score&order=desc&url={encodedImageUri}";
            _ = LoadImageValidation();
        }

        private async Task LoadImageValidation()
        {
            using var progress = notificationManager.ShowProgressBar(
                "Checking image using Hive AI Detection",
                ShowCancelButton: false,
                areaName: "WindowArea");
            await Task.Delay(TimeSpan.FromSeconds(0.5), progress.Cancel);
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
                progress.Report((20, "Waiting for server", null, null));
                using var result = await httpClient.PostAsync(hiveApiUri, form);
                progress.Report((40, "Waiting for response", null, null));
                var content = await result.Content.ReadAsStringAsync();
                if (!string.IsNullOrEmpty(content))
                {
                    try
                    {
                        var response = HiveResponse.FromJson(content);
                        if (response != null)
                        {
                            LogEntries.Add(new LogEntry(JsonConvert.SerializeObject(response, Formatting.Indented), defaultLogColor, skipBullet: true));
                            if (response.StatusCode >= 200 && response.StatusCode <= 299)
                            {
                                progress.Report((60, "Checking for response", null, null));
                                var verdictClass = response.Data.Classes.FirstOrDefault(verdictClass => verdictClass.Class == "not_ai_generated");
                                if (verdictClass != null)
                                {
                                    var highestClass = response.Data.Classes
                                        .Where(verdictClass => !new List<string> { "not_ai_generated", "ai_generated", "none", "inconclusive", "inconclusive_video" }.Contains(verdictClass.Class))
                                        .MaxBy(verdictClass => verdictClass.Score);
                                    var highestClassString = highestClass != null ? $", highest possibility of AI: {highestClass.Class} @ {highestClass.Score:P2}" : "";
                                    var resultString = verdictClass.Score > 0.8 ? "Not AI" : verdictClass.Score < 0.5 ? "AI" : "Indeterminate";
                                    var resultColor = verdictClass.Score > 0.8 ? Colors.Lime : verdictClass.Score < 0.5 ? Colors.Red : Colors.Yellow;
                                    var resultIcon = verdictClass.Score > 0.8 ? PackIconJamIconsKind.ShieldCheckF : verdictClass.Score < 0.5 ? PackIconJamIconsKind.ShieldCloseF : PackIconJamIconsKind.ShieldMinusF;
                                    Verdict = new VerdictResult($"{resultString} ({verdictClass.Score:P2} not AI{highestClassString})", resultColor, resultIcon);
                                    VerdictVisibility = Visibility.Visible;
                                }
                                else
                                {
                                    LogEntries.Add(new LogEntry($"Could not find result class in results", Colors.Violet));
                                    Verdict = new VerdictResult($"Could not determine", Colors.Violet, PackIconJamIconsKind.ShieldMinusF);
                                    VerdictVisibility = Visibility.Visible;
                                }
                            }
                        }
                        else
                        {
                            LogEntries.Add(new LogEntry($"Could not parse the AI detection", Colors.Violet));
                            Verdict = new VerdictResult($"Could not determine", Colors.Violet, PackIconJamIconsKind.ShieldMinusF);
                            VerdictVisibility = Visibility.Visible;
                        }
                    }
                    catch (Exception ex)
                    {
                        LogEntries.Add(new LogEntry($"Could not load the AI detection {ex.Message}", Colors.Violet));
                        Verdict = new VerdictResult($"Could not determine", Colors.Violet, PackIconJamIconsKind.ShieldMinusF);
                        VerdictVisibility = Visibility.Visible;
                    }
                }
            }
            catch (Exception ex)
            {
                LogEntries.Add(new LogEntry($"Could not request the AI detection {ex.Message}", Colors.Violet));
                Verdict = new VerdictResult($"Could not determine", Colors.Violet, PackIconJamIconsKind.ShieldMinusF);
                VerdictVisibility = Visibility.Visible;
            }
            progress.Report((100, null, null, null));
        }

        #region Logging

        private readonly ObservableCollection<LogEntry> logEntries = [];
        public ObservableCollection<LogEntry> LogEntries { get => logEntries; }

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

        private VerdictResult verdict = new("Checking", Colors.Gray, PackIconJamIconsKind.Shield);
        public VerdictResult Verdict
        {
            get => verdict;
            set => Set(ref verdict, value);
        }

        #endregion

        #region Commands

        public Command CopyLogCommand { get; }

        #endregion

        private static void CopyTextToClipboard(string text, string successMessage, NotificationManager notificationManager)
        {
            if (MainViewModel.TrySetClipboardText(text))
            {
                notificationManager.Show(
                    "Copied script",
                    successMessage,
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                notificationManager.Show(
                    "Failed to copy script",
                    "Could not copy script to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(12));
            }
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

    public partial class Data
    {
        [JsonProperty("classes")]
        public required DataClass[] Classes { get; set; }
    }

    public partial class DataClass
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
}
