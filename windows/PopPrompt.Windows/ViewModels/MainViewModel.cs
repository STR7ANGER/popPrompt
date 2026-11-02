using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Threading;
using PopPrompt.Windows.Helpers;
using PopPrompt.Windows.Models;
using PopPrompt.Windows.Services;

namespace PopPrompt.Windows.ViewModels;

public sealed class MainViewModel : INotifyPropertyChanged
{
    private readonly PromptStoreService _store;
    private readonly Action _requestOpenAddPrompt;
    private readonly List<PromptGroup> _groups;
    private string _searchText = string.Empty;
    private bool _isSearchVisible;
    private bool _isAddDialogOpen;

    public MainViewModel(PromptStoreService store, Action requestOpenAddPrompt)
    {
        _store = store;
        _requestOpenAddPrompt = requestOpenAddPrompt;

        _groups = _store.Load();
        // Interim flat view over all groups until the groups screen lands.
        Prompts = new ObservableCollection<Prompt>(_groups.SelectMany(group => group.Prompts));
        PromptsView = CollectionViewSource.GetDefaultView(Prompts);
        PromptsView.Filter = FilterPrompt;

        Prompts.CollectionChanged += (_, _) =>
        {
            SavePrompts();
            OnPropertyChanged(nameof(HasPrompts));
            OnPropertyChanged(nameof(EmptyStateTitle));
            OnPropertyChanged(nameof(EmptyStateBody));
            PromptsView.Refresh();
        };

        ToggleSearchCommand = new RelayCommand(ToggleSearch);
        OpenAddPromptCommand = new RelayCommand(() => _requestOpenAddPrompt());
        DeletePromptCommand = new RelayCommand<Prompt>(DeletePrompt);
        CopyPromptCommand = new RelayCommand<Prompt>(CopyPrompt);
        ToggleExpandCommand = new RelayCommand<Prompt>(ToggleExpand);
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    public ObservableCollection<Prompt> Prompts { get; }

    public ICollectionView PromptsView { get; }

    public ICommand ToggleSearchCommand { get; }

    public ICommand OpenAddPromptCommand { get; }

    public ICommand DeletePromptCommand { get; }

    public ICommand CopyPromptCommand { get; }

    public ICommand ToggleExpandCommand { get; }

    public bool IsSearchVisible
    {
        get => _isSearchVisible;
        set
        {
            if (value == _isSearchVisible)
            {
                return;
            }

            _isSearchVisible = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(SearchButtonBackground));
            OnPropertyChanged(nameof(SearchButtonForeground));
        }
    }

    public string SearchText
    {
        get => _searchText;
        set
        {
            if (value == _searchText)
            {
                return;
            }

            _searchText = value;
            OnPropertyChanged();
            OnPropertyChanged(nameof(IsSearchEmpty));
            PromptsView.Refresh();
            OnPropertyChanged(nameof(HasPrompts));
            OnPropertyChanged(nameof(EmptyStateTitle));
            OnPropertyChanged(nameof(EmptyStateBody));
        }
    }

    public bool HasPrompts => PromptsView.Cast<object>().Any();

    public bool IsAddDialogOpen
    {
        get => _isAddDialogOpen;
        set
        {
            if (value == _isAddDialogOpen)
            {
                return;
            }

            _isAddDialogOpen = value;
            OnPropertyChanged();
        }
    }

    public string SearchButtonBackground => IsSearchVisible ? "White" : "#14FFFFFF";

    public string SearchButtonForeground => IsSearchVisible ? "Black" : "White";

    public bool IsSearchEmpty => string.IsNullOrWhiteSpace(SearchText);

    public string EmptyStateTitle => string.IsNullOrWhiteSpace(SearchText) ? "No prompts yet" : "No matching prompts";

    public string EmptyStateBody => string.IsNullOrWhiteSpace(SearchText)
        ? "Tap the plus button to save your first prompt."
        : "Try a different title or keyword.";

    public void AddPrompt(string title, string content)
    {
        var group = _groups.FirstOrDefault();
        if (group is null)
        {
            group = new PromptGroup { Name = PromptStoreService.MigratedGroupName };
            _groups.Add(group);
        }

        var prompt = new Prompt
        {
            Title = title.Trim(),
            Content = content.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        // Update the group before the collection so the CollectionChanged save sees it.
        group.Prompts.Insert(0, prompt);
        Prompts.Insert(0, prompt);
    }

    private void ToggleSearch()
    {
        IsSearchVisible = !IsSearchVisible;
        if (!IsSearchVisible)
        {
            SearchText = string.Empty;
        }
    }

    private void DeletePrompt(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        _groups.FirstOrDefault(group => group.Prompts.Contains(prompt))?.Prompts.Remove(prompt);
        Prompts.Remove(prompt);
    }

    private void ToggleExpand(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        prompt.IsExpanded = !prompt.IsExpanded;
        PromptsView.Refresh();
    }

    private void CopyPrompt(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        System.Windows.Clipboard.SetText(prompt.Content);
        prompt.IsCopied = true;
        PromptsView.Refresh();

        var timer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(1.2)
        };

        timer.Tick += (_, _) =>
        {
            timer.Stop();
            prompt.IsCopied = false;
            PromptsView.Refresh();
        };

        timer.Start();
    }

    private bool FilterPrompt(object item)
    {
        if (item is not Prompt prompt)
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(SearchText))
        {
            return true;
        }

        return prompt.Title.Contains(SearchText, StringComparison.OrdinalIgnoreCase) ||
               prompt.Content.Contains(SearchText, StringComparison.OrdinalIgnoreCase);
    }

    private void SavePrompts()
    {
        _store.Save(_groups);
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
