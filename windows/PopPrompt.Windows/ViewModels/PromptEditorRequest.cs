using PopPrompt.Windows.Models;

namespace PopPrompt.Windows.ViewModels;

/// <summary>What the prompt editor dialog should show.</summary>
public sealed record PromptEditorRequest(
    string Heading,
    string Subtitle,
    string SaveLabel,
    string Title,
    string Content,
    IReadOnlyList<PromptGroup> Groups,
    PromptGroup SelectedGroup);

/// <summary>What the user saved from the prompt editor dialog.</summary>
public sealed record PromptEditorResult(string Title, string Content, PromptGroup Group);
