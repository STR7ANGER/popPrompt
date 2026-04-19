using System.Drawing;
using System.Windows;
using System.Windows.Forms;
using PopPrompt.Windows.Services;
using PopPrompt.Windows.ViewModels;

namespace PopPrompt.Windows;

public partial class App : Application
{
    private NotifyIcon? _notifyIcon;
    private MainWindow? _mainWindow;
    private MainViewModel? _mainViewModel;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var store = new PromptStoreService();
        _mainViewModel = new MainViewModel(store, OpenAddPromptWindow);
        _mainWindow = new MainWindow(_mainViewModel);
        _mainWindow.Hide();

        ConfigureTrayIcon();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (_notifyIcon is not null)
        {
            _notifyIcon.Visible = false;
            _notifyIcon.Dispose();
        }

        base.OnExit(e);
    }

    private void ConfigureTrayIcon()
    {
        var contextMenu = new ContextMenuStrip();
        contextMenu.Items.Add("Quit PopPrompt", null, (_, _) => QuitApplication());

        _notifyIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "PopPrompt",
            Visible = true,
            ContextMenuStrip = contextMenu
        };

        _notifyIcon.MouseUp += OnTrayIconMouseUp;
    }

    private void OnTrayIconMouseUp(object? sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left)
        {
            ToggleMainWindow();
        }
    }

    private void ToggleMainWindow()
    {
        if (_mainWindow is null)
        {
            return;
        }

        if (_mainWindow.IsVisible)
        {
            _mainWindow.Hide();
            return;
        }

        PositionMainWindow();
        _mainWindow.Show();
        _mainWindow.Activate();
        _mainWindow.Topmost = true;
        _mainWindow.Topmost = false;
        _mainWindow.Focus();
    }

    private void PositionMainWindow()
    {
        if (_mainWindow is null)
        {
            return;
        }

        var cursorPosition = Cursor.Position;
        var screen = Screen.FromPoint(cursorPosition);
        var area = screen.WorkingArea;

        _mainWindow.Left = area.Right - _mainWindow.Width - 20;
        _mainWindow.Top = area.Bottom - _mainWindow.Height - 20;
    }

    private void OpenAddPromptWindow()
    {
        if (_mainWindow is null || _mainViewModel is null)
        {
            return;
        }

        _mainViewModel.IsAddDialogOpen = true;

        try
        {
            var dialog = new AddPromptWindow
            {
                Owner = _mainWindow,
                WindowStartupLocation = WindowStartupLocation.CenterOwner
            };

            if (dialog.ShowDialog() == true)
            {
                _mainViewModel.AddPrompt(dialog.PromptTitle, dialog.PromptContent);
            }
        }
        finally
        {
            _mainViewModel.IsAddDialogOpen = false;
            if (_mainWindow.IsVisible)
            {
                _mainWindow.Activate();
            }
        }
    }

    private void QuitApplication()
    {
        _mainWindow?.CloseFromApp();
        Shutdown();
    }
}
