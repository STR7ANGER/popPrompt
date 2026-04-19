using System.Windows;

namespace PopPrompt.Windows;

public partial class AddPromptWindow : Window
{
    public AddPromptWindow()
    {
        InitializeComponent();
        Loaded += (_, _) => TitleTextBox.Focus();
    }

    public string PromptTitle => TitleTextBox.Text.Trim();

    public string PromptContent => ContentTextBox.Text.Trim();

    private void OnCloseClick(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }

    private void OnSaveClick(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(PromptTitle) || string.IsNullOrWhiteSpace(PromptContent))
        {
            return;
        }

        DialogResult = true;
        Close();
    }
}
