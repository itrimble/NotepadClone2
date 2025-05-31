import SwiftUI

// Define PreferenceTabType here so it's available to AppState and PreferencesWindow
enum PreferenceTabType: String, CaseIterable, Identifiable {
    case about = "About"
    case syntax = "Syntax"
    case general = "General"
    case editor = "Editor"
    case ai = "AI"
    
    var id: String { self.rawValue }
}

struct PreferencesWindow: View {
    @EnvironmentObject var appState: AppState // To observe requestedPreferenceTab
    @State private var selectedTab: PreferenceTabType = .syntax // Default tab

    // Removed AppStorage and State for syntax_theme and showingCustomTheme as they are not used here
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // About Tab
            AboutPreferencesView()
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
                .tag(PreferenceTabType.about)
            
            // Syntax Highlighting Tab
            SyntaxPreferencesView()
                .tabItem {
                    Label("Syntax", systemImage: "paintbrush.fill")
                }
                .tag(PreferenceTabType.syntax)
            
            // General Tab
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(PreferenceTabType.general)
            
            // Editor Tab
            EditorPreferencesView()
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }
                .tag(PreferenceTabType.editor)
            
            // AI Settings Tab
            AISettingsView()
                .tabItem {
                    Label("AI", systemImage: "brain.head.profile")
                }
                .tag(PreferenceTabType.ai)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            if let requestedTab = appState.requestedPreferenceTab {
                selectedTab = requestedTab
                appState.requestedPreferenceTab = nil // Reset after setting
            }
        }
    }
}

struct AISettingsView: View {
    @StateObject private var aiSettings = AISettings() // Manages its own AISettings instance

    var body: some View {
        Form {
            Section(header: Text("Default AI Provider")) {
                Picker("Default Provider:", selection: $aiSettings.preferredAIProvider) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                HStack {
                    Spacer()
                    Button("Reset to Default") {
                        aiSettings.resetPreferredAIProviderToDefault()
                    }
                }
            }

            Section(header: Text("Ollama Configuration")) {
                TextField("API Endpoint URL:", text: $aiSettings.ollamaEndpointURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Model Name:", text: $aiSettings.ollamaModelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Spacer()
                    Button("Reset Endpoint to Default") {
                        aiSettings.resetOllamaEndpointURLToDefault()
                    }
                    Button("Reset Model to Default") {
                        aiSettings.resetOllamaModelNameToDefault()
                    }
                }
            }

            Section(header: Text("OpenAI Configuration")) {
                SecureField("API Key:", text: $aiSettings.openAIAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Model Name:", text: $aiSettings.openAIModelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Spacer()
                    Button("Clear API Key") {
                        aiSettings.resetOpenAIAPIKey()
                    }
                    Button("Reset Model to Default") {
                        aiSettings.resetOpenAIModelNameToDefault()
                    }
                }
            }

            Section(header: Text("Anthropic Configuration")) {
                SecureField("API Key:", text: $aiSettings.anthropicAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Model Name:", text: $aiSettings.anthropicModelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Spacer()
                    Button("Clear API Key") {
                        aiSettings.resetAnthropicAPIKey()
                    }
                    Button("Reset Model to Default") {
                        aiSettings.resetAnthropicModelNameToDefault()
                    }
                }
            }
        }
        .padding()
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
        let systemSyntaxTheme = AppTheme.system.syntaxTheme() // Gets appropriate light/dark system theme
        currentKeywordColor = Color(systemSyntaxTheme.keywordColor)
        currentStringColor = Color(systemSyntaxTheme.stringColor)
        currentCommentColor = Color(systemSyntaxTheme.commentColor)
        currentNumberColor = Color(systemSyntaxTheme.numberColor)
        currentVariableColor = Color(systemSyntaxTheme.variableColor)
        // currentFunctionColor is not directly in SyntaxTheme, but can be themed similarly or use a default.
        // For now, let's use a sensible default that contrasts, or re-evaluate if SyntaxTheme should include it.
        // Fallback to a default or a color from the theme that makes sense.
        // Using variableColor as a placeholder if functionColor is not in systemSyntaxTheme.
        currentFunctionColor = Color(systemSyntaxTheme.functionColor) 
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

struct AboutPreferencesView: View {
    @State private var version = "3.1.1"
    @State private var buildNumber = "2025.05.31"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Icon and Name
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    Text("NotepadClone2")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version \(version) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About NotepadClone2")
                        .font(.headline)
                    
                    Text("A powerful, feature-rich text editor for macOS inspired by Notepad++. Built with SwiftUI and AppKit, offering advanced text editing capabilities with a native macOS experience.")
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                // Key Features
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureRow(icon: "doc.on.doc", text: "Multi-tab editing with unlimited documents")
                        FeatureRow(icon: "paintbrush", text: "Syntax highlighting for 15+ languages")
                        FeatureRow(icon: "magnifyingglass", text: "Advanced search & replace with regex")
                        FeatureRow(icon: "folder", text: "Built-in file explorer with operations")
                        FeatureRow(icon: "rectangle.split.2x1", text: "Split view editing (horizontal/vertical)")
                        FeatureRow(icon: "palette", text: "Multiple themes including Notepad++ classic")
                        FeatureRow(icon: "doc.richtext", text: "Markdown preview and export")
                        FeatureRow(icon: "terminal", text: "Integrated terminal sessions")
                        FeatureRow(icon: "curlybraces", text: "Code folding and bracket matching")
                        FeatureRow(icon: "increase.indent", text: "Smart indentation system")
                    }
                }
                
                Divider()
                
                // System Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Information")
                        .font(.headline)
                    
                    HStack {
                        Text("macOS Version:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(ProcessInfo.processInfo.operatingSystemVersionString)
                    }
                    
                    HStack {
                        Text("Architecture:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(ProcessInfo.processInfo.machineArchitecture)
                    }
                }
                
                Divider()
                
                // Links and Actions
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button("GitHub Repository") {
                            if let url = URL(string: "https://github.com/itrimble/NotepadClone2") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Report Issue") {
                            if let url = URL(string: "https://github.com/itrimble/NotepadClone2/issues") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    HStack(spacing: 20) {
                        Button("Documentation") {
                            if let url = URL(string: "https://github.com/itrimble/NotepadClone2#readme") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Check for Updates") {
                            if let url = URL(string: "https://github.com/itrimble/NotepadClone2/releases") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                
                // Copyright and License
                VStack(spacing: 4) {
                    Text("© 2025 Ian Trimble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Released under the MIT License")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Made with ❤️ using SwiftUI and Claude Code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 16)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.caption)
            Spacer()
        }
    }
}

// Extension to get machine architecture
extension ProcessInfo {
    var machineArchitecture: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

#Preview {
    PreferencesWindow()
}
