import Foundation

struct PromptGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var prompts: [Prompt]

    init(id: UUID = UUID(), name: String, createdAt: Date = .now, prompts: [Prompt] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.prompts = prompts
    }
}
