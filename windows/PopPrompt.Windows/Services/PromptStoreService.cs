using System.IO;
using System.Text.Json;
using PopPrompt.Windows.Models;

namespace PopPrompt.Windows.Services;

public sealed class PromptStoreService
{
    public const string MigratedGroupName = "My Prompts";

    private const string LegacyWelcomeTitle = "Welcome Prompt";
    private const string LegacyWelcomeContent = "Store your favorite prompts here, then copy them into any app with one click.";

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true
    };

    private readonly string _groupsFilePath;
    // v1.0 stored a flat prompt list here. It is read once for migration and left untouched.
    private readonly string _legacyPromptsFilePath;

    public PromptStoreService()
    {
        var appDataFolder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "PopPrompt"
        );

        _groupsFilePath = Path.Combine(appDataFolder, "groups.json");
        _legacyPromptsFilePath = Path.Combine(appDataFolder, "prompts.json");
    }

    public List<PromptGroup> Load()
    {
        if (File.Exists(_groupsFilePath))
        {
            try
            {
                var json = File.ReadAllText(_groupsFilePath);
                return JsonSerializer.Deserialize<List<PromptGroup>>(json, SerializerOptions) ?? [];
            }
            catch
            {
                return [];
            }
        }

        var migrated = MigrateLegacyPrompts();
        Save(migrated);
        return migrated;
    }

    public void Save(IEnumerable<PromptGroup> groups)
    {
        var directory = Path.GetDirectoryName(_groupsFilePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        // Write to a temp file first so a crash mid-write can't corrupt the saved groups.
        var tempPath = _groupsFilePath + ".tmp";
        var json = JsonSerializer.Serialize(groups, SerializerOptions);
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, _groupsFilePath, overwrite: true);
    }

    private List<PromptGroup> MigrateLegacyPrompts()
    {
        try
        {
            if (!File.Exists(_legacyPromptsFilePath))
            {
                return [];
            }

            var json = File.ReadAllText(_legacyPromptsFilePath);
            var legacyPrompts = JsonSerializer.Deserialize<List<Prompt>>(json, SerializerOptions) ?? [];
            var keptPrompts = legacyPrompts
                .Where(prompt => !(prompt.Title == LegacyWelcomeTitle && prompt.Content == LegacyWelcomeContent))
                .OrderByDescending(prompt => prompt.CreatedAt)
                .ToList();

            if (keptPrompts.Count == 0)
            {
                return [];
            }

            return
            [
                new PromptGroup
                {
                    Name = MigratedGroupName,
                    Prompts = keptPrompts
                }
            ];
        }
        catch
        {
            return [];
        }
    }
}
