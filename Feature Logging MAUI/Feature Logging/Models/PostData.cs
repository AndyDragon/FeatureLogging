using Newtonsoft.Json;
using System.Xml.Linq;

namespace FeatureLogging
{
    #region Old data

    public class PostData
    {
        public static PostData? FromJson(string json) => JsonConvert.DeserializeObject<PostData>(json);

        [JsonProperty("loaderData", NullValueHandling = NullValueHandling.Ignore)]
        public LoaderData? LoaderData { get; set; }
    }

    public class PostData2
    {
        public static PostData2? FromJson(string json) => JsonConvert.DeserializeObject<PostData2>(json);

        [JsonProperty("loaderData", NullValueHandling = NullValueHandling.Ignore)]
        public LoaderData2? LoaderData { get; set; }
    }

    public class LoaderData
    {
        [JsonProperty("0-1", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry1 { get; set; }

        [JsonProperty("0-2", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry2 { get; set; }

        [JsonProperty("0-3", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry3 { get; set; }

        [JsonProperty("0-4", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry4 { get; set; }

        [JsonProperty("0-5", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry? Entry5 { get; set; }

        public PostEntry? Entry => Entry1 ?? Entry2 ?? Entry3 ?? Entry4 ?? Entry5;
    }

    public class LoaderData2
    {
        [JsonProperty("0-1", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry2? Entry1 { get; set; }

        [JsonProperty("0-2", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry2? Entry2 { get; set; }

        [JsonProperty("0-3", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry2? Entry3 { get; set; }

        [JsonProperty("0-4", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry2? Entry4 { get; set; }

        [JsonProperty("0-5", NullValueHandling = NullValueHandling.Ignore)]
        public PostEntry2? Entry5 { get; set; }

        public PostEntry2? Entry => Entry1 ?? Entry2 ?? Entry3 ?? Entry4 ?? Entry5;
    }

    public class PostEntry
    {
        [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
        public EntryProfile? Profile { get; set; }

        [JsonProperty("post", NullValueHandling = NullValueHandling.Ignore)]
        public EntryPost? Post { get; set; }
    }

    public class PostEntry2
    {
        [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
        public Profile? Profile { get; set; }

        [JsonProperty("post", NullValueHandling = NullValueHandling.Ignore)]
        public EntryPost? Post { get; set; }
    }

    public class EntryProfile
    {
        [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
        public Profile? Profile { get; set; }
    }

    public class Profile
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("firstname", NullValueHandling = NullValueHandling.Ignore)]
        public string? Name { get; set; }

        [JsonProperty("picture", NullValueHandling = NullValueHandling.Ignore)]
        public Picture? Picture { get; set; }

        [JsonProperty("username", NullValueHandling = NullValueHandling.Ignore)]
        public string? Username { get; set; }

        [JsonProperty("bio", NullValueHandling = NullValueHandling.Ignore)]
        public string? Bio { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public class Picture
    {
        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public class EntryPost
    {
        [JsonProperty("post", NullValueHandling = NullValueHandling.Ignore)]
        public Post? Post { get; set; }

        [JsonProperty("comments", NullValueHandling = NullValueHandling.Ignore)]
        public Comment[]? Comments { get; set; }
    }

    public class Post
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("author", NullValueHandling = NullValueHandling.Ignore)]
        public Author? Author { get; set; }

        [JsonProperty("title", NullValueHandling = NullValueHandling.Ignore)]
        public string? Title { get; set; }

        [JsonProperty("caption", NullValueHandling = NullValueHandling.Ignore)]
        public Segment[]? Caption { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }

        [JsonProperty("images", NullValueHandling = NullValueHandling.Ignore)]
        public PostImage[]? Images { get; set; }

        [JsonProperty("likes", NullValueHandling = NullValueHandling.Ignore)]
        public int? Likes { get; set; }

        [JsonProperty("comments", NullValueHandling = NullValueHandling.Ignore)]
        public int? Comments { get; set; }

        [JsonProperty("views", NullValueHandling = NullValueHandling.Ignore)]
        public int? Views { get; set; }

        [JsonProperty("timestamp", NullValueHandling = NullValueHandling.Ignore)]
        public DateTime? Timestamp { get; set; }
    }

    public class Comment
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("text", NullValueHandling = NullValueHandling.Ignore)]
        public string? Text { get; set; }

        [JsonProperty("timestamp", NullValueHandling = NullValueHandling.Ignore)]
        public DateTime? Timestamp { get; set; }

        [JsonProperty("author", NullValueHandling = NullValueHandling.Ignore)]
        public Author? Author { get; set; }

        [JsonProperty("content", NullValueHandling = NullValueHandling.Ignore)]
        public Segment[]? Content { get; set; }
    }

    public class Author
    {
        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("firstname", NullValueHandling = NullValueHandling.Ignore)]
        public string? Name { get; set; }

        [JsonProperty("username", NullValueHandling = NullValueHandling.Ignore)]
        public string? Username { get; set; }

        [JsonProperty("picture", NullValueHandling = NullValueHandling.Ignore)]
        public Picture? Picture { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public class Segment
    {
        // "text", "tag", "person", "url"
        [JsonProperty("type", NullValueHandling = NullValueHandling.Ignore)]
        public string? Type { get; set; }

        [JsonProperty("value", NullValueHandling = NullValueHandling.Ignore)]
        public string? Value { get; set; }

        [JsonProperty("label", NullValueHandling = NullValueHandling.Ignore)]
        public string? Label { get; set; }

        [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
        public string? Id { get; set; }

        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    public class PostImage
    {
        [JsonProperty("url", NullValueHandling = NullValueHandling.Ignore)]
        public Uri? Url { get; set; }
    }

    #endregion

    #region New data

    public abstract class ReactIndexObject
    {
        protected readonly Dictionary<string, dynamic> _properties = [];

        public IDictionary<string, dynamic> Properties => _properties;

        public virtual IReadOnlyCollection<string> KnownRawProperties => Array.Empty<string>();

        public IReadOnlyList<string> GetUnknownRawPropertyNames()
        {
            var known = new HashSet<string>(KnownRawProperties, StringComparer.Ordinal);
            return _properties.Keys
                .Where(key => !known.Contains(key))
                .OrderBy(key => key, StringComparer.Ordinal)
                .ToArray();
        }

        protected void LoadIndices(dynamic[] reactData, dynamic indices)
        {
            foreach (var index in indices)
            {
                var name = index.Name;
                if (!name.StartsWith("_"))
                {
                    throw new Exception("Dynamic property name index malformed");
                }

                var nameIndex = int.Parse(name.Substring(1));
                var valueIndex = index.Value;
                if (valueIndex == -5)
                {
                    _properties.Add(reactData[nameIndex], null);
                }
                else
                {
                    var propertyValue = reactData[valueIndex];
                    if (propertyValue.GetType().IsArray)
                    {
                        var propertyList = new List<dynamic>();
                        foreach (var propIndex in propertyValue)
                        {
                            propertyList.Add(propIndex);
                        }

                        _properties.Add(reactData[nameIndex], propertyList);
                    }
                    else
                    {
                        _properties.Add(reactData[nameIndex], propertyValue);
                    }
                }
            }
        }

        protected bool HasProperty(string propertyName, bool treatNullAsMissing = false)
        {
            if (treatNullAsMissing)
            {
                return _properties.ContainsKey(propertyName) && _properties[propertyName] != null;
            }
            return _properties.ContainsKey(propertyName);
        }

        protected dynamic GetProperty(string propertyName)
        {
            return _properties[propertyName];
        }

        protected dynamic GetProperty(string propertyName, dynamic defaultValue)
        {
            if (!_properties.ContainsKey(propertyName))
            {
                return defaultValue;
            }
            return _properties[propertyName];
        }

        protected void Dump(string name, string[]? excludes = null, bool skipUnhandled = false)
        {
//#if DEBUG
//            var indentString = new string(' ', _indent * 2);
//            Console.Write(indentString);
//            Console.WriteLine(name);
//            var needsLabel = true;
//            foreach (var property in _properties.Keys)
//            {
//                if (excludes != null && excludes.IndexOf(property) != -1)
//                {
//                    continue;
//                }
//                if (needsLabel)
//                {
//                    Console.Write(indentString);
//                    Console.WriteLine("  properties:");
//                    needsLabel = false;
//                }
//                if (!skipUnhandled)
//                {
//                    Console.Write(indentString);
//                    Console.WriteLine("Found unhandled property " + property);
//                }
//                Console.Write(indentString);
//                var originalColor = Console.ForegroundColor;
//                Console.ForegroundColor = ConsoleColor.Red;
//                if (_properties[property] == null)
//                {
//                    Console.WriteLine("    {0}: NULL", property);
//                }
//                else
//                {
//                    Console.WriteLine("    {0} ({1}): {2}", property, _properties[property].GetType().Name, _properties[property]);
//                }
//                Console.ForegroundColor = originalColor;
//            }
//#endif
        }

        protected void DumpValue(string property, dynamic value)
        {
//#if DEBUG
//            var indentString = new string(' ', _indent * 2);
//            Console.Write(indentString);
//            var originalColor = Console.ForegroundColor;
//            Console.ForegroundColor = ConsoleColor.Green;
//            Console.WriteLine($"  {property}: {value}");
//            Console.ForegroundColor = originalColor;
//#endif
        }

        private static int _indent = 0;

        protected void ResetIndent()
        {
            _indent = 0;
        }

        protected void Indent()
        {
            ++_indent;
        }

        protected void Unindent()
        {
            --_indent;
        }

        public abstract string Name { get; }
    }

    public class ReactData : ReactIndexObject
    {
        public ReactData(dynamic[] reactData)
        {
            LoadIndices(reactData, reactData[0]);
            ResetIndent();
            Dump("Global", ["loaderData", "actionData", "errors"]);
            DumpValue("LoaderData", "{object}");
            DumpValue("ActionData", "{object}");
            DumpValue("Errors", "{object}");
            LoaderData = HasProperty("loaderData") ? new ReactLoaderData(reactData, GetProperty("loaderData")) : null;
            ActionData = HasProperty("actionData", true) ? new ReactActionData(reactData, GetProperty("actionData")) : null;
            Errors = HasProperty("errors", true) ? new ReactErrors(reactData, GetProperty("errors")) : null;
        }

        public override string Name => "Global";
        public override IReadOnlyCollection<string> KnownRawProperties => ["loaderData", "actionData", "errors"];

        public ReactLoaderData? LoaderData { get; }
        public ReactActionData? ActionData { get; }
        public ReactErrors? Errors { get; }
    }

    public class ReactLoaderData : ReactIndexObject
    {
        public ReactLoaderData(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("loaderData", ["root", "user-post", "post-only"]);
            DumpValue("Root", "{object}");
            DumpValue("UserPost", "{object}");
            Root = HasProperty("root") ? new ReactRoot(reactData, GetProperty("root")) : null;
            UserPost = HasProperty("user-post") ? new ReactUserPost(reactData, GetProperty("user-post")) : null;
            PostOnly = HasProperty("post-only") ? new ReactPostOnly(reactData, GetProperty("post-only")) : null;
            Unindent();
        }

        public override string Name => "loaderData";
        public override IReadOnlyCollection<string> KnownRawProperties => ["root", "user-post", "post-only"];

        public ReactRoot? Root { get; }
        public ReactUserPost? UserPost { get; }
        public ReactPostOnly? PostOnly { get; }
    }

    public class ReactRoot : ReactIndexObject
    {
        public ReactRoot(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("root", ["config", "systemInformation"]);
            DumpValue("Config", "{object}");
            DumpValue("SystemInformation", "{object}");
            Config = HasProperty("config") ? new ReactConfig(reactData, GetProperty("config")) : null;
            SystemInformation = HasProperty("systemInformation") ? new ReactSystemInformation(reactData, GetProperty("systemInformation")) : null;
            Unindent();
        }

        public override string Name => "root";
        public override IReadOnlyCollection<string> KnownRawProperties => ["config", "systemInformation"];

        public ReactConfig? Config { get; }
        public ReactSystemInformation? SystemInformation { get; }
    }

    public class ReactConfig : ReactIndexObject
    {
        public ReactConfig(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("config", ["CLIENT_API_URL", "CHAKRAY_API_URL", "USER_STORAGE_API_URL", "WEBVIEWS_URL", "VERO_WEBAPP_URL", "SLEEVE_WEBAPP_URL", "ITUNES_URL",
            "TMDB_URL", "APPLE_MUSIC_URL", "FEATURE_FLAG_WEBAPP", "FEATURE_FLAG_WIDGETS", "FEATURE_FLAG_COMMUNITY_TAGS", "FEATURE_FLAG_NSFW",
            "FEATURE_FLAG_VERO_3_CREATORS", "GROWTHBOOK_CLIENT_ID", "SPREECOMMERCE_API_URL", "VERO_FEATURED_API_URL", "VERO_VAULT_API_URL"]);
            DumpValue("ClientApiUrl", ClientApiUrl);
            DumpValue("ChakrayApiUrl", ChakrayApiUrl);
            DumpValue("UserStorageApiUrl", UserStorageApiUrl);
            DumpValue("WebViewsUrl", WebViewsUrl);
            DumpValue("VeroWebAppUrl", VeroWebAppUrl);
            DumpValue("SleeveWebAppUrl", SleeveWebAppUrl);
            DumpValue("iTunesUrl", iTunesUrl);
            DumpValue("TheMovieDBUrl", TheMovieDBUrl);
            DumpValue("AppleMusicUrl", AppleMusicUrl);
            DumpValue("WebApp", WebApp);
            DumpValue("Widgets", Widgets);
            DumpValue("CommunityTags", CommunityTags);
            DumpValue("Nsfw", Nsfw);
            DumpValue("Vero3Creators", Vero3Creators);
            DumpValue("GrowthBookClientId", GrowthBookClientId);
            DumpValue("SpreeCommerceApiUrl", SpreeCommerceApiUrl);
            DumpValue("VeroFeaturedApiUrl", VeroFeaturedApiUrl);
            DumpValue("VeroVaultApiUrl", VeroVaultApiUrl);
            Unindent();
        }

        public override string Name => "config";
        public override IReadOnlyCollection<string> KnownRawProperties => ["CLIENT_API_URL", "CHAKRAY_API_URL", "USER_STORAGE_API_URL", "WEBVIEWS_URL", "VERO_WEBAPP_URL", "SLEEVE_WEBAPP_URL", "ITUNES_URL",
            "TMDB_URL", "APPLE_MUSIC_URL", "FEATURE_FLAG_WEBAPP", "FEATURE_FLAG_WIDGETS", "FEATURE_FLAG_COMMUNITY_TAGS", "FEATURE_FLAG_NSFW",
            "FEATURE_FLAG_VERO_3_CREATORS", "GROWTHBOOK_CLIENT_ID", "SPREECOMMERCE_API_URL", "VERO_FEATURED_API_URL", "VERO_VAULT_API_URL"];

        public string ClientApiUrl => GetProperty("CLIENT_API_URL", "");
        public string ChakrayApiUrl => GetProperty("CHAKRAY_API_URL", "");
        public string UserStorageApiUrl => GetProperty("USER_STORAGE_API_URL", "");
        public string WebViewsUrl => GetProperty("WEBVIEWS_URL", "");
        public string VeroWebAppUrl => GetProperty("VERO_WEBAPP_URL", "");
        public string SleeveWebAppUrl => GetProperty("SLEEVE_WEBAPP_URL", "");
        public string iTunesUrl => GetProperty("ITUNES_URL", "");
        public string TheMovieDBUrl => GetProperty("TMDB_URL", "");
        public string AppleMusicUrl => GetProperty("APPLE_MUSIC_URL", "");
        public bool WebApp => GetProperty("FEATURE_FLAG_WEBAPP", false);
        public bool Widgets => GetProperty("FEATURE_FLAG_WIDGETS", false);
        public bool CommunityTags => GetProperty("FEATURE_FLAG_COMMUNITY_TAGS", false);
        public bool Nsfw => GetProperty("FEATURE_FLAG_NSFW", false);
        public bool Vero3Creators => GetProperty("FEATURE_FLAG_VERO_3_CREATORS", false);
        public string GrowthBookClientId => GetProperty("GROWTHBOOK_CLIENT_ID", "");
        public string SpreeCommerceApiUrl => GetProperty("SPREECOMMERCE_API_URL", "");
        public string VeroFeaturedApiUrl => GetProperty("VERO_FEATURED_API_URL", "");
        public string VeroVaultApiUrl => GetProperty("VERO_VAULT_API_URL", "");
    }

    public class ReactSystemInformation : ReactIndexObject
    {
        public ReactSystemInformation(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("systemInformation", ["preferredLanguage", "isMobileDevice", "userAgent", "osName"]);
            DumpValue("PreferredLanguage", PreferredLanguage);
            DumpValue("IsMobileDevice", IsMobileDevice);
            DumpValue("UserAgent", UserAgent);
            DumpValue("OsName", OsName);
            Unindent();
        }

        public override string Name => "systemInformation";
        public override IReadOnlyCollection<string> KnownRawProperties => ["preferredLanguage", "isMobileDevice", "userAgent", "osName"];

        public string PreferredLanguage => GetProperty("preferredLanguage", "");
        public bool IsMobileDevice => GetProperty("isMobileDevice", false);
        public string UserAgent => GetProperty("userAgent", "");
        public string OsName => GetProperty("osName", "");
    }

    public class ReactUserPost : ReactIndexObject
    {
        public ReactUserPost(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("user-post", ["profile", "post", "communityTagsOverview", "dehydratedQueryClient"]);
            DumpValue("CommunityTagsOverview", "{arrray}");
            DumpValue("DehydratedQueryClient", "{object}");
            DumpValue("Profile", "{object}");
            DumpValue("Post", "{object}");
            CommunityTagsOverview = [];
            if (HasProperty("communityTagsOverview"))
            {
                foreach (var index in GetProperty("communityTagsOverview"))
                {
                    CommunityTagsOverview.Add(new ReactCommunityTagsOverview(reactData, (int)index));
                }
            }
            DehydratedQueryClient = HasProperty("dehydratedQueryClient") ? new ReactDehydratedQueryClient(reactData, GetProperty("dehydratedQueryClient")) : null;
            Profile = HasProperty("profile") ? new ReactProfile(reactData, GetProperty("profile")) : null;
            Post = HasProperty("post") ? new ReactPost(reactData, GetProperty("post")) : null;
            Unindent();
        }

        public override string Name => "user-post";
        public override IReadOnlyCollection<string> KnownRawProperties => ["profile", "post", "communityTagsOverview", "dehydratedQueryClient"];

        public ReactProfile? Profile { get; }
        public ReactPost? Post { get; }
        public IList<ReactCommunityTagsOverview> CommunityTagsOverview { get; }
        public ReactDehydratedQueryClient? DehydratedQueryClient { get; }
    }

    public class ReactProfile : ReactIndexObject
    {
        public ReactProfile(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("profile", ["picture", "browsable", "id", "firstname", "lastname", "connectable", "username", "bio", "bio_lang", "url",
        "followable", "followers", "connections_count", "leads", "shorturl", "verified"]);
            DumpValue("Picture", "{object}");
            DumpValue("Browsable", Browsable);
            DumpValue("Id", Id);
            DumpValue("FirstName", FirstName);
            DumpValue("LastName", LastName ?? string.Empty);
            DumpValue("Connectable", Connectable);
            DumpValue("UserName", UserName);
            DumpValue("Bio", Bio.Replace("\\n", "\n").StripExtraSpaces(true));
            DumpValue("BioLang", BioLang);
            DumpValue("Url", Url);
            DumpValue("Followable", Followable);
            DumpValue("Followers", Followers);
            DumpValue("Connections", Connections);
            DumpValue("Leads", Leads);
            DumpValue("ShortUrl", ShortUrl);
            DumpValue("Verified", Verified);
            Picture = HasProperty("picture") ? new ReactPicture(reactData, GetProperty("picture")) : null;
            Unindent();
        }

        public override string Name => "profile";
        public override IReadOnlyCollection<string> KnownRawProperties => ["picture", "browsable", "id", "firstname", "lastname", "connectable", "username", "bio", "bio_lang", "url",
            "followable", "followers", "connections_count", "leads", "shorturl", "verified"];

        public ReactPicture? Picture { get; }
        public bool Browsable => GetProperty("browsable", false);
        public string Id => GetProperty("id", "");
        public string FirstName => GetProperty("firstname", "");
        public string LastName => GetProperty("lastname", "");
        public bool Connectable => GetProperty("connectable", false);
        public string UserName => GetProperty("username", "");
        public string Bio => GetProperty("bio", "");
        public string BioLang => GetProperty("bio_lang", "");
        public bool Followable => GetProperty("followable", false);
        public long Followers => GetProperty("followers", 0);
        public long Connections => GetProperty("connections_count", 0);
        public long Leads => GetProperty("leads", 0);
        public string ShortUrl => GetProperty("shorturl", "");
        public string Url => GetProperty("url", "");
        public bool Verified => GetProperty("verified", false);
    }

    public class ReactPicture : ReactIndexObject
    {
        public ReactPicture(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("picture", ["thumbnail", "url"]);
            DumpValue("Thumbnail", Thumbnail);
            DumpValue("Url", Url);
            Unindent();
        }

        public override string Name => "picture";
        public override IReadOnlyCollection<string> KnownRawProperties => ["thumbnail", "url"];

        public string Thumbnail => GetProperty("thumbnail", "");
        public string Url => GetProperty("url", "");
    }

    public class ReactPost : ReactIndexObject
    {
        public ReactPost(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("post", ["comments", "post", "embeddedMode"]);
            DumpValue("Comments", "{array}");
            DumpValue("Post", "{object}");
            DumpValue("EmbeddedMode", EmbeddedMode);
            Comments = [];
            if (HasProperty("comments"))
            {
                foreach (var index in GetProperty("comments"))
                {
                    Comments.Add(new ReactComment(reactData, (int)index));
                }
            }
            Post = HasProperty("post") ? new ReactPostPost(reactData, GetProperty("post")) : null;
            Unindent();
        }

        public override string Name => "post";
        public override IReadOnlyCollection<string> KnownRawProperties => ["comments", "post", "embeddedMode"];

        public IList<ReactComment> Comments { get; }
        public ReactPostPost? Post { get; }
        public bool EmbeddedMode => GetProperty("embeddedMode", false);
    }

    public class ReactComment : ReactIndexObject
    {
        public ReactComment(dynamic[] reactData, int objectIndex)
        {
            LoadIndices(reactData, reactData[objectIndex]);
            Indent();
            Dump("comment", ["id", "text", "timestamp", "author", "content", "replied_by_author", "language"]);
            DumpValue("Id", Id);
            DumpValue("Text", Text);
            DumpValue("Timestamp", Timestamp);
            DumpValue("Author", "{object}");
            DumpValue("Content", "{array}");
            DumpValue("RepliedByAuthor", RepliedByAuthor);
            DumpValue("Language", Language);
            Author = HasProperty("author") ? new ReactAuthor(reactData, GetProperty("author")) : null;
            Content = [];
            if (HasProperty("content"))
            {
                foreach (var index in GetProperty("content"))
                {
                    Content.Add(new ReactContent(reactData, (int)index));
                }
            }
            Unindent();
        }

        public override string Name => "comment";
        public override IReadOnlyCollection<string> KnownRawProperties => ["id", "text", "timestamp", "author", "content", "replied_by_author", "language"];

        public string Id => GetProperty("id", "");
        public string Text => GetProperty("text", "");
        public DateTime Timestamp => GetProperty("timestamp", DateTime.MinValue);
        public ReactAuthor? Author { get; }
        public IList<ReactContent> Content { get; }
        public bool RepliedByAuthor => GetProperty("replied_by_author", false);
        public string Language => GetProperty("language", "");
    }

    public class ReactScores : ReactIndexObject
    {
        public ReactScores(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("scores", ["nsfw"]);
            DumpValue("Nsfw", Nsfw);
            Unindent();
        }

        public override string Name => "scores";
        public override IReadOnlyCollection<string> KnownRawProperties => ["nsfw"];

        public double Nsfw => GetProperty("nsfw", 0.0);
    }

    public class ReactAuthor : ReactIndexObject
    {
        public ReactAuthor(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("author", ["id", "firstname", "username", "picture", "connectable", "verified", "followable", "following", "follower", "url"]);
            DumpValue("Id", Id);
            DumpValue("FirstName", FirstName);
            DumpValue("UserName", UserName);
            DumpValue("Picture", "{object}");
            DumpValue("Connectable", Connectable);
            DumpValue("Verified", Verified);
            DumpValue("Followable", Followable);
            DumpValue("Following", Following);
            DumpValue("Follower", Follower);
            DumpValue("Url", Url);
            Picture = HasProperty("picture") ? new ReactPicture(reactData, GetProperty("picture")) : null;
            Unindent();
        }

        public override string Name => "author";
        public override IReadOnlyCollection<string> KnownRawProperties => ["id", "firstname", "username", "picture", "connectable", "verified", "followable", "following", "follower", "url"];

        public ReactPicture? Picture { get; }
        public string Id => GetProperty("id", "");
        public string FirstName => GetProperty("firstname", "");
        public string UserName => GetProperty("username", "");
        public bool Connectable => GetProperty("connectable", false);
        public bool Verified => GetProperty("verified", false);
        public bool Followable => GetProperty("followable", false);
        public bool Following => GetProperty("following", false);
        public bool Follower => GetProperty("follower", false);
        public string Url => GetProperty("url", "");
    }

    public class ReactContent : ReactIndexObject
    {
        public ReactContent(dynamic[] reactData, int objectIndex)
        {
            LoadIndices(reactData, reactData[objectIndex]);
            Indent();
            switch (Type)
            {
                case "text":
                case "tag":
                    ValidateProperties(["value"]);
                    Dump("content", ["type", "value"]);
                    DumpValue("Type", Type);
                    DumpValue("Value", Value);
                    Unindent();
                    break;
                case "person":
                    ValidateProperties(["label", "id", "url"]);
                    Dump("content", ["type", "label", "id", "url"]);
                    DumpValue("Type", Type);
                    DumpValue("Label", Label);
                    DumpValue("Id", Id);
                    DumpValue("Url", Url);
                    Unindent();
                    break;
                case "url":
                    ValidateProperties(["value", "label"]);
                    Dump("content", ["type", "value", "label"]);
                    DumpValue("Type", Type);
                    DumpValue("Value", Value);
                    DumpValue("Label", Label);
                    Unindent();
                    break;
            }
        }

        public override string Name => "content";
        public override IReadOnlyCollection<string> KnownRawProperties => ["type", "value", "label", "id", "url"];

        private void ValidateProperties(string[] properties)
        {
            foreach (var property in _properties.Keys)
            {
                if (property != "type" && properties.IndexOf(property) == -1)
                {
                    throw new Exception($"Found unhandled property for type {Type}");
                }
            }
        }

        public string Type => GetProperty("type", "");
        public string Value => GetProperty("value", "");
        public string Label => GetProperty("label", "");
        public string Id => GetProperty("id", "");
        public string Url => GetProperty("url", "");
    }

    public class ReactPostPost : ReactIndexObject
    {
        public ReactPostPost(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("post", ["id", "time", "action", "object", "author", "title", "caption", "nsfw_post", "effective_nsfw_post", "loop", "url", "veroTags", "images",
        "likes", "comments", "views", "featured", "timestamp", "scores", "attributes", "language"]);
            DumpValue("Id", Id);
            DumpValue("Time", Time);
            DumpValue("Action", Action);
            DumpValue("Object", Object);
            DumpValue("Author", "{object}");
            DumpValue("Title", Title);
            DumpValue("Caption", "{array}");
            DumpValue("NsfwPost", NsfwPost);
            DumpValue("EffectiveNsfwPost", EffectiveNsfwPost);
            DumpValue("Loop", Loop);
            DumpValue("Url", Url);
            DumpValue("VeroTags", "{array}");
            DumpValue("Images", "{array}");
            DumpValue("Likes", Likes);
            DumpValue("Comments", Comments);
            DumpValue("Views", Views);
            DumpValue("Featured", Featured);
            DumpValue("Timestamp", Timestamp);
            DumpValue("Scores", "{object}");
            DumpValue("Attributes", "{object}");
            DumpValue("Language", Language);
            Author = HasProperty("author") ? new ReactAuthor(reactData, GetProperty("author")) : null;
            Caption = [];
            if (HasProperty("caption"))
            {
                foreach (var index in GetProperty("caption"))
                {
                    Caption.Add(new ReactContent(reactData, (int)index));
                }
            }

            VeroTags = [];
            if (HasProperty("veroTags"))
            {
                foreach (var index in GetProperty("veroTags"))
                {
                    VeroTags.Add(reactData[(int)index]);
                }
                DumpValue("VeroTags", string.Join(",", VeroTags));
            }

            Images = [];
            if (HasProperty("images"))
            {
                foreach (var index in GetProperty("images"))
                {
                    Images.Add(new ReactImage(reactData, (int)index));
                }
            }
            Scores = HasProperty("scores") ? new ReactScores(reactData, GetProperty("scores")) : null;
            Attributes = HasProperty("attributes") ? new ReactAttributes(reactData, GetProperty("attributes")) : null;
            Unindent();
        }

        public override string Name => "post";
        public override IReadOnlyCollection<string> KnownRawProperties => ["id", "time", "action", "object", "author", "title", "caption", "nsfw_post", "effective_nsfw_post", "loop", "url", "veroTags", "images",
            "likes", "comments", "views", "featured", "timestamp", "scores", "attributes", "language"];

        public string Id => GetProperty("id", "");
        public long Time => GetProperty("time", 0);
        public string Action => GetProperty("action", "");
        public string Object => GetProperty("object", "");
        public ReactAuthor? Author { get; }
        public string Title => GetProperty("title", "");
        public IList<ReactContent> Caption { get; }
        public bool NsfwPost => GetProperty("nsfw_post", false);
        public bool EffectiveNsfwPost => GetProperty("effective_nsfw_post", false);
        public string Loop => GetProperty("loop", "");
        public string Url => GetProperty("url", "");
        public IList<string> VeroTags { get; }
        public IList<ReactImage> Images { get; }
        public long Likes => GetProperty("likes", 0);
        public long Comments => GetProperty("comments", 0);
        public long Views => GetProperty("views", 0);
        public bool Featured => GetProperty("featured", false);
        public DateTime Timestamp => GetProperty("timestamp", DateTime.MinValue);
        public ReactScores? Scores { get; }
        public ReactAttributes? Attributes { get; }
        public string Language => GetProperty("language", "");
    }

    public class ReactAttributes : ReactIndexObject
    {
        public ReactAttributes(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("attributes", [], true);
            Unindent();
        }

        public override string Name => "attributes";
        public override IReadOnlyCollection<string> KnownRawProperties => Array.Empty<string>();
    }

    public class ReactImage : ReactIndexObject
    {
        public ReactImage(dynamic[] reactData, int objectIndex)
        {
            LoadIndices(reactData, reactData[objectIndex]);
            Indent();
            Dump("image", ["url", "width", "height", "thumbnail"]);
            DumpValue("Url", Url);
            DumpValue("Width", Width);
            DumpValue("Height", Height);
            DumpValue("Thumbnail", Thumbnail);
            Unindent();
        }

        public override string Name => "image";
        public override IReadOnlyCollection<string> KnownRawProperties => ["url", "width", "height", "thumbnail"];

        public string Url => GetProperty("url", "");
        public long Width => GetProperty("width", "");
        public long Height => GetProperty("height", "");
        public string Thumbnail => GetProperty("thumbnail", "");
    }

    public class ReactPostOnly : ReactIndexObject
    {
        public ReactPostOnly(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("post-only", ["post", "profile", "dehydratedQueryClient"]);
            DumpValue("Post", "{object}");
            DumpValue("Profile", "{object}");
            DumpValue("DehydratedQueryClient", "{object}");
            Post = HasProperty("post") ? new ReactPost(reactData, GetProperty("post")) : null;
            Profile = HasProperty("profile") ? new ReactProfile(reactData, GetProperty("profile")) : null;
            DehydratedQueryClient = HasProperty("dehydratedQueryClient") ? new ReactDehydratedQueryClient(reactData, GetProperty("dehydratedQueryClient")) : null;
            Unindent();
        }

        public override string Name => "post-only";
        public override IReadOnlyCollection<string> KnownRawProperties => ["post", "profile", "dehydratedQueryClient"];

        public ReactPost? Post { get; }
        public ReactProfile? Profile { get; }
        public ReactDehydratedQueryClient? DehydratedQueryClient { get; }
    }

    public class ReactCommunityTagsOverview : ReactIndexObject
    {
        public ReactCommunityTagsOverview(dynamic[] reactData, int objectIndex)
        {
            LoadIndices(reactData, reactData[objectIndex]);
            Indent();
            Dump("communityTagsOverview", ["tagId", "tagName"], true);
            Unindent();
        }

        public override string Name => "communityTagsOverview";
        public override IReadOnlyCollection<string> KnownRawProperties => ["tagId", "tagName"];

        public string TagId => GetProperty("tagId", "");
        public string TagName => GetProperty("tagName", "");
    }

    public class ReactDehydratedQueryClient : ReactIndexObject
    {
        public ReactDehydratedQueryClient(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("dehydratedQueryClient", [], true);
            Unindent();
        }

        public override string Name => "dehydratedQueryClient";
        public override IReadOnlyCollection<string> KnownRawProperties => Array.Empty<string>();

        // TODO : mutations (array)
        // TODO : queries (array)
    }

    public class ReactActionData : ReactIndexObject
    {
        public ReactActionData(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("actionData", [], true);
            Unindent();
        }

        public override string Name => "actionData";
        public override IReadOnlyCollection<string> KnownRawProperties => Array.Empty<string>();
    }

    public class ReactErrors : ReactIndexObject
    {
        public ReactErrors(dynamic[] reactData, dynamic indices)
        {
            LoadIndices(reactData, indices);
            Indent();
            Dump("errors", [], true);
            Unindent();
        }

        public override string Name => "errors";
        public override IReadOnlyCollection<string> KnownRawProperties => Array.Empty<string>();
    }

    #endregion
}

