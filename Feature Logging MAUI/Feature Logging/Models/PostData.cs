using Newtonsoft.Json;

namespace FeatureLogging.Models;

public class PostData
{
    public static PostData? FromJson(string json) => JsonConvert.DeserializeObject<PostData>(json);

    [JsonProperty("loaderData", NullValueHandling = NullValueHandling.Ignore)]
    public LoaderData? LoaderData { get; set; }
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

public class PostEntry
{
    [JsonProperty("profile", NullValueHandling = NullValueHandling.Ignore)]
    public EntryProfile? Profile { get; set; }

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
