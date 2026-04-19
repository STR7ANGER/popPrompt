using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using PopPrompt.Windows.ViewModels;

namespace PopPrompt.Windows;

public partial class MainWindow : Window
{
    private readonly MainViewModel _viewModel;
    private bool _allowClose;

    public MainWindow(MainViewModel viewModel)
    {
        InitializeComponent();
        _viewModel = viewModel;
        DataContext = _viewModel;

        Deactivated += OnDeactivated;
        PreviewKeyDown += OnPreviewKeyDown;
        Closing += OnClosing;
    }

    public void CloseFromApp()
    {
        _allowClose = true;
        Close();
    }

    private void OnDeactivated(object? sender, EventArgs e)
    {
        if (!_viewModel.IsAddDialogOpen && IsVisible)
        {
            Hide();
        }
    }

    private void OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            Hide();
            e.Handled = true;
        }
    }

    private void OnClosing(object? sender, CancelEventArgs e)
    {
        if (_allowClose)
        {
            return;
        }

        e.Cancel = true;
        Hide();
    }
}
