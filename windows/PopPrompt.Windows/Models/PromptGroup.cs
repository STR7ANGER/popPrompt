namespace PopPrompt.Windows.Models;

public sealed class PromptGroup
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<Prompt> Prompts { get; set; } = [];
}
