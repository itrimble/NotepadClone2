import SwiftUI

struct PreferencesWindow: View {
    @AppStorage("syntax_theme") private var selectedTheme = "default"
    @State private var showingCustomTheme = false
    
    var body: some View {
        TabView {
            // Syntax Highlighting Tab
            SyntaxPreferencesView()
                .tabItem {
                    Label("Syntax", systemImage: "paintbrush.fill")
                }
            
            // General Tab
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            // Editor Tab
            EditorPreferencesView()
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct SyntaxPreferencesView: View {
    @AppStorage("syntax_keyword_color") private var keywordColor = Color.purple.rawValue
    @AppStorage("syntax_string_color") private var stringColor = Color.green.rawValue
    @AppStorage("syntax_comment_color") private var commentColor = Color.gray.rawValue
    @AppStorage("syntax_number_color") private var numberColor = Color.blue.rawValue
    @AppStorage("syntax_variable_color") private var variableColor = Color.orange.rawValue
    @AppStorage("syntax_function_color") private var functionColor = Color.yellow.rawValue
    
    @State private var currentKeywordColor = Color.purple
    @State private var currentStringColor = Color.green
    @State private var currentCommentColor = Color.gray
    @State private var currentNumberColor = Color.blue
    @State private var currentVariableColor = Color.orange
    @State private var currentFunctionColor = Color.yellow
    
    var body: some View {
        Form {
            Section(header: Text("Syntax Highlighting Colors")) {
                ColorSetting(name: "Keywords", color: $currentKeywordColor)
                ColorSetting(name: "Strings", color: $currentStringColor)
                ColorSetting(name: "Comments", color: $currentCommentColor)
                ColorSetting(name: "Numbers", color: $currentNumberColor)
                ColorSetting(name: "Variables", color: $currentVariableColor)
                ColorSetting(name: "Functions", color: $currentFunctionColor)
            }
            
            Section(header: Text("Theme Presets")) {
                HStack {
                    Button("Default Light") {
                        applyDefaultLightTheme()
                    }
                    Button("Default Dark") {
                        applyDefaultDarkTheme()
                    }
                    Button("Reset to System") {
                        resetToSystem()
                    }
                }
            }
            
            Section(header: Text("Preview")) {
                SyntaxPreview(
                    keywordColor: currentKeywordColor,
                    stringColor: currentStringColor,
                    commentColor: currentCommentColor,
                    numberColor: currentNumberColor,
                    variableColor: currentVariableColor,
                    functionColor: currentFunctionColor
                )
                .frame(height: 100)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
            }
        }
        .padding()
        .onAppear {
            loadCurrentColors()
        }
        .onChange(of: currentKeywordColor) { _, newColor in
            keywordColor = newColor.encode()
        }
        .onChange(of: currentStringColor) { _, newColor in
            stringColor = newColor.encode()
        }
        .onChange(of: currentCommentColor) { _, newColor in
            commentColor = newColor.encode()
        }
        .onChange(of: currentNumberColor) { _, newColor in
            numberColor = newColor.encode()
        }
        .onChange(of: currentVariableColor) { _, newColor in
            variableColor = newColor.encode()
        }
        .onChange(of: currentFunctionColor) { _, newColor in
            functionColor = newColor.encode()
        }
    }
    
    private func loadCurrentColors() {
        currentKeywordColor = Color.decode(keywordColor) ?? .purple
        currentStringColor = Color.decode(stringColor) ?? .green
        currentCommentColor = Color.decode(commentColor) ?? .gray
        currentNumberColor = Color.decode(numberColor) ?? .blue
        currentVariableColor = Color.decode(variableColor) ?? .orange
        currentFunctionColor = Color.decode(functionColor) ?? .yellow
    }
    
    private func applyDefaultLightTheme() {
        currentKeywordColor = Color(red: 0.52, green: 0.0, blue: 0.67)
        currentStringColor = Color(red: 0.0, green: 0.42, blue: 0.0)
        currentCommentColor = Color(red: 0.25, green: 0.25, blue: 0.25)
        currentNumberColor = Color(red: 0.0, green: 0.0, blue: 0.67)
        currentVariableColor = Color(red: 0.67, green: 0.22, blue: 0.0)
        currentFunctionColor = Color(red: 0.67, green: 0.28, blue: 0.0)
    }
    
    private func applyDefaultDarkTheme() {
        currentKeywordColor = Color(red: 0.95, green: 0.51, blue: 0.93)
        currentStringColor = Color(red: 0.67, green: 0.82, blue: 0.38)
        currentCommentColor = Color(red: 0.5, green: 0.5, blue: 0.5)
        currentNumberColor = Color(red: 0.38, green: 0.63, blue: 0.89)
        currentVariableColor = Color(red: 0.99, green: 0.71, blue: 0.38)
        currentFunctionColor = Color(red: 1.0, green: 0.85, blue: 0.38)
    }
    
    private func resetToSystem() {
        // Replace these lines in PreferencesWindows.swift (around line 120-130)
        currentKeywordColor = .purple        // Instead of .systemPurple
        currentStringColor = .green         // Instead of .systemGreen
        currentCommentColor = .gray         // Instead of .systemGray
        currentNumberColor = .blue          // Instead of .systemBlue
        currentVariableColor = .orange      // Instead of .systemOrange
        currentFunctionColor = .yellow      // Instead of .systemYellow
    }
}

struct ColorSetting: View {
    let name: String
    @Binding var color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .frame(width: 80, alignment: .leading)
            ColorPicker("", selection: $color)
                .labelsHidden()
        }
    }
}

struct SyntaxPreview: View {
    let keywordColor: Color
    let stringColor: Color
    let commentColor: Color
    let numberColor: Color
    let variableColor: Color
    let functionColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("func").foregroundColor(keywordColor)
                Text(" calculateSum").foregroundColor(functionColor)
                Text("(")
                Text("a").foregroundColor(variableColor)
                Text(": ")
                Text("Int").foregroundColor(keywordColor)
                Text(", ")
                Text("b").foregroundColor(variableColor)
                Text(": ")
                Text("Int").foregroundColor(keywordColor)
                Text(") -> ")
                Text("Int").foregroundColor(keywordColor)
                Text(" {")
            }
            .font(.system(.body, design: .monospaced))
            
            HStack(spacing: 0) {
                Text("    ").foregroundColor(.primary)
                Text("// Add two numbers").foregroundColor(commentColor)
            }
            .font(.system(.body, design: .monospaced))
            
            HStack(spacing: 0) {
                Text("    ").foregroundColor(.primary)
                Text("return").foregroundColor(keywordColor)
                Text(" ")
                Text("a").foregroundColor(variableColor)
                Text(" + ")
                Text("b").foregroundColor(variableColor)
            }
            .font(.system(.body, design: .monospaced))
            
            HStack(spacing: 0) {
                Text("}")
            }
            .font(.system(.body, design: .monospaced))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct GeneralPreferencesView: View {
    @AppStorage("auto_save_enabled") private var autoSaveEnabled = true
    @AppStorage("auto_save_interval") private var autoSaveInterval = 30.0
    @AppStorage("show_hidden_characters") private var showHiddenCharacters = false
    @AppStorage("default_font_size") private var defaultFontSize = 14.0
    
    var body: some View {
        Form {
            Section(header: Text("Auto-Save")) {
                Toggle("Enable Auto-Save", isOn: $autoSaveEnabled)
                if autoSaveEnabled {
                    HStack {
                        Text("Save interval:")
                        Slider(value: $autoSaveInterval, in: 5...300, step: 5)
                        Text("\(Int(autoSaveInterval))s")
                            .frame(width: 40)
                    }
                }
            }
            
            Section(header: Text("Editor")) {
                Toggle("Show Hidden Characters", isOn: $showHiddenCharacters)
                HStack {
                    Text("Default Font Size:")
                    Stepper("\(Int(defaultFontSize))pt", value: $defaultFontSize, in: 10...24)
                }
            }
        }
        .padding()
    }
}

struct EditorPreferencesView: View {
    @AppStorage("word_wrap") private var wordWrap = true
    @AppStorage("line_numbers") private var lineNumbers = false
    @AppStorage("highlight_current_line") private var highlightCurrentLine = true
    @AppStorage("tab_width") private var tabWidth = 4
    @AppStorage("use_spaces_for_tabs") private var useSpacesForTabs = true
    
    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle("Word Wrap", isOn: $wordWrap)
                Toggle("Show Line Numbers", isOn: $lineNumbers)
                Toggle("Highlight Current Line", isOn: $highlightCurrentLine)
            }
            
            Section(header: Text("Indentation")) {
                Toggle("Use Spaces for Tabs", isOn: $useSpacesForTabs)
                HStack {
                    Text("Tab Width:")
                    Stepper("\(tabWidth)", value: $tabWidth, in: 1...8)
                }
            }
        }
        .padding()
    }
}

// Extensions for color encoding/decoding
extension Color {
    var rawValue: String {
        return encode()
    }
    
    func encode() -> String {
        let nsColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "\(red),\(green),\(blue),\(alpha)"
    }
    
    static func decode(_ string: String) -> Color? {
        let components = string.split(separator: ",")
        guard components.count == 4,
              let red = Double(components[0]),
              let green = Double(components[1]),
              let blue = Double(components[2]),
              let alpha = Double(components[3]) else {
            return nil
        }
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

#Preview {
    PreferencesWindow()
}
