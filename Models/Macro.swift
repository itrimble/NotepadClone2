import Foundation

struct Macro: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String?
    var actions: [MacroAction]

    init(id: UUID = UUID(), name: String? = nil, actions: [MacroAction] = []) {
        self.id = id
        self.name = name
        self.actions = actions
    }
}
