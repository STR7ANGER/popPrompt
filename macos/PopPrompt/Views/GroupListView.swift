import SwiftUI

/// The first screen: every group, or prompts from all groups while searching.
struct GroupListView: View {
    @EnvironmentObject private var store: PromptStore

    let searchText: String
    let onOpen: (PromptGroup) -> Void
    let onCreate: () -> Void
    let onRename: (PromptGroup) -> Void
    let onDelete: (PromptGroup) -> Void

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if isSearching {
            searchResults
        } else if store.groups.isEmpty {
            EmptyStateView(
                systemName: "folder.badge.plus",
                title: "No groups yet",
                message: "Tap the plus button to create your first group.",
                actionTitle: "New Group",
                action: onCreate
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.groups) { group in
                        GroupCardView(
                            group: group,
                            onOpen: { onOpen(group) },
                            onRename: { onRename(group) },
                            onDelete: { onDelete(group) }
                        )
                    }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let results = store.searchAllPrompts(matching: searchText)

        if results.isEmpty {
            EmptyStateView(
                systemName: "magnifyingglass",
                title: "No matching prompts",
                message: "Try a different title or keyword."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results, id: \.prompt.id) { result in
                        PromptCardView(prompt: result.prompt, groupName: result.group.name) {
                            store.deletePrompt(result.prompt.id)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct GroupCardView: View {
    let group: PromptGroup
    let onOpen: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var showActions = false

    private var countLabel: String {
        group.prompts.count == 1 ? "1 prompt" : "\(group.prompts.count) prompts"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button(action: onOpen) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(group.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(countLabel)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }

                        Spacer(minLength: 12)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                CardIconButton(systemName: "ellipsis") {
                    withAnimation(.panel) {
                        showActions.toggle()
                    }
                }

                CardIconButton(systemName: "chevron.right", action: onOpen)
            }

            if showActions {
                HStack(spacing: 8) {
                    Button("Rename") {
                        showActions = false
                        onRename()
                    }
                    .buttonStyle(PillButtonStyle(compact: true))

                    Button("Delete") {
                        showActions = false
                        onDelete()
                    }
                    .buttonStyle(PillButtonStyle(compact: true))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .cardSurface()
    }
}
