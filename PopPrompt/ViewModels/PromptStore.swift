import Foundation

@MainActor
final class PromptStore: ObservableObject {
    @Published private(set) var prompts: [Prompt] = [] {
        didSet {
            guard hasLoaded else { return }
            save()
        }
    }

    private let defaultsKey = "prompts"
    private var hasLoaded = false

    init() {
        load()
    }

    func addPrompt(title: String, content: String) {
        let prompt = Prompt(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        prompts.insert(prompt, at: 0)
    }

    func deletePrompts(at offsets: IndexSet, from filteredPrompts: [Prompt]) {
        let idsToDelete = offsets.map { filteredPrompts[$0].id }
        prompts.removeAll { idsToDelete.contains($0.id) }
    }

    func deletePrompt(_ prompt: Prompt) {
        prompts.removeAll { $0.id == prompt.id }
    }

    func prompt(withID id: Prompt.ID?) -> Prompt? {
        prompts.first { $0.id == id }
    }

    func filteredPrompts(matching query: String) -> [Prompt] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return prompts }

        return prompts.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            prompt.content.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(prompts) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        defer { hasLoaded = true }

        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Prompt].self, from: data) else {
            prompts = [
                Prompt(
                    title: "Welcome Prompt",
                    content: "Store your favorite prompts here, then copy them into any app with one click."
                )
            ]
            return
        }

        prompts = decoded.sorted { $0.createdAt > $1.createdAt }
    }
}
