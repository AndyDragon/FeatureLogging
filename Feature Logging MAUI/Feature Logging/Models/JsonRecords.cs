namespace FeatureLogging.Models;

public class ScriptsCatalog
{
    public ScriptsCatalog()
    {
        Hubs = new Dictionary<string, IList<PageEntry>>();
    }

    public IDictionary<string, IList<PageEntry>>? Hubs { get; set; }
}

public class PageEntry
{
    public PageEntry()
    {
        Name = string.Empty;
    }

    public string Name { get; set; }
    public string? PageName { get; set; }
    public string? Title { get; set; }
    public string? HashTag { get; set; }
}

public class LoadedPage(string hubName, PageEntry page)
{
    public string Id
    {
        get
        {
            if (string.IsNullOrEmpty(HubName))
            {
                return Name;
            }
            return $"{HubName}:{Name}";
        }
    }
    public string HubName { get; } = hubName;
    public string Name { get; } = page.Name;
    public string? PageName { get; } = page.PageName;
    public string? Title { get; private set; } = page.Title;
    public string? HashTag { get; } = page.HashTag;
    public string DisplayName
    {
        get
        {
            if (string.IsNullOrEmpty(HubName) || HubName == "other")
            {
                return Name;
            }
            return $"{HubName}_{Name}";
        }
    }
    public string[] PageTags
    {
        get
        {
            if (HubName == "snap")
            {
                if (!string.IsNullOrEmpty(PageName) && PageName != Name)
                {
                    return [HashTag ?? $"snap_{Name}", $"raw_{Name}", $"snap_{PageName}", $"raw_{PageName}"];
                }
                return [HashTag ?? $"snap_{Name}", $"raw_{Name}"];
            }
            if (HubName == "click")
            {
                return [HashTag ?? $"click_{Name}"];
            }
            return [HashTag ?? Name];
        }
    }
}

public class TemplatesCatalog
{
    public TemplatesCatalog()
    {
        Pages = [];
        SpecialTemplates = [];
    }

    public TemplatePageEntry[] Pages { get; set; }

    public TemplateEntry[] SpecialTemplates { get; set; }
}

public class TemplatePageEntry
{
    public TemplatePageEntry()
    {
        Name = string.Empty;
        Templates = [];
    }

    public string Name { get; set; }

    public TemplateEntry[] Templates { get; set; }
}

public class TemplateEntry
{
    public TemplateEntry()
    {
        Name = string.Empty;
        Template = string.Empty;
    }

    public string Name { get; set; }

    public string Template { get; set; }
}

internal class LoadedPageComparer : IComparer<LoadedPage>
{
    public int Compare(LoadedPage? x, LoadedPage? y)
    {
        if (x == null && y == null)
        {
            return 0;
        }
        if (x == null)
        {
            return -1;
        }
        if (y == null)
        {
            return 1;
        }
        if (x.HubName == "other" && y.HubName == "other")
        {
            // ReSharper disable once StringCompareIsCultureSpecific.3
            return string.Compare(x.Id, y.Id, true);
        }
        if (x.HubName == "other")
        {
            return 1;
        }
        if (y.HubName == "other")
        {
            return -1;
        }
        // ReSharper disable once StringCompareIsCultureSpecific.3
        return string.Compare(x.DisplayName, y.DisplayName, true);
    }

    public static readonly LoadedPageComparer Default = new();
}
