import SwiftUI
import AppKit

// Notification name for theme changes
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
}

// Theme constants for the application
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case notepadPlusPlus = "Notepad++"
    
    var id: String { self.rawValue }
    
    // Get the color scheme for SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system, .notepadPlusPlus:
            return nil // System will follow system setting
        }
    }
    
    // Get the icon name for the theme
    var iconName: String {
        switch self {
        case .system:
            return "gear"
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .notepadPlusPlus:
            return "doc.text"
        }
    }
    
    // Apply the theme to the application
    func apply() {
        // Ensure theme changes are applied on the main thread
        DispatchQueue.main.async {
            switch self {
            case .system:
                NSApp.appearance = nil // Use system setting
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .notepadPlusPlus:
                // Apply Notepad++ like colors
                // This would require custom styling for various UI elements
                NSApp.appearance = NSAppearance(named: .aqua) // Base on light mode
                // Additional styling applied at the view level
            }
            
            // Notify all views that the theme has changed
            NotificationCenter.default.post(
                name: .themeDidChange,
                object: self,
                userInfo: ["theme": self.rawValue]
            )
        }
    }
    
    // Get colors for text editor based on theme
    func editorBackgroundColor() -> NSColor {
        switch self {
        case .system:
            return NSColor.textBackgroundColor
        case .light:
            return NSColor.white
        case .dark:
            return NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        case .notepadPlusPlus:
            return NSColor.white // Notepad++ uses white background by default
        }
    }
    
    func editorTextColor() -> NSColor {
        switch self {
        case .system:
            return NSColor.textColor
        case .light:
            return NSColor.black
        case .dark:
            return NSColor.white
        case .notepadPlusPlus:
            return NSColor.black // Notepad++ uses black text by default
        }
    }
    
    // Get syntax highlighting theme
    func syntaxTheme() -> SyntaxTheme {
        switch self {
        case .system:
            // Determine if we're in dark mode
            let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDarkMode ? SyntaxTheme.dark : SyntaxTheme.default
        case .light:
            return SyntaxTheme.default
        case .dark:
            return SyntaxTheme.dark
        case .notepadPlusPlus:
            // Create a Notepad++ inspired theme
            return SyntaxTheme(
                textColor: NSColor.black,
                keywordColor: NSColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0),   // Blue
                stringColor: NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),    // Red
                commentColor: NSColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0),   // Green
                numberColor: NSColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0),    // Purple
                variableColor: NSColor.black,
                pathColor: NSColor(red: 0.0, green: 0.0, blue: 0.8, alpha: 1.0),      // Blue
                functionColor: NSColor.black,
                typeColor: NSColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0),      // Purple
                annotationColor: NSColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0), // Red
                regexColor: NSColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)      // Olive
            )
        }
    }
    
    // Get tab bar styling
    func tabBarBackgroundColor() -> Color {
        switch self {
        case .system:
            return Color(NSColor.windowBackgroundColor)
        case .light:
            return Color(white: 0.95)
        case .dark:
            return Color(white: 0.2)
        case .notepadPlusPlus:
            return Color(white: 0.92) // Light grayish like Notepad++
        }
    }
    
    func tabBarSelectedColor() -> Color {
        switch self {
        case .system:
            return Color.accentColor.opacity(0.2)
        case .light:
            return Color.blue.opacity(0.2)
        case .dark:
            return Color.blue.opacity(0.3)
        case .notepadPlusPlus:
            return Color(NSColor(red: 0.87, green: 0.82, blue: 0.65, alpha: 1.0)) // Beige-ish like Notepad++
        }
    }
    
    // Load theme from UserDefaults
    static func loadSavedTheme() -> AppTheme {
        if let savedThemeString = UserDefaults.standard.string(forKey: "AppTheme"),
           let savedTheme = AppTheme(rawValue: savedThemeString) {
            return savedTheme
        }
        return .system // Default to system theme
    }
    
    // Save theme to UserDefaults
    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: "AppTheme")
    }
}
