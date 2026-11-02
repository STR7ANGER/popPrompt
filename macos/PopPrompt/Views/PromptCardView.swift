import SwiftUI

struct PromptCardView: View {
    let prompt: Prompt
    /// Shown under the title in cross-group search results.
    var groupName: String?
    let onDelete: () -> Void

    @State private var isExpanded = false
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(prompt.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if let groupName {
                        Text(groupName)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                CardIconButton(systemName: isCopied ? "checkmark" : "doc.on.doc", action: copy)

                CardIconButton(systemName: "trash", action: onDelete)

                CardIconButton(systemName: "chevron.down", rotation: isExpanded ? 180 : 0) {
                    withAnimation(.panel) {
                        isExpanded.toggle()
                    }
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    Text(prompt.content)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(prompt.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .cardSurface()
    }

    private func copy() {
        ClipboardManager.copy(prompt.content)
        isCopied = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            isCopied = false
        }
    }
}
