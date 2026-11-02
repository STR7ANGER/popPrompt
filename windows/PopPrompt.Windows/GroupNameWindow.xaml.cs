using System.Windows;

namespace PopPrompt.Windows;

public partial class GroupNameWindow : Window
{
    public GroupNameWindow(string heading, string saveLabel, string initialName)
    {
        InitializeComponent();
        HeadingText.Text = heading;
        SaveButton.Content = saveLabel;
        NameTextBox.Text = initialName;

        Loaded += (_, _) =>
        {
            NameTextBox.Focus();
            NameTextBox.SelectAll();
        };
    }

    public string GroupName => NameTextBox.Text.Trim();

    private void OnNameChanged(object sender, System.Windows.Controls.TextChangedEventArgs e)
    {
        PlaceholderText.Visibility = NameTextBox.Text.Length == 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private void OnSaveClick(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(GroupName))
        {
            return;
        }

        DialogResult = true;
        Close();
    }
}
