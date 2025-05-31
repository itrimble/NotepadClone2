import Foundation

class MCPManager: ObservableObject {
    @Published var availablePlugins: [MultiContextPlugin] = []

    init() {
        // Later, this is where plugins would be discovered and loaded.
        // For now, it's empty. Starter MCPs will be added manually.
        loadPlugins()
    }

    private func loadPlugins() {
        // Placeholder for plugin discovery logic.
        // Example:
        // self.availablePlugins.append(MyDesktopCommanderPlugin())
        // self.availablePlugins.append(MyAppleScriptPlugin())
        print("MCPManager: Plugin loading would occur here.")

        // Manually load the TimestampPlugin
        let timestampPlugin = TimestampPlugin()
        self.availablePlugins.append(timestampPlugin)
        print("MCPManager: Loaded TimestampPlugin. Total plugins: \(availablePlugins.count)")
    }

    func executePlugin(byId id: String, context: MCPContext) throws -> MCPResult {
        guard let plugin = availablePlugins.first(where: { $0.id == id }) else {
            throw NSError(domain: "MCPManagerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Plugin with ID \(id) not found."])
        }
        return try plugin.execute(context: context)
    }

    // Potentially add methods to register/unregister plugins dynamically if needed later
}
