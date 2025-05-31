import Foundation

// Assuming MultiContextPlugin and MCPResult are available from Protocols/MultiContextPlugin.swift
// No need to redefine them here.

class TimestampPlugin: MultiContextPlugin {
    var id: String = "com.example.timestamp"
    var name: String = "Timestamp Plugin"
    var description: String = "Inserts the current date and time."

    // Updated execute method to match the protocol
    func execute(context: MCPContext) throws -> MCPResult {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateTimeString = formatter.string(from: now)

        // Assuming MCPResult has an initializer like this:
        // MCPResult(success: Bool, message: String?, newText: String?, insertedText: String?)
        // Based on Protocols/MultiContextPlugin.swift, it is:
        // MCPResult(success: Bool, message: String?, newText: String?, insertedText: String?)
        // The previous version was MCPResult(success: Bool, insertedText: String?, errorMessage: String?)
        // The `errorMessage` field is `message` in the protocol definition.
        return MCPResult(success: true, message: "Timestamp inserted successfully.", newText: nil, insertedText: dateTimeString)
    }
}
