import Foundation

/// Debug logger for troubleshooting text input issues
class DebugLogger {
    static let shared = DebugLogger()
    
    private var logEntries: [String] = []
    private let maxEntries = 1000
    
    private init() {}
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] [\(filename):\(line)] \(function) - \(message)"
        
        print(logMessage)
        
        // Store in memory for later analysis
        logEntries.append(logMessage)
        if logEntries.count > maxEntries {
            logEntries.removeFirst()
        }
    }
    
    func getRecentLogs(count: Int = 100) -> [String] {
        return Array(logEntries.suffix(count))
    }
    
    func clearLogs() {
        logEntries.removeAll()
    }
    
    func exportLogs() -> String {
        return logEntries.joined(separator: "\n")
    }
}

// Global convenience function
func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    DebugLogger.shared.log(message, file: file, function: function, line: line)
}