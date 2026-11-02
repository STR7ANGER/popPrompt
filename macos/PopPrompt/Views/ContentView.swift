import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore

    @State private var selectedGroupID: PromptGroup.ID?
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var activeSheet: ActiveSheet?
    @State private var groupPendingDeletion: PromptGroup?

    private enum ActiveSheet: Identifiable {
        case newGroup
        case renameGroup(PromptGroup)
        case newPrompt(PromptGroup.ID)

        var id: String {
            switch self {
            case .newGroup: "new-group"
            case .renameGroup(let group): "rename-\(group.id)"
            case .newPrompt(let groupID): "new-prompt-\(groupID)"
            }
        }
    }

    private var selectedGroup: PromptGroup? {
        store.group(withID: selectedGroupID)
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 14) {
                header

                if showSearch {
                    searchField
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ZStack {
                    if let group = selectedGroup {
                        GroupDetailView(group: group, searchText: searchText) {
                            activeSheet = .newPrompt(group.id)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        GroupListView(
                            searchText: searchText,
                            onOpen: open,
                            onCreate: { activeSheet = .newGroup },
                            onRename: { activeSheet = .renameGroup($0) },
                            onDelete: { group in
                                withAnimation(.panel) { groupPendingDeletion = group }
                            }
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            }
            .padding(16)

            if let group = groupPendingDeletion {
                deleteConfirmation(for: group)
                    .transition(.opacity)
            }
        }
        .frame(width: 430, height: 560)
        .background(Color.black)
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
        }
        .animation(.panel, value: showSearch)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            if selectedGroup != nil {
                HeaderIconButton(systemName: "chevron.left", action: goBack)
                    .keyboardShortcut(.cancelAction)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Text(selectedGroup?.name ?? "PopPrompt")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .id(selectedGroupID)
                .transition(.opacity)

            Spacer(minLength: 0)

            HeaderIconButton(systemName: "magnifyingglass", isActive: showSearch) {
                showSearch.toggle()
                if !showSearch {
                    searchText = ""
                }
            }

            HeaderIconButton(systemName: "plus") {
                if let selectedGroupID {
                    activeSheet = .newPrompt(selectedGroupID)
                } else {
                    activeSheet = .newGroup
                }
            }
        }
    }

    private var searchField: some View {
        TextField(selectedGroup.map { "Search in \($0.name)" } ?? "Search all prompts", text: $searchText)
            .textFieldStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(.white)
    }

    // MARK: - Navigation

    private func open(_ group: PromptGroup) {
        withAnimation(.panel) {
            resetSearch()
            selectedGroupID = group.id
        }
    }

    private func goBack() {
        withAnimation(.panel) {
            resetSearch()
            selectedGroupID = nil
        }
    }

    private func resetSearch() {
        showSearch = false
        searchText = ""
    }

    // MARK: - Sheets

    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .newGroup:
            GroupNameView(heading: "New Group", saveTitle: "Create") { name in
                open(store.addGroup(name: name))
            }
        case .renameGroup(let group):
            GroupNameView(heading: "Rename Group", saveTitle: "Save", initialName: group.name) { name in
                store.renameGroup(group.id, to: name)
            }
        case .newPrompt(let groupID):
            AddPromptView { title, content in
                store.addPrompt(title: title, content: content, to: groupID)
            }
        }
    }

    // MARK: - Delete confirmation

    private func deleteConfirmation(for group: PromptGroup) -> some View {
        let count = group.prompts.count
        let message = count == 0
            ? "This group is empty."
            : "Its \(count == 1 ? "1 prompt" : "\(count) prompts") will be deleted too."

        return ZStack {
            Color.black.opacity(0.6)
                .onTapGesture(perform: cancelDeletion)

            VStack(spacing: 14) {
                Text("Delete \u{201C}\(group.name)\u{201D}?")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)

                HStack(spacing: 10) {
                    Button("Cancel", action: cancelDeletion)
                        .buttonStyle(PillButtonStyle())
                        .keyboardShortcut(.cancelAction)

                    Button("Delete") {
                        withAnimation(.panel) {
                            store.deleteGroup(group.id)
                            groupPendingDeletion = nil
                        }
                    }
                    .buttonStyle(PillButtonStyle(prominent: true))
                }
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black)
            )
            .cardSurface(cornerRadius: 24)
            .padding(32)
        }
    }

    private func cancelDeletion() {
        withAnimation(.panel) {
            groupPendingDeletion = nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PromptStore())
}
