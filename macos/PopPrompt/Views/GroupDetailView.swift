import SwiftUI

/// The prompts inside one group.
struct GroupDetailView: View {
    @EnvironmentObject private var store: PromptStore

    let group: PromptGroup
    let searchText: String
    let onAddPrompt: () -> Void

    var body: some View {
        let prompts = store.prompts(in: group.id, matching: searchText)

        if prompts.isEmpty {
            if group.prompts.isEmpty {
                EmptyStateView(
                    systemName: "rectangle.stack.badge.plus",
                    title: "No prompts yet",
                    message: "Tap the plus button to add one to \(group.name).",
                    actionTitle: "Add Prompt",
                    action: onAddPrompt
                )
            } else {
                EmptyStateView(
                    systemName: "magnifyingglass",
                    title: "No matching prompts",
                    message: "Try a different title or keyword."
                )
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(prompts) { prompt in
                        PromptCardView(prompt: prompt) {
                            store.deletePrompt(prompt.id)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}
