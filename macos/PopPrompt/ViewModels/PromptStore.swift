import Foundation

@MainActor
final class PromptStore: ObservableObject {
    @Published private(set) var groups: [PromptGroup] = [] {
        didSet {
            guard hasLoaded else { return }
            save()
        }
    }

    static let migratedGroupName = "My Prompts"

    private let groupsKey = "groups"
    // v1.0 stored a flat prompt list here. It is read once for migration and left untouched.
    private let legacyPromptsKey = "prompts"
    private let legacyWelcomeTitle = "Welcome Prompt"
    private let legacyWelcomeContent = "Store your favorite prompts here, then copy them into any app with one click."

    // Set once the bundled starter groups have been added, so deleting them is permanent.
    private let didSeedDefaultsKey = "didSeedDefaults"
    private let defaultGroupsURL: URL?

    private var hasLoaded = false

    init(defaultGroupsURL: URL? = Bundle.main.url(forResource: "default-groups", withExtension: "json")) {
        self.defaultGroupsURL = defaultGroupsURL
        load()
    }

    // MARK: - Groups

    func group(withID id: PromptGroup.ID?) -> PromptGroup? {
        groups.first { $0.id == id }
    }

    @discardableResult
    func addGroup(name: String) -> PromptGroup {
        let group = PromptGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        groups.append(group)
        return group
    }

    func renameGroup(_ id: PromptGroup.ID, to name: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func deleteGroup(_ id: PromptGroup.ID) {
        groups.removeAll { $0.id == id }
    }

    // MARK: - Prompts

    func addPrompt(title: String, content: String, to groupID: PromptGroup.ID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let prompt = Prompt(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        groups[index].prompts.insert(prompt, at: 0)
    }

    /// Updates a prompt's text and, if `groupID` differs from its current group, moves it there.
    func updatePrompt(_ id: Prompt.ID, title: String, content: String, groupID: PromptGroup.ID) {
        guard let source = groupIndex(containing: id),
              let destination = groups.firstIndex(where: { $0.id == groupID }),
              let promptIndex = groups[source].prompts.firstIndex(where: { $0.id == id }) else { return }

        var updatedGroups = groups
        var prompt = updatedGroups[source].prompts[promptIndex]
        prompt.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        prompt.content = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if source == destination {
            updatedGroups[source].prompts[promptIndex] = prompt
        } else {
            updatedGroups[source].prompts.remove(at: promptIndex)
            updatedGroups[destination].prompts.insert(prompt, at: 0)
        }

        groups = updatedGroups
    }

    func deletePrompt(_ id: Prompt.ID) {
        guard let index = groupIndex(containing: id) else { return }
        groups[index].prompts.removeAll { $0.id == id }
    }

    func groupID(containing promptID: Prompt.ID) -> PromptGroup.ID? {
        groupIndex(containing: promptID).map { groups[$0].id }
    }

    // MARK: - Search

    func prompts(in groupID: PromptGroup.ID, matching query: String) -> [Prompt] {
        guard let group = group(withID: groupID) else { return [] }
        return group.prompts.filter { matches($0, query: query) }
    }

    func searchAllPrompts(matching query: String) -> [(group: PromptGroup, prompt: Prompt)] {
        groups.flatMap { group in
            group.prompts
                .filter { matches($0, query: query) }
                .map { (group: group, prompt: $0) }
        }
    }

    private func matches(_ prompt: Prompt, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }

        return prompt.title.localizedCaseInsensitiveContains(trimmedQuery) ||
            prompt.content.localizedCaseInsensitiveContains(trimmedQuery)
    }

    private func groupIndex(containing promptID: Prompt.ID) -> Int? {
        groups.firstIndex { group in group.prompts.contains { $0.id == promptID } }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        UserDefaults.standard.set(data, forKey: groupsKey)
    }

    private func load() {
        defer { hasLoaded = true }

        var loadedGroups: [PromptGroup]
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([PromptGroup].self, from: data) {
            loadedGroups = decoded
        } else {
            loadedGroups = migratedLegacyGroups()
        }

        if !UserDefaults.standard.bool(forKey: didSeedDefaultsKey) {
            let defaultGroups = bundledDefaultGroups()
            if !defaultGroups.isEmpty {
                loadedGroups.insert(contentsOf: defaultGroups, at: 0)
                UserDefaults.standard.set(true, forKey: didSeedDefaultsKey)
            }
        }

        groups = loadedGroups
        save()
    }

    /// Starter groups from `shared/default-groups.json`, which both the macOS and Windows apps bundle.
    private func bundledDefaultGroups() -> [PromptGroup] {
        guard let defaultGroupsURL,
              let data = try? Data(contentsOf: defaultGroupsURL),
              let file = try? JSONDecoder().decode(DefaultGroupsFile.self, from: data) else {
            return []
        }

        return file.groups.map { group in
            PromptGroup(
                name: group.name,
                prompts: group.prompts.map { Prompt(title: $0.title, content: $0.content) }
            )
        }
    }

    private func migratedLegacyGroups() -> [PromptGroup] {
        guard let data = UserDefaults.standard.data(forKey: legacyPromptsKey),
              let legacyPrompts = try? JSONDecoder().decode([Prompt].self, from: data) else {
            return []
        }

        let keptPrompts = legacyPrompts
            .filter { !($0.title == legacyWelcomeTitle && $0.content == legacyWelcomeContent) }
            .sorted { $0.createdAt > $1.createdAt }

        guard !keptPrompts.isEmpty else { return [] }
        return [PromptGroup(name: Self.migratedGroupName, prompts: keptPrompts)]
    }
}

private struct DefaultGroupsFile: Decodable {
    struct Group: Decodable {
        let name: String
        let prompts: [Item]
    }

    struct Item: Decodable {
        let title: String
        let content: String
    }

    let groups: [Group]
}
