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
    case classicWordProcessor = "Classic WP"
    case turboPascal = "Turbo Pascal"
    case aqua = "Aqua"
    
    var id: String { self.rawValue }
    
    // Get the color scheme for SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light, .notepadPlusPlus:
            return .light
        case .dark, .materialDark, .nord, .turboPascal:
            return .dark
        case .classicWordProcessor, .aqua: 
            return .light 
        case .system:
            return nil 
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
        case .classicWordProcessor:
            return "doc.richtext.fill"
        case .turboPascal:
            return "terminal.fill"
        case .aqua:
            return "drop.fill" 
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
                // Apply Notepad++ like colors - force light mode as base
                NSApp.appearance = NSAppearance(named: .aqua)
            case .materialDark, .nord, .turboPascal: 
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case .classicWordProcessor, .aqua: 
                NSApp.appearance = NSAppearance(named: .aqua)
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
        case .classicWordProcessor:
            return NSColor(srgbRed: 0.0, green: 0.0, blue: 0.4, alpha: 1.0) // Deep blue for Classic WP
        case .turboPascal:
            return NSColor(srgbRed: 0.0, green: 0.0, blue: 0.502, alpha: 1.0) 
        case .aqua:
            return NSColor(srgbRed: 0.92, green: 0.95, blue: 0.98, alpha: 1.0) 
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
        case .classicWordProcessor:
            return NSColor(srgbRed: 0.95, green: 0.95, blue: 0.8, alpha: 1.0) // Soft Yellow/Beige for Classic WP
        case .turboPascal:
            return NSColor(srgbRed: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) 
        case .aqua:
            return NSColor(srgbRed: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) 
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
                editorFont: self.editorFont, // Pass editorFont
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
                editorFont: self.editorFont, // Pass editorFont
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
                editorFont: self.editorFont, // Pass editorFont
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
                editorFont: self.editorFont, // Pass editorFont
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
                editorFont: self.editorFont, // Pass editorFont
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
                editorFont: self.editorFont, // Pass editorFont
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
        case .classicWordProcessor:
            let mainTextColor = self.editorTextColor()
            return SyntaxTheme(
                editorFont: self.editorFont, // Pass editorFont
                textColor: mainTextColor, // Soft Yellow/Beige
                keywordColor: NSColor(srgbRed: 0.8, green: 1.0, blue: 0.8, alpha: 1.0), // Light Mint
                stringColor: NSColor(srgbRed: 1.0, green: 0.85, blue: 0.85, alpha: 1.0),  // Light Pink
                commentColor: NSColor(srgbRed: 0.7, green: 0.7, blue: 0.5, alpha: 1.0), // Muted Yellow/Gray
                numberColor: NSColor(srgbRed: 0.85, green: 0.85, blue: 1.0, alpha: 1.0),  // Light Lavender
                variableColor: mainTextColor, // Default to main text color
                pathColor: NSColor(srgbRed: 1.0, green: 1.0, blue: 0.85, alpha: 1.0), // Soft Yellow
                functionColor: NSColor(srgbRed: 0.85, green: 1.0, blue: 1.0, alpha: 1.0), // Light Cyan
                typeColor: NSColor(srgbRed: 0.8, green: 1.0, blue: 0.8, alpha: 1.0), // Light Mint
                annotationColor: NSColor(srgbRed: 1.0, green: 0.8, blue: 1.0, alpha: 1.0), // Light Magenta
                regexColor: NSColor(srgbRed: 1.0, green: 0.85, blue: 0.85, alpha: 1.0)  // Light Pink
            )
        case .turboPascal:
            return SyntaxTheme(
                editorFont: self.editorFont, // Bright Yellow
                textColor: self.editorTextColor(), 
                keywordColor: NSColor(srgbRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), // Cyan
                stringColor: NSColor.white,
                commentColor: NSColor.gray,
                numberColor: NSColor.white,
                variableColor: NSColor(srgbRed: 0.85, green: 0.85, blue: 0.85, alpha: 1.0), // Light Gray
                pathColor: self.editorTextColor(), // Bright Yellow
                functionColor: self.editorTextColor(), // Bright Yellow for function names
                typeColor: NSColor(srgbRed: 0.0, green: 1.0, blue: 1.0, alpha: 1.0), // Cyan for types
                annotationColor: NSColor.white,
                regexColor: NSColor.white
            )
        case .aqua:
            return SyntaxTheme(
                editorFont: self.editorFont, 
                textColor: self.editorTextColor(), 
                keywordColor: NSColor(srgbRed: 0.6, green: 0.2, blue: 0.4, alpha: 1.0), 
                stringColor: NSColor(srgbRed: 0.8, green: 0.2, blue: 0.0, alpha: 1.0),  
                commentColor: NSColor(srgbRed: 0.0, green: 0.5, blue: 0.0, alpha: 1.0), 
                numberColor: NSColor(srgbRed: 0.0, green: 0.0, blue: 0.8, alpha: 1.0),  
                variableColor: NSColor(srgbRed: 0.4, green: 0.2, blue: 0.6, alpha: 1.0), 
                pathColor: self.editorTextColor(),
                functionColor: NSColor(srgbRed: 0.1, green: 0.1, blue: 0.6, alpha: 1.0), 
                typeColor: NSColor(srgbRed: 0.3, green: 0.4, blue: 0.0, alpha: 1.0), 
                annotationColor: NSColor(srgbRed: 0.5, green: 0.3, blue: 0.0, alpha: 1.0), 
                regexColor: NSColor(srgbRed: 0.8, green: 0.2, blue: 0.0, alpha: 1.0)
            )
        }
    }

    // Editor Font property
    var editorFont: NSFont {
        switch self {
        case .classicWordProcessor:
            return NSFont(name: "Courier New", size: 14) ?? NSFont.userFixedPitchFont(ofSize: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        case .turboPascal:
            return NSFont(name: "Monaco", size: 14) ?? NSFont.userFixedPitchFont(ofSize: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        case .aqua:
            return NSFont.systemFont(ofSize: 13) 
        default:
            return NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
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
            return Color(NSColor(hex: "#E0E0E0"))
        case .materialDark:
            return Color(NSColor(hex: "#1E272C"))
        case .nord:
            return Color(NSColor(hex: "#252A33"))
        case .classicWordProcessor:
            return Color(NSColor(srgbRed: 0.0, green: 0.0, blue: 0.3, alpha: 1.0)) 
        case .turboPascal:
            return Color(NSColor(srgbRed: 0.0, green: 0.0, blue: 0.2, alpha: 1.0)) 
        case .aqua:
            return Color(NSColor(srgbRed: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)) 
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
            return Color(NSColor(hex: "#CCE8FF"))
        case .materialDark:
            return Color(NSColor(hex: "#314549"))
        case .nord:
            return Color(NSColor(hex: "#3B4252"))
        case .classicWordProcessor:
            return Color(NSColor(srgbRed: 0.1, green: 0.1, blue: 0.5, alpha: 1.0)) 
        case .turboPascal:
            return Color(NSColor(srgbRed: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)) 
        case .aqua:
            return Color(NSColor(srgbRed: 0.75, green: 0.85, blue: 0.95, alpha: 1.0)) 
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
