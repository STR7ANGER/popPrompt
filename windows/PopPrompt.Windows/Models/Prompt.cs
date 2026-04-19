using System.Text.Json.Serialization;

namespace PopPrompt.Windows.Models;

public sealed class Prompt
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Title { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [JsonIgnore]
    public bool IsExpanded { get; set; }

    [JsonIgnore]
    public bool IsCopied { get; set; }

    [JsonIgnore]
    public string CreatedAtDisplay => CreatedAt.ToLocalTime().ToString("MMM d, yyyy h:mm tt");
}
