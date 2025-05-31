import Foundation

// Forward declaration of AppState to avoid circular dependency if MCPContext needs it directly
// For now, we'll keep context simpler, but this is a common pattern.
// class AppState {} // Only if truly needed and properly managed

/// Provides context to an MCP during execution.
struct MCPContext {
    // Example properties - to be expanded as needed
    let appState: AppState // Reference to the global AppState
    var currentText: String?
    var selectedText: String?
    var currentFileURL: URL?
    // Add other relevant context properties like active editor, project root, etc.
}

/// Represents the result of an MCP execution.
struct MCPResult {
    let success: Bool
    let message: String?
    var newText: String? // If the MCP modifies the entire text
    var insertedText: String? // If the MCP inserts text (e.g., at cursor)
    // Add other potential result fields, e.g., data for UI display
}

/// Defines the interface for a Multi Context Plugin.
protocol MultiContextPlugin: AnyObject { // Use AnyObject for class-bound protocol if state is needed
    var id: String { get } // Unique identifier for the plugin
    var name: String { get } // User-facing name
    var description: String { get } // Brief description of what the plugin does

    /// Executes the plugin's main functionality.
    /// - Parameter context: The current operational context.
    /// - Returns: An MCPResult indicating the outcome.
    /// - Throws: Errors if execution fails unexpectedly.
    func execute(context: MCPContext) throws -> MCPResult
}
