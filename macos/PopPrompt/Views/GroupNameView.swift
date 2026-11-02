import SwiftUI

/// Sheet for creating or renaming a group.
struct GroupNameView: View {
    @Environment(\.dismiss) private var dismiss

    let heading: String
    let saveTitle: String
    let onSave: (String) -> Void

    @State private var name: String
    @FocusState private var isNameFocused: Bool

    init(heading: String, saveTitle: String, initialName: String = "", onSave: @escaping (String) -> Void) {
        self.heading = heading
        self.saveTitle = saveTitle
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(heading)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Name")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                        .textCase(.uppercase)

                    TextField("e.g. Writing, Code Review", text: $name)
                        .textFieldStyle(.plain)
                        .focused($isNameFocused)
                        .onSubmit(save)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .cardSurface(cornerRadius: 16)
                        .foregroundStyle(.white)
                }

                HStack {
                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(PillButtonStyle())
                    .keyboardShortcut(.cancelAction)

                    Button(saveTitle, action: save)
                        .buttonStyle(PillButtonStyle(prominent: true))
                        .disabled(!canSave)
                }
            }
            .padding(24)
        }
        .frame(width: 380)
        .onAppear { isNameFocused = true }
    }

    private func save() {
        guard canSave else { return }
        onSave(name)
        dismiss()
    }
}
