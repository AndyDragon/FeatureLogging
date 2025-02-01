// ReSharper disable ConvertConstructorToMemberInitializers
// ReSharper disable ClassNeverInstantiated.Global

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
    public string Id => string.IsNullOrEmpty(HubName) ? Name : $"{HubName}:{Name}";
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
            return HubName switch
            {
                "snap" when !string.IsNullOrEmpty(PageName) && PageName != Name => 
                    [HashTag ?? $"snap_{Name}", $"raw_{Name}", $"snap_{PageName}", $"raw_{PageName}"],
                "snap" => 
                    [HashTag ?? $"snap_{Name}", $"raw_{Name}"],
                "click" => 
                    [HashTag ?? $"click_{Name}"],
                _ => 
                    [HashTag ?? Name]
            };
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
        switch (x)
        {
            case null when y == null:
                return 0;
            case null:
                return -1;
        }

        if (y == null)
        {
            return 1;
        }
        
        switch (x.HubName)
        {
            case "other" when y.HubName == "other":
                // ReSharper disable once StringCompareIsCultureSpecific.3
                return string.Compare(x.Id, y.Id, true);
            case "other":
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
