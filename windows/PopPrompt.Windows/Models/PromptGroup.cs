using System.Text.Json.Serialization;

namespace PopPrompt.Windows.Models;

public sealed class PromptGroup
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<Prompt> Prompts { get; set; } = [];

    [JsonIgnore]
    public bool IsActionsVisible { get; set; }

    [JsonIgnore]
    public string CountDisplay => Prompts.Count == 1 ? "1 prompt" : $"{Prompts.Count} prompts";
}
