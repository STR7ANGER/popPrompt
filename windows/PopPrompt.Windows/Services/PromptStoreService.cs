using System.IO;
using System.Text.Json;
using PopPrompt.Windows.Models;

namespace PopPrompt.Windows.Services;

public sealed class PromptStoreService
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true
    };

    private readonly string _filePath;

    public PromptStoreService()
    {
        var appDataFolder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "PopPrompt"
        );

        _filePath = Path.Combine(appDataFolder, "prompts.json");
    }

    public IReadOnlyList<Prompt> Load()
    {
        try
        {
            if (!File.Exists(_filePath))
            {
                return DefaultPrompts();
            }

            var json = File.ReadAllText(_filePath);
            var prompts = JsonSerializer.Deserialize<List<Prompt>>(json, SerializerOptions);
            if (prompts is null)
            {
                return DefaultPrompts();
            }

            return prompts
                .OrderByDescending(prompt => prompt.CreatedAt)
                .ToList();
        }
        catch
        {
            return DefaultPrompts();
        }
    }

    public void Save(IEnumerable<Prompt> prompts)
    {
        var directory = Path.GetDirectoryName(_filePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var json = JsonSerializer.Serialize(prompts, SerializerOptions);
        File.WriteAllText(_filePath, json);
    }

    private static IReadOnlyList<Prompt> DefaultPrompts()
    {
        return
        [
            new Prompt
            {
                Title = "Welcome Prompt",
                Content = "Store your favorite prompts here, then copy them into any app with one click.",
                CreatedAt = DateTime.UtcNow
            }
        ];
    }
}
