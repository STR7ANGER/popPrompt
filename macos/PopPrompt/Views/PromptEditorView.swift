import SwiftUI

/// Sheet for adding a new prompt or editing an existing one, including which group it lives in.
struct PromptEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let heading: String
    let subtitle: String
    let saveTitle: String
    let groups: [PromptGroup]
    let onSave: (_ title: String, _ content: String, _ groupID: PromptGroup.ID) -> Void

    @State private var title: String
    @State private var content: String
    @State private var groupID: PromptGroup.ID

    init(
        heading: String,
        subtitle: String,
        saveTitle: String,
        groups: [PromptGroup],
        groupID: PromptGroup.ID,
        initialTitle: String = "",
        initialContent: String = "",
        onSave: @escaping (_ title: String, _ content: String, _ groupID: PromptGroup.ID) -> Void
    ) {
        self.heading = heading
        self.subtitle = subtitle
        self.saveTitle = saveTitle
        self.groups = groups
        self.onSave = onSave
        _title = State(initialValue: initialTitle)
        _content = State(initialValue: initialContent)
        _groupID = State(initialValue: groupID)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(heading)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle(compact: true))
                }

                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Title")

                    TextField("Name your prompt", text: $title)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .cardSurface(cornerRadius: 16)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Content")

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.clear)
                            .cardSurface(cornerRadius: 18)

                        if content.isEmpty {
                            Text("Paste or write the full prompt here...")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.35))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                        }

                        TextEditor(text: $content)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 190, maxHeight: 190)
                    }
                }

                if groups.count > 1 {
                    VStack(alignment: .leading, spacing: 10) {
                        fieldLabel("Group")
                        groupPicker
                    }
                }

                HStack {
                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle())
                    .keyboardShortcut(.cancelAction)

                    Button(saveTitle) {
                        onSave(title, content, groupID)
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle(prominent: true))
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(!canSave)
                }
            }
            .padding(24)
        }
        .frame(width: 460, height: groups.count > 1 ? 540 : 470)
    }

    private var groupPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(groups) { group in
                    let isSelected = group.id == groupID

                    Button(group.name) {
                        groupID = group.id
                    }
                    .buttonStyle(PillButtonStyle(prominent: isSelected, compact: true))
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .textCase(.uppercase)
    }
}
