import Foundation

struct Prompt: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}
