import SwiftUI

struct AddPromptView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""

    let onSave: (String, String) -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Prompt")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.subheadline.weight(.semibold))

                TextEditor(text: $content)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .frame(minHeight: 180)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    onSave(title, content)
                    dismiss()
                }
                .disabled(!canSave)
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(canSave ? Color.black : Color.black.opacity(0.2))
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(Color(red: 0.95, green: 0.93, blue: 0.89))
    }
}
