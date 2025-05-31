import Foundation

// Centralized notification names for the application
// This prevents duplicate declarations across files and ensures consistent naming
extension Notification.Name {
    // Document notifications
    static let documentTextDidChange = Notification.Name("DocumentTextDidChange")
    static let documentStateDidChange = Notification.Name("DocumentStateDidChange")
    
    // App state notifications
    static let appStateTabDidChange = Notification.Name("AppStateTabDidChange")
    
    // Preferences notifications
    static let preferencesDidChange = Notification.Name("PreferencesDidChange")
    
    // Search notifications
    static let searchQueryDidChange = Notification.Name("SearchQueryDidChange")
    static let searchResultsDidChange = Notification.Name("SearchResultsDidChange")
    
    // Window notifications (custom, in addition to AppKit ones)
    static let windowContentDidChange = Notification.Name("WindowContentDidChange")
    
    // Theme notifications are declared in ThemeConstants.swift
    
    // Navigation notifications
    static let jumpToLine = Notification.Name("JumpToLine")
    
    // Text view selection change notification
    static let textViewSelectionDidChange = Notification.Name("TextViewSelectionDidChange")
    
    // Dialog notifications
    static let showGoToLineDialog = Notification.Name("ShowGoToLineDialog")
    static let showEncodingMenu = Notification.Name("ShowEncodingMenu")
    
    // Code folding notifications
    static let toggleCodeFold = Notification.Name("ToggleCodeFold")
    static let codeFoldStateDidChange = Notification.Name("CodeFoldStateDidChange")

    // Minimap / Editor Scroll Sync Notifications
    static let minimapNavigateToRatio = Notification.Name("minimapNavigateToRatio")
    static let customTextViewDidScroll = Notification.Name("customTextViewDidScroll")
    
    // Terminal notifications
    static let sendTextToTerminal = Notification.Name("sendTextToTerminalNotification")
    
    // Helper for posting typed notifications
    static func post(name: Notification.Name, object: Any? = nil, userInfo: [String: Any]? = nil) {
        NotificationCenter.default.post(name: name, object: object, userInfo: userInfo)
    }
    
    // Helper for observing notifications
    static func observe(name: Notification.Name,
                        object: Any? = nil,
                        queue: OperationQueue? = .main,
                        using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
    }
    
    // Helper for removing observers
    static func removeObserver(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
