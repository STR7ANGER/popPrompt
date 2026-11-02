using System.Windows;
using System.Windows.Input;
using PopPrompt.Windows.Models;
using PopPrompt.Windows.ViewModels;

namespace PopPrompt.Windows;

/// <summary>Dialog for adding a new prompt or editing an existing one, including which group it lives in.</summary>
public partial class PromptEditorWindow : Window
{
    public PromptEditorWindow(PromptEditorRequest request)
    {
        InitializeComponent();

        HeadingText.Text = request.Heading;
        SubtitleText.Text = request.Subtitle;
        SaveButton.Content = request.SaveLabel;
        TitleTextBox.Text = request.Title;
        ContentTextBox.Text = request.Content;

        GroupListBox.ItemsSource = request.Groups;
        GroupListBox.SelectedItem = request.SelectedGroup;
        GroupSection.Visibility = request.Groups.Count > 1 ? Visibility.Visible : Visibility.Collapsed;

        Loaded += (_, _) => TitleTextBox.Focus();
        PreviewKeyDown += OnPreviewKeyDown;
    }

    public string PromptTitle => TitleTextBox.Text.Trim();

    public string PromptContent => ContentTextBox.Text.Trim();

    public PromptGroup? SelectedGroup => GroupListBox.SelectedItem as PromptGroup;

    // Ctrl+Enter saves, since plain Enter adds a new line in the content box.
    private void OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == Key.Enter && Keyboard.Modifiers.HasFlag(ModifierKeys.Control))
        {
            TrySave();
            e.Handled = true;
        }
    }

    private void OnSaveClick(object sender, RoutedEventArgs e)
    {
        TrySave();
    }

    private void TrySave()
    {
        if (string.IsNullOrWhiteSpace(PromptTitle) || string.IsNullOrWhiteSpace(PromptContent) || SelectedGroup is null)
        {
            return;
        }

        DialogResult = true;
        Close();
    }
}
