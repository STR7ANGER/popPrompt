import SwiftUI

struct PromptListView: View {
    let prompts: [Prompt]
    @Binding var selectedPromptID: Prompt.ID?
    let onDelete: (IndexSet, [Prompt]) -> Void

    var body: some View {
        List(selection: $selectedPromptID) {
            ForEach(prompts) { prompt in
                Button {
                    selectedPromptID = prompt.id
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prompt.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(prompt.content)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 12)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        guard let index = prompts.firstIndex(of: prompt) else { return }
                        onDelete(IndexSet(integer: index), prompts)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete { offsets in
                onDelete(offsets, prompts)
            }
        }
        .listStyle(.sidebar)
    }
}
