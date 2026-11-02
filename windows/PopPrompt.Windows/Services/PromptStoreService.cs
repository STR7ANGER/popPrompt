using System.IO;
using System.Text.Json;
using PopPrompt.Windows.Models;

namespace PopPrompt.Windows.Services;

public sealed class PromptStoreService
{
    public const string MigratedGroupName = "My Prompts";

    private const string LegacyWelcomeTitle = "Welcome Prompt";
    private const string LegacyWelcomeContent = "Store your favorite prompts here, then copy them into any app with one click.";
    private const string DefaultGroupsResourceName = "PopPrompt.Windows.default-groups.json";

    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true
    };

    private readonly string _groupsFilePath;
    // v1.0 stored a flat prompt list here. It is read once for migration and left untouched.
    private readonly string _legacyPromptsFilePath;
    // Set once the bundled starter groups have been added, so deleting them is permanent.
    private bool _didSeedDefaults;

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
        var library = ReadLibrary() ?? new PromptLibrary { Groups = MigrateLegacyPrompts() };

        if (!library.DidSeedDefaults)
        {
            var defaultGroups = LoadDefaultGroups();
            if (defaultGroups.Count > 0)
            {
                library.Groups.InsertRange(0, defaultGroups);
                library.DidSeedDefaults = true;
            }
        }

        _didSeedDefaults = library.DidSeedDefaults;
        Save(library.Groups);
        return library.Groups;
    }

    public void Save(IEnumerable<PromptGroup> groups)
    {
        var directory = Path.GetDirectoryName(_groupsFilePath);
        if (!string.IsNullOrEmpty(directory))
        {
            Directory.CreateDirectory(directory);
        }

        var library = new PromptLibrary
        {
            DidSeedDefaults = _didSeedDefaults,
            Groups = groups.ToList()
        };

        // Write to a temp file first so a crash mid-write can't corrupt the saved groups.
        var tempPath = _groupsFilePath + ".tmp";
        var json = JsonSerializer.Serialize(library, SerializerOptions);
        File.WriteAllText(tempPath, json);
        File.Move(tempPath, _groupsFilePath, overwrite: true);
    }

    /// <summary>Returns the saved library, or null if there isn't a readable one yet.</summary>
    private PromptLibrary? ReadLibrary()
    {
        if (!File.Exists(_groupsFilePath))
        {
            return null;
        }

        try
        {
            var json = File.ReadAllText(_groupsFilePath);
            return JsonSerializer.Deserialize<PromptLibrary>(json, SerializerOptions);
        }
        catch
        {
            // Keep the unreadable file around rather than silently overwriting it.
            try
            {
                File.Copy(_groupsFilePath, _groupsFilePath + ".bak", overwrite: true);
            }
            catch
            {
                // Best effort only.
            }

            return null;
        }
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

    /// <summary>Starter groups from shared/default-groups.json, which both the macOS and Windows apps bundle.</summary>
    private static List<PromptGroup> LoadDefaultGroups()
    {
        try
        {
            using var stream = typeof(PromptStoreService).Assembly.GetManifestResourceStream(DefaultGroupsResourceName);
            if (stream is null)
            {
                return [];
            }

            var file = JsonSerializer.Deserialize<DefaultGroupsFile>(stream, SerializerOptions);
            return file?.Groups
                .Select(group => new PromptGroup
                {
                    Name = group.Name,
                    Prompts = group.Prompts
                        .Select(item => new Prompt { Title = item.Title, Content = item.Content })
                        .ToList()
                })
                .ToList() ?? [];
        }
        catch
        {
            return [];
        }
    }

    private sealed class PromptLibrary
    {
        public bool DidSeedDefaults { get; set; }

        public List<PromptGroup> Groups { get; set; } = [];
    }

    private sealed class DefaultGroupsFile
    {
        public List<DefaultGroup> Groups { get; set; } = [];
    }

    private sealed class DefaultGroup
    {
        public string Name { get; set; } = string.Empty;

        public List<DefaultPrompt> Prompts { get; set; } = [];
    }

    private sealed class DefaultPrompt
    {
        public string Title { get; set; } = string.Empty;

        public string Content { get; set; } = string.Empty;
    }
}
