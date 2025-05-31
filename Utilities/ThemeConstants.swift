//
//  ThemeConstants.swift
//  NotepadClone2
//
//  Created by Ian Trimble on 5/10/25.
//  Updated by Ian Trimble on 5/12/25.
//  Version: 2025-05-12
//

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
    case materialDark = "Notepad++ Material Dark"
    case nord = "Notepad++ Nord"
    case aqua = "Aqua"
    case turboPascal = "Turbo Pascal"
    case macOS8 = "Mac OS 8"
    
    var id: String { self.rawValue }
    
    // Get the color scheme for SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light, .notepadPlusPlus, .aqua, .turboPascal, .macOS8: // turboPascal and macOS8 are placeholders
            return .light
        case .dark, .materialDark, .nord:
            return .dark
        case .system:
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
        case .materialDark:
            return "text.badge.checkmark"
        case .nord:
            return "snow"
        case .aqua:
            return "drop.fill" // Placeholder
        case .turboPascal:
            return "pc" // Placeholder
        case .macOS8:
            return "desktopcomputer" // Placeholder
        }
    }
    
    // Apply the theme to the application
    func apply() {
        // Ensure theme changes are applied on the main thread
        DispatchQueue.main.async {
            switch self {
            case .system:
                NSApp.appearance = nil // Use system setting
            case .light, .aqua:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .notepadPlusPlus:
                // Apply Notepad++ like colors - force light mode as base
                NSApp.appearance = NSAppearance(named: .aqua)
            case .materialDark, .nord:
                // Force dark mode for these themes
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .turboPascal, .macOS8:
                // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
                // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
                NSApp.appearance = NSAppearance(named: .aqua) // Placeholder
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
            // Notepad++ default theme - light cream background
            return NSColor(hex: "#FFFBF0")
        case .materialDark:
            return NSColor(hex: "#263238")
        case .nord:
            return NSColor(hex: "#2E3440")
        case .aqua:
            return NSColor.windowBackgroundColor // System's Aqua background
        case .turboPascal:
            // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
            return NSColor(hex: "#0000A0") // Classic Turbo Pascal blue
        case .macOS8:
            // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
            return NSColor(hex: "#CCCCCC") // Classic Mac OS gray
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
            return NSColor.black
        case .materialDark:
            return NSColor(hex: "#ECEFF1")
        case .nord:
            return NSColor(hex: "#D8DEE9")
        case .aqua:
            return NSColor.textColor // System's Aqua text color
        case .turboPascal:
            // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
            return NSColor(hex: "#FFFF00") // Yellow text
        case .macOS8:
            // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
            return NSColor.black // Black text
        }
    }
    
    // Get syntax highlighting theme
    func syntaxTheme() -> SyntaxTheme {
        // Get the editor text color for this theme to ensure consistency
        let editorTextColor = self.editorTextColor()
        
        switch self {
        case .system:
            // Determine if we're in dark mode, with safe fallback
            let effectiveAppearance = NSApp.effectiveAppearance
            let isDarkMode = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let baseTheme = isDarkMode ? SyntaxTheme.dark : SyntaxTheme.default
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: baseTheme.keywordColor,
                stringColor: baseTheme.stringColor,
                commentColor: baseTheme.commentColor,
                numberColor: baseTheme.numberColor,
                variableColor: baseTheme.variableColor,
                pathColor: baseTheme.pathColor,
                functionColor: baseTheme.functionColor,
                typeColor: baseTheme.typeColor,
                annotationColor: baseTheme.annotationColor,
                regexColor: baseTheme.regexColor
            )
        case .light:
            let baseTheme = SyntaxTheme.default
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: baseTheme.keywordColor,
                stringColor: baseTheme.stringColor,
                commentColor: baseTheme.commentColor,
                numberColor: baseTheme.numberColor,
                variableColor: baseTheme.variableColor,
                pathColor: baseTheme.pathColor,
                functionColor: baseTheme.functionColor,
                typeColor: baseTheme.typeColor,
                annotationColor: baseTheme.annotationColor,
                regexColor: baseTheme.regexColor
            )
        case .dark:
            let baseTheme = SyntaxTheme.dark
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: baseTheme.keywordColor,
                stringColor: baseTheme.stringColor,
                commentColor: baseTheme.commentColor,
                numberColor: baseTheme.numberColor,
                variableColor: baseTheme.variableColor,
                pathColor: baseTheme.pathColor,
                functionColor: baseTheme.functionColor,
                typeColor: baseTheme.typeColor,
                annotationColor: baseTheme.annotationColor,
                regexColor: baseTheme.regexColor
            )
        case .notepadPlusPlus:
            // Create an authentic Notepad++ classic theme
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: NSColor(hex: "#0000FF"),    // Vivid blue for keywords
                stringColor: NSColor(hex: "#008000"),     // Green for strings
                commentColor: NSColor(hex: "#808080"),    // Gray for comments
                numberColor: NSColor(hex: "#FF8000"),     // Orange for numbers
                variableColor: NSColor(hex: "#8000FF"),   // Purple for variables
                pathColor: NSColor(hex: "#0000FF"),       // Blue for paths
                functionColor: NSColor(hex: "#800080"),   // Purple for functions
                typeColor: NSColor(hex: "#000080"),       // Navy for types
                annotationColor: NSColor(hex: "#808000"), // Olive for annotations
                regexColor: NSColor(hex: "#000080")       // Navy for regex
            )
        case .materialDark:
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: NSColor(hex: "#80CBC4"),
                stringColor: NSColor(hex: "#C3E88D"),
                commentColor: NSColor(hex: "#546E7A"),
                numberColor: NSColor(hex: "#F78C6C"),
                variableColor: NSColor(hex: "#ECEFF1"),
                pathColor: NSColor(hex: "#80CBC4"),
                functionColor: NSColor(hex: "#82AAFF"),
                typeColor: NSColor(hex: "#C792EA"),
                annotationColor: NSColor(hex: "#C792EA"),
                regexColor: NSColor(hex: "#F07178")
            )
        case .nord:
            return SyntaxTheme(
                textColor: editorTextColor,
                keywordColor: NSColor(hex: "#81A1C1"),
                stringColor: NSColor(hex: "#A3BE8C"),
                commentColor: NSColor(hex: "#616E88"),
                numberColor: NSColor(hex: "#B48EAD"),
                variableColor: NSColor(hex: "#D8DEE9"),
                pathColor: NSColor(hex: "#88C0D0"),
                functionColor: NSColor(hex: "#8FBCBB"),
                typeColor: NSColor(hex: "#81A1C1"),
                annotationColor: NSColor(hex: "#5E81AC"),
                regexColor: NSColor(hex: "#EBCB8B")
            )
        // TODO: Define proper syntax highlighting for Aqua
        case .aqua:
            let baseTheme = SyntaxTheme.default // Or system-derived
            return SyntaxTheme(
                textColor: editorTextColor, // Use self.editorTextColor()
                keywordColor: baseTheme.keywordColor,
                stringColor: baseTheme.stringColor,
                commentColor: baseTheme.commentColor,
                numberColor: baseTheme.numberColor,
                variableColor: baseTheme.variableColor,
                pathColor: baseTheme.pathColor,
                functionColor: baseTheme.functionColor,
                typeColor: baseTheme.typeColor,
                annotationColor: baseTheme.annotationColor,
                regexColor: baseTheme.regexColor
            )
        // TODO: Define proper syntax highlighting for Turbo Pascal
        case .turboPascal:
            // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
            let baseTheme = SyntaxTheme.default 
            return SyntaxTheme(
                textColor: editorTextColor, // Use self.editorTextColor()
                keywordColor: NSColor(hex: "#FFFFFF"), // White keywords on blue
                stringColor: NSColor(hex: "#00FFFF"), // Cyan strings
                commentColor: NSColor(hex: "#808080"), // Gray comments
                numberColor: NSColor(hex: "#00FF00"), // Green numbers
                variableColor: NSColor(hex: "#FFFF00"), // Yellow variables (same as text)
                pathColor: NSColor(hex: "#00FFFF"),
                functionColor: NSColor(hex: "#FFFFFF"),
                typeColor: NSColor(hex: "#FFFFFF"),
                annotationColor: NSColor(hex: "#808080"),
                regexColor: NSColor(hex: "#00FFFF")
            )
        // TODO: Define proper syntax highlighting for Mac OS 8
        case .macOS8:
            // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
            let baseTheme = SyntaxTheme.default
            return SyntaxTheme(
                textColor: editorTextColor, // Use self.editorTextColor()
                keywordColor: baseTheme.keywordColor,
                stringColor: baseTheme.stringColor,
                commentColor: baseTheme.commentColor,
                numberColor: baseTheme.numberColor,
                variableColor: baseTheme.variableColor,
                pathColor: baseTheme.pathColor,
                functionColor: baseTheme.functionColor,
                typeColor: baseTheme.typeColor,
                annotationColor: baseTheme.annotationColor,
                regexColor: baseTheme.regexColor
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
            // Classic Notepad++ tab bar color
            return Color(NSColor(hex: "#E0E0E0"))
        case .materialDark:
            return Color(NSColor(hex: "#1E272C"))
        case .nord:
            return Color(NSColor(hex: "#252A33"))
        case .aqua:
            return Color(NSColor.controlBackgroundColor)
        case .turboPascal:
            // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
            return Color(hex: "#000080") // Darker blue
        case .macOS8:
            // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
            return Color(hex: "#BDBDBD") // Slightly darker gray
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
            // Authentic Notepad++ tab selection color
            return Color(NSColor(hex: "#CCE8FF"))
        case .materialDark:
            return Color(NSColor(hex: "#314549"))
        case .nord:
            return Color(NSColor(hex: "#3B4252"))
        case .aqua:
            return Color.accentColor.opacity(0.2)
        case .turboPascal:
            // TODO: turboPascal - Placeholder styling, requires accurate color definitions.
            return Color(hex: "#00FFFF").opacity(0.3) // Cyanish
        case .macOS8:
            // TODO: macOS8 - Placeholder styling, requires accurate color definitions.
            return Color.black.opacity(0.1) // Darker selection
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

    // MARK: - Terminal Colors

    func terminalBackgroundColor() -> NSColor {
        switch self {
        case .system: return NSColor.textBackgroundColor // Standard system terminal background
        case .light: return NSColor.white
        case .dark: return NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // Slightly darker than editor
        case .notepadPlusPlus: return self.editorBackgroundColor() // Or a specific terminal color
        case .materialDark: return NSColor(hex: "#212121") // Darker than editor
        case .nord: return NSColor(hex: "#20242F") // Darker than editor
        case .aqua: return NSColor.windowBackgroundColor
        case .turboPascal: return NSColor(hex: "#0000A0") // Consistent with editor
        case .macOS8: return NSColor(hex: "#CCCCCC") // Consistent with editor
        }
    }

    func terminalTextColor() -> NSColor {
        switch self {
        case .system: return NSColor.textColor
        case .light: return NSColor.black
        case .dark: return NSColor.lightGray // Slightly less bright than pure white for terminals
        case .notepadPlusPlus: return self.editorTextColor()
        case .materialDark: return NSColor(hex: "#B0BEC5")
        case .nord: return NSColor(hex: "#D8DEE9")
        case .aqua: return NSColor.textColor
        case .turboPascal: return NSColor(hex: "#FFFF00") // Consistent
        case .macOS8: return NSColor.black // Consistent
        }
    }

    func terminalCursorColor() -> NSColor {
        // Often good to be a distinct, visible color
        switch self {
        case .dark, .materialDark, .nord: return NSColor.yellow
        default: return NSColor.systemOrange // Or self.terminalTextColor() for less contrast
        }
    }

    func terminalSelectionColor() -> NSColor {
        // Usually a semi-transparent version of the accent color or a standard selection color
        switch self {
        case .dark, .materialDark, .nord:
            return NSColor.selectedTextBackgroundColor.withAlphaComponent(0.5)
        default:
            return NSColor.selectedTextBackgroundColor.withAlphaComponent(0.3)
        }
    }
}

// Extension to support hex color codes
extension NSColor {
    convenience init(hex: String) {
        let trimHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropHash = String(trimHex.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        let hexString = trimHex.hasPrefix("#") ? dropHash : trimHex
        let ui64 = UInt64(hexString, radix: 16)
        let value = ui64 != nil ? Int(ui64!) : 0
        
        // Support for both 6 and 8 digit hex strings
        let isShortHex = hexString.count <= 6
        
        let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(value & 0x0000FF) / 255.0
        let a = isShortHex ? CGFloat(1.0) : CGFloat((value & 0xFF000000) >> 24) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
