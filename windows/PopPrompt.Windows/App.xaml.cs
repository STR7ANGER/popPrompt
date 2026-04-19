using System.Drawing;
using System.Diagnostics;
using System.Windows;
using Forms = System.Windows.Forms;
using PopPrompt.Windows.Services;
using PopPrompt.Windows.ViewModels;

namespace PopPrompt.Windows;

public partial class App : System.Windows.Application
{
    private Forms.NotifyIcon? _notifyIcon;
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
        var contextMenu = new Forms.ContextMenuStrip();
        contextMenu.Items.Add("Quit PopPrompt", null, (_, _) => QuitApplication());

        _notifyIcon = new Forms.NotifyIcon
        {
            Icon = Icon.ExtractAssociatedIcon(Process.GetCurrentProcess().MainModule!.FileName!) ?? SystemIcons.Application,
            Text = "PopPrompt",
            Visible = true,
            ContextMenuStrip = contextMenu
        };

        _notifyIcon.MouseUp += OnTrayIconMouseUp;
    }

    private void OnTrayIconMouseUp(object? sender, Forms.MouseEventArgs e)
    {
        if (e.Button == Forms.MouseButtons.Left)
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

        var cursorPosition = Forms.Cursor.Position;
        var screen = Forms.Screen.FromPoint(cursorPosition);
        var workingArea = screen.WorkingArea;
        var windowWidth = _mainWindow.Width;
        var windowHeight = _mainWindow.Height;

        _mainWindow.Left = workingArea.Left + ((workingArea.Width - windowWidth) / 2);
        _mainWindow.Top = workingArea.Top + ((workingArea.Height - windowHeight) / 2);
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
