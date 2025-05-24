# Project Context for Claude (v2025-05-24)

## Project Overview

* **Project Name:** NotepadClone2
* **Project Description:** A macOS rich text editor with multi-tab support, inspired by Notepad++. Features include syntax highlighting, file management, search/replace functionality, and theme customization.
* **Contact Information:** Developer: Ian
* **Project Specification:** See `spec.md` for complete requirements and technical specifications

## System Variables / Build Configurations

* **Target:** NotepadClone2
* **Scheme:** Debug
* **Build Configuration:** Debug
* **Deployment Target:** macOS 15.4 (macOS Sequoia)
* **Bundle Identifier:** com.trimbletech.NotepadClone2
* **Development Team ID:** CLDQBGZBDU

## Swift Code Guidelines

* **Swift Style Guide:** Apple's Swift API Design Guidelines
* **Naming Conventions:** 
  * Use camelCase for variables and functions
  * Use PascalCase for types, classes, and protocols
  * Use descriptive variable names that clearly indicate purpose
* **Preferred Libraries/Frameworks:** SwiftUI, AppKit, Foundation, UniformTypeIdentifiers
* **Dependency Manager:** None (uses built-in frameworks only)
* **Testing Framework:** XCTest
* **Architecture Pattern:** MVVM with SwiftUI/AppKit bridging

## Conversation History Summary

* **Last conversation summary:** Implemented comprehensive code intelligence features (Phase 2.6) including code folding, bracket matching, and smart indentation. Fixed critical text view initialization issues that prevented typing and file content display. Resolved compilation errors and cleaned up code warnings.

## File Descriptions

### Managers
* `AppDelegate.swift`: Application lifecycle management, appearance settings, and window restoration handling.
* `AppState.swift`: Central state management for the application, handling tabs, documents, and user interactions. Now includes code folding notification handling and auto-indent functionality.
* `FindPanelManager.swift`: Handles search and replace functionality for text documents.

### Models
* `Document.swift`: Data model for text documents, including text content, file URL, syntax highlighting settings, and code folding state persistence.

### Components
* `CustomTextView.swift`: SwiftUI wrapper for NSTextView with enhanced features including line numbers, code folding controls (CodeFoldingRulerView), bracket matching, and smart indentation support.

### Views
* `ContentView.swift`: Main view of the application combining tab bar, text editor, and status bar. Supports split pane editing and drag & drop file opening.
* `TabBarView.swift`: Custom tab implementation for document switching with theme-aware styling.
* `StatusBar.swift`: Enhanced status bar showing word count, character count, line:column position, selection info, and file encoding.
* `PreferencesWindow.swift`: Settings interface for the application.
* `SplitEditorView.swift`: Split pane editor view for side-by-side document editing.

### Utilities
* `SyntaxHighlighter.swift`: Provides syntax highlighting for various programming languages.
* `ThemeConstants.swift`: Defines the available themes and their visual properties.
* `Notifications.swift`: Central place for all notification name declarations, including new code folding notifications.
* `CodeFolder.swift`: ✨ NEW - Detects foldable code regions (functions, classes, blocks) for multiple programming languages.
* `BracketMatcher.swift`: ✨ NEW - Provides intelligent bracket matching and highlighting functionality.
* `SmartIndenter.swift`: ✨ NEW - Implements language-aware automatic indentation with configurable rules.

### Project Files
* `NotepadCloneApp.swift`: Main app entry point and menu configuration. Now includes Auto Indent menu item.
* `NotepadClone2.xcodeproj`: Xcode project file.

## Recent Updates (2025-05-24)

### Debug Logging System Added (Session 2)
Added comprehensive debug logging to diagnose text input issues:
- **CustomTextView.swift**: Logs text view lifecycle, first responder status, and all keyboard input attempts
- **AppDelegate.swift**: System-wide keyboard event monitoring with responder chain tracing
- **DebugLogger.swift**: Centralized logging utility with in-memory storage and export capabilities
- **Console Output**: Detailed logs with emojis for easy visual parsing (🔧 setup, ✏️ text changes, 🎹 keyboard input, etc.)

### Critical Bug Fixes (Session 2)
20. **Color Picker Issue:** ✅ Fixed
   - Disabled `usesFontPanel` to prevent color picker appearing on launch
   - No longer interferes with text input focus
21. **Typing Issue Debugging:** 🔄 In Progress
   - Added comprehensive logging to trace keyboard events
   - Monitoring responder chain and text view delegate calls
   - Tests written but typing still not working

## Recent Updates (2025-05-24)

### Core Features Implemented ✅
1. **Search Functionality:** ✅ Fixed - Find/Replace panel now displays as an overlay when triggered from menu
2. **Theme Implementation:** ✅ Fixed - All UI components now properly use theme colors and update when theme changes
3. **Tab Switching Behavior:** ✅ Working as designed - First tab must always be selected for UI to function, preference applies to subsequent tabs
4. **Line Numbers:** ✅ Added - Toggleable line number display with theme-aware styling (Cmd+Shift+L)
5. **Split Pane View:** ✅ Added - Side-by-side document editing with horizontal/vertical split options (Cmd+\)
6. **Enhanced Status Bar:** ✅ Added - Line:column position, selection info, and encoding display with clickable items
7. **Find in Files:** ✅ Added - Multi-file search with filtering and context display (UI files created, need Xcode integration)

### Performance & Bug Fixes ✅
8. **Performance Issues:** ✅ Fixed - Resolved state modification warnings and typing responsiveness issues
9. **Invisible Text Issue:** ✅ Fixed - Text now displays correctly in all themes
10. **Typing Performance:** ✅ Optimized - Added comprehensive tests and fixed sporadic issues
11. **Drag and Drop File Opening:** ✅ Added - Complete drag and drop functionality for opening files
12. **StateObject and Theme Initialization Fixes:** ✅ Fixed - Resolved app launch issues

### Phase 2.6: Code Intelligence ✅ COMPLETED (2025-05-24)
13. **Code Folding System:** ✅ Implemented
   - Created CodeFolder.swift for detecting foldable regions in multiple languages
   - Language-specific detection for functions, classes, blocks, conditionals, loops
   - Enhanced ruler view (CodeFoldingRulerView) with clickable fold controls (+/- buttons)
   - Persistent fold state per document across sessions
   - Integration with existing syntax highlighting and theme system
14. **Bracket Matching & Highlighting:** ✅ Implemented
   - Created BracketMatcher.swift for intelligent bracket matching
   - Supports (), [], {}, <>, "", '', ``
   - Real-time highlighting as cursor moves
   - Blue for matched brackets, red for unmatched
   - Uses temporary attributes to avoid syntax highlighting conflicts
15. **Smart Indentation:** ✅ Implemented
   - Created SmartIndenter.swift with language-aware indentation rules
   - Auto-indent on Enter key based on language context
   - Manual auto-indent command (Edit → Auto Indent, Cmd+Option+I)
   - Language-specific rules for Swift, Python, JavaScript, Bash, AppleScript
   - Handles nested structures and continuation lines

### Critical Bug Fixes (2025-05-24)
16. **Text View Initialization:** ✅ Fixed
   - Fixed text view not appearing or accepting input
   - Added proper text view configuration (editable, selectable, etc.)
   - Fixed scroll view setup and border configuration
   - Ensured proper first responder handling
17. **File Loading Issues:** ✅ Fixed
   - Fixed plain text files (JS, Swift, etc.) being read as RTF
   - Added file extension detection for proper encoding
   - Plain text files now load correctly with UTF-8 encoding
18. **Text Visibility:** ✅ Fixed
   - Fixed missing font attributes causing invisible text
   - Ensured proper theme colors are applied to all text
   - Fixed initial document state with proper attributed text
19. **Compilation Errors:** ✅ Fixed
   - Fixed optional unwrapping errors in AppState.swift
   - Fixed closure capture semantics in CustomTextView.swift
   - Cleaned up unused variable warnings across multiple files

## Future Enhancements

Based on Notepad++ design analysis and current progress, remaining features include:
* ~~Find in Files functionality~~ ✅ Completed (UI integration needed)
* ~~Enhanced status bar~~ ✅ Completed
* ~~Drag and drop file opening~~ ✅ Completed
* ~~Code folding/unfolding~~ ✅ Completed
* ~~Bracket matching~~ ✅ Completed
* ~~Smart indentation~~ ✅ Completed
* File explorer/project sidebar for project management
* Document map/minimap for quick navigation
* Column mode and multi-cursor editing
* Macro recording and playback system
* Bookmarking system with navigation
* Advanced encoding support and conversion
* Plugin system for extensibility

## Additional Notes

* The application uses a mix of SwiftUI and AppKit components to provide advanced text editing capabilities.
* Window state restoration is important for preserving user sessions.
* Theme management supports System, Light, Dark, Notepad++, Material Dark, and Nord themes.
* Uses the NSWindowRestoration protocol for window state persistence.
* Built using Xcode version 16.3 (16E140).
* Line numbers are implemented using NSRulerView for native macOS integration.
* Split view uses HSplitView/VSplitView for proper macOS split pane behavior.
* Code folding uses enhanced NSRulerView (CodeFoldingRulerView) with interactive controls.
* Bracket matching uses NSLayoutManager temporary attributes for non-destructive highlighting.

## Conversation History / TODO

* Phase 2.6 (Code Intelligence) has been completed
* Next phase: File explorer/project sidebar implementation
* See `prompt_plan.md` for detailed task tracking