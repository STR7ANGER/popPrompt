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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Prompt")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Save a reusable prompt in a clean monochrome workspace.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Title")

                    TextField("Name your prompt", text: $title)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 10) {
                    fieldLabel("Content")

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )

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
                            .frame(minHeight: 220, maxHeight: 220)
                    }
                }

                HStack {
                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())

                    Button("Save") {
                        onSave(title, content)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(canSave ? Color.white : Color.white.opacity(0.18))
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                }
            }
            .padding(24)
        }
        .frame(width: 460, height: 470)
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.72))
            .textCase(.uppercase)
    }
}
