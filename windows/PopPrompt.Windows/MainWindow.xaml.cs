using System.ComponentModel;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
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
        _viewModel.Navigated += OnNavigated;
    }

    public void CloseFromApp()
    {
        _allowClose = true;
        Close();
    }

    private void OnDeactivated(object? sender, EventArgs e)
    {
        if (!_viewModel.IsDialogOpen && IsVisible)
        {
            Hide();
        }
    }

    private void OnPreviewKeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (!_viewModel.HandleEscape())
            {
                Hide();
            }

            e.Handled = true;
        }
    }

    // Slides the screen in from the side it's navigating towards.
    private void OnNavigated(bool intoGroup)
    {
        var duration = TimeSpan.FromMilliseconds(200);
        var easing = new CubicEase { EasingMode = EasingMode.EaseOut };

        ScreenTranslate.BeginAnimation(
            TranslateTransform.XProperty,
            new DoubleAnimation(intoGroup ? 40 : -40, 0, duration) { EasingFunction = easing });
        ScreenHost.BeginAnimation(
            OpacityProperty,
            new DoubleAnimation(0, 1, duration) { EasingFunction = easing });
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
