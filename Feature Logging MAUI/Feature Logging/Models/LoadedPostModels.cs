using System.Text;
using System.Text.RegularExpressions;
using FeatureLogging.Base;

namespace FeatureLogging.Models;

public static class PostDataHelper
{
    public static string JoinSegments(Segment[]? segments, List<string>? hashTags = null)
    {
        var builder = new StringBuilder();
        foreach (var segment in segments ?? [])
        {
            switch (segment.Type)
            {
                case "text":
                    builder.Append(segment.Value);
                    break;

                case "tag":
                    builder.Append($"#{segment.Value}");
                    if (segment.Value != null)
                    {
                        hashTags?.Add(segment.Value);
                    }
                    break;

                case "person":
                    builder.Append(segment.Label != null ? $"@{segment.Label}" : segment.Value);
                    break;

                case "url":
                    builder.Append(segment.Label ?? segment.Value);
                    break;
            }
        }

        return builder.ToString().Replace("\\n", "\n");
    }
}

public enum LogType
{
    Info,
    Success,
    Warning,
    Error,
    Special
}
public class LogEntry(string message, LogType type = LogType.Success, bool showBullet = true) : NotifyPropertyChanged
{
    private static readonly Color InfoColor = 
        Application.Current!.RequestedTheme == AppTheme.Dark ? Colors.White : Colors.Black;
    private static readonly Color SuccessColor = Colors.Lime;
    private static readonly Color WarningColor = Colors.Yellow;
    private static readonly Color ErrorColor = Colors.Red;
    private static readonly Color SpecialColor = Colors.Violet;

    private string message = message;
    public string Message
    {
        get => message;
        set => Set(ref message, value);
    }
    
    private LogType type = type;
    public LogType Type
    {
        get => type;
        set => Set(ref type, value, [nameof(Color)]);
    }
    
    private bool showBullet = showBullet;

    public bool ShowBullet
    {
        get => showBullet;
        set => Set(ref showBullet, value);
    }
    
    public Color Color
    {
        get
        {
            return Type switch
            {
                LogType.Info => InfoColor,
                LogType.Warning => WarningColor,
                LogType.Error => ErrorColor,
                LogType.Special => SpecialColor,
                _ => SuccessColor
            };
        }
    }
}

public static partial class StringExtensions
{
    public static string StripExtraSpaces(this string source, bool stripNewlines = false)
    {
        return stripNewlines 
            ? WhitespaceRegex().Replace(source, " ") 
            : string.Join("\n", source.Split('\n').Select(line => line.Trim().StripExtraSpaces(true)));
    }

    [GeneratedRegex("[\\s]+")]
    private static partial Regex WhitespaceRegex();
}

public static class DateTimeExtensions
{
    public static string FormatTimestamp(this DateTime source)
    {
        var delta = DateTime.Now - source.ToLocalTime();
        if (delta.TotalMinutes < 1)
        {
            return "Now";
        }
        if (delta.TotalMinutes < 60)
        {
            var minutes = (int)delta.TotalMinutes;
            var result = $"{minutes}m";
            return result;
        }
        if (delta.TotalHours < 24)
        {
            var hours = (int)delta.TotalHours;
            var result = $"{hours}h";
            return result;
        }
        if (delta.TotalDays < 7)
        {
            var days = (int)delta.TotalDays;
            var result = $"{days}d";
            return result;
        }
        if (source.Year == DateTime.Now.Year)
        {
            return source.ToString("MMM d");
        }
        return source.ToString("MMM d, yyyy");
    }
}
