import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore

    @State private var searchText = ""
    @State private var selectedPromptID: Prompt.ID?
    @State private var showAddPrompt = false

    private var filteredPrompts: [Prompt] {
        store.filteredPrompts(matching: searchText)
    }

    private var selectedPrompt: Prompt? {
        store.prompt(withID: selectedPromptID)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let selectedPrompt {
                PromptDetailView(
                    prompt: selectedPrompt,
                    onBack: { selectedPromptID = nil },
                    onDelete: {
                        store.deletePrompt(selectedPrompt)
                        selectedPromptID = nil
                    },
                    onCopy: { copy(selectedPrompt) }
                )
            } else {
                VStack(spacing: 12) {
                    header

                    if filteredPrompts.isEmpty {
                        emptyState
                    } else {
                        PromptListView(
                            prompts: filteredPrompts,
                            selectedPromptID: $selectedPromptID,
                            onDelete: { offsets, prompts in
                                store.deletePrompts(at: offsets, from: prompts)
                            }
                        )
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 420, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showAddPrompt) {
            AddPromptView { title, content in
                store.addPrompt(title: title, content: content)
            }
        }
        .animation(.smooth(duration: 0.2), value: filteredPrompts)
        .animation(.smooth(duration: 0.2), value: selectedPromptID)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PopPrompt")
                        .font(.title3.weight(.semibold))

                    Text("Reusable prompts, one click away")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showAddPrompt = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .help("Add prompt")
            }

            TextField("Search prompts", text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.bubble")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "No prompts yet" : "No matches found")
                .font(.headline)

            Text(searchText.isEmpty ? "Create your first prompt to start copying faster." : "Try a different title or keyword.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if searchText.isEmpty {
                Button("Add Prompt") {
                    showAddPrompt = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func copy(_ prompt: Prompt) {
        ClipboardManager.copy(prompt.content)
    }
}

#Preview {
    ContentView()
        .environmentObject(PromptStore())
}
