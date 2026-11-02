using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Threading;
using PopPrompt.Windows.Helpers;
using PopPrompt.Windows.Models;
using PopPrompt.Windows.Services;

namespace PopPrompt.Windows.ViewModels;

public sealed class MainViewModel : INotifyPropertyChanged
{
    // Properties that depend on which screen is showing, the search, or the data.
    private static readonly string[] ScreenStateProperties =
    [
        nameof(IsInGroup),
        nameof(HeaderTitle),
        nameof(SearchPlaceholder),
        nameof(IsGroupListVisible),
        nameof(IsPromptListVisible),
        nameof(IsEmptyStateVisible),
        nameof(ShowGroupNames),
        nameof(EmptyStateTitle),
        nameof(EmptyStateBody),
        nameof(EmptyStateActionText),
        nameof(HasEmptyStateAction)
    ];

    private readonly PromptStoreService _store;
    private readonly Func<PromptEditorRequest, PromptEditorResult?> _requestPrompt;
    private readonly Func<string, string, string, string?> _requestGroupName;
    private string _searchText = string.Empty;
    private bool _isSearchVisible;
    private bool _isDialogOpen;
    private PromptGroup? _selectedGroup;
    private PromptGroup? _groupPendingDeletion;

    /// <param name="requestPrompt">Shows the prompt editor dialog; returns null if cancelled.</param>
    /// <param name="requestGroupName">Shows the group name dialog (heading, save label, initial name); returns null if cancelled.</param>
    public MainViewModel(
        PromptStoreService store,
        Func<PromptEditorRequest, PromptEditorResult?> requestPrompt,
        Func<string, string, string, string?> requestGroupName)
    {
        _store = store;
        _requestPrompt = requestPrompt;
        _requestGroupName = requestGroupName;

        Groups = new ObservableCollection<PromptGroup>(_store.Load());
        foreach (var group in Groups)
        {
            foreach (var prompt in group.Prompts)
            {
                prompt.GroupName = group.Name;
            }
        }

        VisiblePrompts = [];

        ToggleSearchCommand = new RelayCommand(ToggleSearch);
        AddCommand = new RelayCommand(Add);
        BackCommand = new RelayCommand(GoBack);
        OpenGroupCommand = new RelayCommand<PromptGroup>(OpenGroup);
        ToggleGroupActionsCommand = new RelayCommand<PromptGroup>(ToggleGroupActions);
        RenameGroupCommand = new RelayCommand<PromptGroup>(RenameGroup);
        DeleteGroupCommand = new RelayCommand<PromptGroup>(RequestDeleteGroup);
        ConfirmDeleteGroupCommand = new RelayCommand(ConfirmDeleteGroup);
        CancelDeleteGroupCommand = new RelayCommand(CancelDeleteGroup);
        EditPromptCommand = new RelayCommand<Prompt>(EditPrompt);
        DeletePromptCommand = new RelayCommand<Prompt>(DeletePrompt);
        CopyPromptCommand = new RelayCommand<Prompt>(CopyPrompt);
        ToggleExpandCommand = new RelayCommand<Prompt>(ToggleExpand);

        RefreshScreen();
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    /// <summary>Raised after switching screens; the argument is true when going into a group.</summary>
    public event Action<bool>? Navigated;

    public ObservableCollection<PromptGroup> Groups { get; }

    /// <summary>Prompts in the open group, or matches across all groups while searching the groups screen.</summary>
    public ObservableCollection<Prompt> VisiblePrompts { get; }

    public ICommand ToggleSearchCommand { get; }

    public ICommand AddCommand { get; }

    public ICommand BackCommand { get; }

    public ICommand OpenGroupCommand { get; }

    public ICommand ToggleGroupActionsCommand { get; }

    public ICommand RenameGroupCommand { get; }

    public ICommand DeleteGroupCommand { get; }

    public ICommand ConfirmDeleteGroupCommand { get; }

    public ICommand CancelDeleteGroupCommand { get; }

    public ICommand EditPromptCommand { get; }

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
            RefreshScreen();
        }
    }

    public bool IsDialogOpen
    {
        get => _isDialogOpen;
        set
        {
            if (value == _isDialogOpen)
            {
                return;
            }

            _isDialogOpen = value;
            OnPropertyChanged();
        }
    }

    public bool IsInGroup => _selectedGroup is not null;

    private bool IsSearching => !string.IsNullOrWhiteSpace(SearchText);

    public string HeaderTitle => _selectedGroup?.Name ?? "PopPrompt";

    public string SearchPlaceholder => _selectedGroup is null ? "Search all prompts" : $"Search in {_selectedGroup.Name}";

    public string SearchButtonBackground => IsSearchVisible ? "White" : "#14FFFFFF";

    public string SearchButtonForeground => IsSearchVisible ? "Black" : "White";

    public bool IsSearchEmpty => string.IsNullOrWhiteSpace(SearchText);

    public bool IsGroupListVisible => !IsInGroup && !IsSearching && Groups.Count > 0;

    public bool IsPromptListVisible => (IsInGroup || IsSearching) && VisiblePrompts.Count > 0;

    public bool IsEmptyStateVisible => !IsGroupListVisible && !IsPromptListVisible;

    public bool ShowGroupNames => !IsInGroup && IsSearching;

    public string EmptyStateTitle
    {
        get
        {
            if (IsSearching)
            {
                return "No matching prompts";
            }

            return IsInGroup ? "No prompts yet" : "No groups yet";
        }
    }

    public string EmptyStateBody
    {
        get
        {
            if (IsSearching)
            {
                return "Try a different title or keyword.";
            }

            return _selectedGroup is not null
                ? $"Tap the plus button to add one to {_selectedGroup.Name}."
                : "Tap the plus button to create your first group.";
        }
    }

    public string EmptyStateActionText => IsInGroup ? "Add Prompt" : "New Group";

    public bool HasEmptyStateAction => !IsSearching;

    public bool IsDeleteConfirmVisible => _groupPendingDeletion is not null;

    public string DeleteConfirmTitle => _groupPendingDeletion is null ? string.Empty : $"Delete “{_groupPendingDeletion.Name}”?";

    public string DeleteConfirmBody => _groupPendingDeletion?.Prompts.Count switch
    {
        null => string.Empty,
        0 => "This group is empty.",
        1 => "Its 1 prompt will be deleted too.",
        var count => $"Its {count} prompts will be deleted too."
    };

    /// <summary>Handles Esc. Returns false when there is nothing to back out of, so the window can hide.</summary>
    public bool HandleEscape()
    {
        if (IsDeleteConfirmVisible)
        {
            CancelDeleteGroup();
            return true;
        }

        if (IsInGroup)
        {
            GoBack();
            return true;
        }

        return false;
    }

    // Navigation

    private void OpenGroup(PromptGroup? group)
    {
        if (group is null)
        {
            return;
        }

        group.IsActionsVisible = false;
        _selectedGroup = group;
        ResetSearch();
        RefreshScreen();
        Navigated?.Invoke(true);
    }

    private void GoBack()
    {
        if (_selectedGroup is null)
        {
            return;
        }

        _selectedGroup = null;
        ResetSearch();
        RefreshGroups();
        RefreshScreen();
        Navigated?.Invoke(false);
    }

    private void ToggleSearch()
    {
        IsSearchVisible = !IsSearchVisible;
        if (!IsSearchVisible)
        {
            SearchText = string.Empty;
        }
    }

    private void ResetSearch()
    {
        IsSearchVisible = false;
        SearchText = string.Empty;
    }

    private void Add()
    {
        if (_selectedGroup is not null)
        {
            AddPrompt(_selectedGroup);
        }
        else
        {
            CreateGroup();
        }
    }

    // Groups

    private void CreateGroup()
    {
        var name = _requestGroupName("New Group", "Create", string.Empty);
        if (string.IsNullOrWhiteSpace(name))
        {
            return;
        }

        var group = new PromptGroup { Name = name.Trim() };
        Groups.Add(group);
        Save();
        OpenGroup(group);
    }

    private void ToggleGroupActions(PromptGroup? group)
    {
        if (group is null)
        {
            return;
        }

        group.IsActionsVisible = !group.IsActionsVisible;
        RefreshGroups();
    }

    private void RenameGroup(PromptGroup? group)
    {
        if (group is null)
        {
            return;
        }

        group.IsActionsVisible = false;
        var name = _requestGroupName("Rename Group", "Save", group.Name);
        if (!string.IsNullOrWhiteSpace(name))
        {
            group.Name = name.Trim();
            foreach (var prompt in group.Prompts)
            {
                prompt.GroupName = group.Name;
            }

            Save();
        }

        RefreshGroups();
        RefreshScreen();
    }

    private void RequestDeleteGroup(PromptGroup? group)
    {
        if (group is null)
        {
            return;
        }

        group.IsActionsVisible = false;
        _groupPendingDeletion = group;
        RefreshGroups();
        RaiseDeleteConfirmChanged();
    }

    private void ConfirmDeleteGroup()
    {
        if (_groupPendingDeletion is null)
        {
            return;
        }

        Groups.Remove(_groupPendingDeletion);
        _groupPendingDeletion = null;
        Save();
        RaiseDeleteConfirmChanged();
        RefreshScreen();
    }

    private void CancelDeleteGroup()
    {
        _groupPendingDeletion = null;
        RaiseDeleteConfirmChanged();
    }

    // Prompts

    private void AddPrompt(PromptGroup group)
    {
        var result = _requestPrompt(new PromptEditorRequest(
            "New Prompt",
            "Save a reusable prompt in a clean monochrome workspace.",
            "Save",
            string.Empty,
            string.Empty,
            Groups,
            group));

        if (result is null)
        {
            return;
        }

        result.Group.Prompts.Insert(0, new Prompt
        {
            Title = result.Title.Trim(),
            Content = result.Content.Trim(),
            CreatedAt = DateTime.UtcNow,
            GroupName = result.Group.Name
        });

        Save();
        RefreshGroups();
        RefreshScreen();
    }

    private void EditPrompt(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        var currentGroup = Groups.FirstOrDefault(group => group.Prompts.Contains(prompt));
        if (currentGroup is null)
        {
            return;
        }

        var result = _requestPrompt(new PromptEditorRequest(
            "Edit Prompt",
            "Update the prompt or move it to another group.",
            "Save Changes",
            prompt.Title,
            prompt.Content,
            Groups,
            currentGroup));

        if (result is null)
        {
            return;
        }

        prompt.Title = result.Title.Trim();
        prompt.Content = result.Content.Trim();

        if (result.Group != currentGroup)
        {
            currentGroup.Prompts.Remove(prompt);
            result.Group.Prompts.Insert(0, prompt);
            prompt.GroupName = result.Group.Name;
        }

        Save();
        RefreshGroups();
        RefreshScreen();
        RefreshPromptItems();
    }

    private void DeletePrompt(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        Groups.FirstOrDefault(group => group.Prompts.Contains(prompt))?.Prompts.Remove(prompt);
        Save();
        RefreshGroups();
        RefreshScreen();
    }

    private void ToggleExpand(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        prompt.IsExpanded = !prompt.IsExpanded;
        RefreshPromptItems();
    }

    private void CopyPrompt(Prompt? prompt)
    {
        if (prompt is null)
        {
            return;
        }

        System.Windows.Clipboard.SetText(prompt.Content);
        prompt.IsCopied = true;
        RefreshPromptItems();

        var timer = new DispatcherTimer
        {
            Interval = TimeSpan.FromSeconds(1.2)
        };

        timer.Tick += (_, _) =>
        {
            timer.Stop();
            prompt.IsCopied = false;
            RefreshPromptItems();
        };

        timer.Start();
    }

    // Refresh helpers

    /// <summary>Rebuilds the visible prompt list and re-evaluates every screen-dependent property.</summary>
    private void RefreshScreen()
    {
        IEnumerable<Prompt> prompts;
        if (_selectedGroup is not null)
        {
            prompts = _selectedGroup.Prompts.Where(Matches);
        }
        else if (IsSearching)
        {
            prompts = Groups.SelectMany(group => group.Prompts).Where(Matches);
        }
        else
        {
            prompts = [];
        }

        VisiblePrompts.Clear();
        foreach (var prompt in prompts)
        {
            VisiblePrompts.Add(prompt);
        }

        foreach (var propertyName in ScreenStateProperties)
        {
            OnPropertyChanged(propertyName);
        }
    }

    // Prompt and PromptGroup don't raise change notifications, so their cards are re-rendered via Refresh.
    private void RefreshPromptItems() => CollectionViewSource.GetDefaultView(VisiblePrompts).Refresh();

    private void RefreshGroups() => CollectionViewSource.GetDefaultView(Groups).Refresh();

    private void RaiseDeleteConfirmChanged()
    {
        OnPropertyChanged(nameof(IsDeleteConfirmVisible));
        OnPropertyChanged(nameof(DeleteConfirmTitle));
        OnPropertyChanged(nameof(DeleteConfirmBody));
    }

    private bool Matches(Prompt prompt)
    {
        if (!IsSearching)
        {
            return true;
        }

        var query = SearchText.Trim();
        return prompt.Title.Contains(query, StringComparison.OrdinalIgnoreCase) ||
               prompt.Content.Contains(query, StringComparison.OrdinalIgnoreCase);
    }

    private void Save()
    {
        _store.Save(Groups);
    }

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}
