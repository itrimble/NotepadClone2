## Version 3.1.1 - YYYY-MM-DD - Stability and Bugfix Update

### Fixed
- **Core Typing Issues:** Addressed bugs in `CustomTextView` related to first responder management, `isUpdating` state flag, and added theme color validation to prevent invisible text.
- **UI Visibility:** Improved layout priorities for File Explorer and Tab Bar in `ContentView` to prevent them from being hidden or crushed.
- **Window Restoration:** Simplified window restoration logic in `NotepadCloneApp` by commenting out custom `restorationClass` to help diagnose/fix "two windows opening" issue.
- **Line Number Visibility:** Added theme color clash detection for the `CodeFoldingRulerView` in `CustomTextView` to ensure line numbers are visible.
- **Tab Selection Logic:** Corrected tab selection logic in `AppState.newDocument()` by removing debug code that forced selection to the newest tab, fixing issues with opening files from the file explorer.
- **"Jump to Line" Functionality:** Refactored "Jump to Line" to correctly scroll to the target line and set the cursor position by using `NotificationCenter` to communicate between `AppState` and `CustomTextView.Coordinator`.
- **`MarkdownSplitView.swift` Build Errors:**
    - Changed `appState.appTheme.name` to `appState.appTheme.rawValue`.
    - Added `import WebKit`.
    - Implemented a placeholder fix for Markdown parsing by using HTML-escaped plain text in `<pre>` tags for export.
- **`FindInFilesManager.swift` Build Errors & Warnings:**
    - Removed unused local `results` variable in `performSearch()`.
    - Corrected max results check to use `self.searchResults.count`.
    - Ensured `FileManager.DirectoryEnumerator` is fully iterated before use in an async loop by converting to an array.
- **`TerminalManager.swift` Missing Property:** Added `@Published var terminalWidth: CGFloat = 300` to fix a bug where the right-positioned terminal panel was missing a width definition.

### Changed
- **Markdown Export Styling:** Refined the placeholder HTML export in `MarkdownSplitView.swift` to be dark-mode aware for better visual consistency.
- **Session State Robustness:**
    - `Managers/AppState.swift`: Now saves and restores split view configuration (`splitViewEnabled`, `splitViewOrientation`, `splitViewTabIndex`).
    - `Models/Document.swift`: Added error logging for JSON serialization/deserialization during session state saving and loading.
- **Debug Logging:** Added extensive "TYPING_DEBUG:" prefixed logs to `CustomTextView` to aid in diagnosing typing and view lifecycle issues.

### Added
- **New Themes:** Added definitions for "Aqua," "Turbo Pascal," and "Mac OS 8" themes in `Utilities/ThemeConstants.swift`. Styling for "Turbo Pascal" and "Mac OS 8" are placeholders requiring future refinement.
- **Terminal Integration:** Integrated previously commented-out Terminal functionality by uncommenting relevant code in `Managers/AppState.swift`, `Views/ContentView.swift`, and `NotepadCloneApp.swift`.

# NotepadClone2 Changelog

## Version 3.1.0 - 2025-05-24 - Markdown Preview & Terminal (Session 4)

### Added
- **Markdown Preview System**
  - Created MarkdownPreviewView.swift using WKWebView for rich rendering
  - Leverages Apple's swift-markdown package for parsing
  - Theme-aware styling that adapts to light/dark modes
  - Custom HTML renderer for complete Markdown AST support
  - Supports headers, lists, tables, code blocks, images, links, blockquotes
  - Live preview updates as you type

- **Markdown Split View**
  - Created MarkdownSplitView.swift for side-by-side editing
  - Adjustable split ratio with draggable divider
  - Synchronized scrolling between editor and preview (toggleable)
  - Visual sync button in header to enable/disable scroll sync
  - Export functionality for HTML and PDF formats
  - Export menu with proper file naming and save panels

- **Menu Integration**
  - Added Markdown Preview toggle to View menu (⇧⌘M)
  - Preview mode picker: Split View vs Preview Only
  - Auto-detects markdown files by extension (.md, .markdown, .mdown, .mkd)
  - Menu items disabled when non-markdown file is active

- **Terminal Implementation** (Files Ready)
  - Created Terminal.swift model with process lifecycle management
  - Created TerminalManager.swift for multiple terminal sessions
  - Created TerminalView.swift using NSViewRepresentable
  - Created TerminalPanelView.swift with tabbed interface
  - Support for multiple concurrent terminal sessions
  - Terminal position options (bottom or right)
  - Process management with proper cleanup
  - Environment variable configuration
  - Note: Files created but not yet added to Xcode project

### Changed
- **AppState Updates**
  - Added showMarkdownPreview and markdownPreviewMode properties
  - Added currentDocumentIsMarkdown computed property
  - Added MarkdownPreviewMode enum with split/preview options

- **ContentView Updates**
  - Modified single editor mode to support markdown preview
  - Integrated MarkdownSplitView and MarkdownPreviewView
  - Maintains existing split editor functionality

### Technical Details
- Markdown parsing uses Apple's swift-markdown package (already in dependencies)
- WebKit integration for preview rendering with custom CSS
- HTML export generates standalone documents with embedded styles
- PDF export uses NSPrintOperation with WKWebView
- Terminal uses Process API with Pipe for I/O handling

## Version 3.0.0 - 2025-05-24 - File Explorer & UI Polish (Session 3)

### Added
- **File Explorer Sidebar**
  - Created FileExplorerView.swift with complete file management capabilities
  - Tree view with expandable/collapsible directories
  - File icons with type-specific colors
  - Keyboard shortcut ⇧⌘E to toggle visibility
  - Theme-aware styling matching app appearance

- **File Operations**
  - Create new files and folders via context menu
  - Rename files and folders with validation
  - Delete files/folders (moves to trash for safety)
  - Copy file path to clipboard
  - Reveal in Finder functionality
  - Automatic file opening after creation

- **Context Menus**
  - Right-click support for all file operations
  - Directory-specific options (New File, New Folder)
  - Visual separators for organized menu structure

- **Menu Enhancements**
  - Added "Enter Full Screen" to custom View menu
  - Added Preferences to app menu with ⌘, shortcut
  - Created openPreferencesWindow() function

### Fixed
- **Duplicate View Menu Issue**
  - Removed system View menu conflicts
  - Consolidated all view options into single custom View menu
  - Proper menu organization following macOS standards

- **App Initialization**
  - Fixed "No document selected" blank screen on startup
  - Ensured at least one tab exists when app launches
  - Improved session restoration with fallback logic
  - Added debug logging for initialization sequence

- **Theme Color Consistency**
  - Fixed syntaxTheme.textColor mismatch with editorTextColor
  - All themes now use consistent color values
  - Text visibility fixed across all themes

### Changed
- **AppState Initialization**
  - Added safety checks for empty tabs array
  - Improved newDocument() creation logic
  - Better debug output for session restoration

### Technical Details
- FileExplorerView uses SwiftUI with NSViewRepresentable components
- File operations use FileManager.default for safety
- Context menus implemented with SwiftUI's contextMenu modifier
- Tree state managed with @ObservedObject FileSystemItem instances

## 2025-05-24 - Debug Logging Update (Session 2)

### Added
- **Debug Logging System**
  - Created DebugLogger.swift - Centralized logging utility with in-memory storage
  - Added system-wide keyboard event monitoring in AppDelegate.swift
  - Comprehensive logging in CustomTextView.swift for text input debugging
  - Visual console output with emoji indicators for easy parsing
  - Responder chain tracing to diagnose focus issues

### Fixed
- **Color Picker Issue**
  - Disabled `usesFontPanel` to prevent color picker appearing on launch
  - No longer interferes with text input focus

### Changed
- **Enhanced CustomTextView Debugging**
  - Added logging for all keyboard input attempts with detailed state
  - Tracks first responder changes and view lifecycle events
  - Monitors text delegate callbacks (shouldChangeTextIn, textDidChange)
  - Logs NSTextView configuration and editability state

### Known Issues
- Text input still not working despite debug logging implementation
- Cursor not visible in text editor
- Need to analyze debug logs to identify root cause

## 2025-05-24 - Code Intelligence Update

### Phase 2.6: Code Intelligence Features
- **Code Folding System**
  - Created CodeFolder.swift for detecting foldable code regions
  - Language-specific detection for Swift, Python, JavaScript, Bash, and AppleScript
  - Detects functions, classes, structs, enums, protocols, extensions, conditionals, loops
  - Enhanced ruler view (CodeFoldingRulerView) with clickable fold controls (+/- buttons)
  - Persistent fold state per document across sessions
  - Wider gutter (60px) to accommodate fold controls alongside line numbers

- **Bracket Matching & Highlighting**
  - Created BracketMatcher.swift for intelligent bracket matching
  - Supports (), [], {}, <>, "", '', ``
  - Real-time highlighting as cursor moves (blue for matched, red for unmatched)
  - Uses temporary NSLayoutManager attributes to avoid syntax highlighting conflicts
  - Handles nested brackets correctly

- **Smart Indentation**
  - Created SmartIndenter.swift with language-aware indentation rules
  - Auto-indent on Enter key based on language context
  - Manual auto-indent command (Edit → Auto Indent, Cmd+Option+I)
  - Language-specific rules for Swift, Python, JavaScript, Bash, AppleScript
  - Handles nested structures and continuation lines

### Critical Bug Fixes
- **Text View Initialization Issues**
  - Fixed text view not appearing or accepting input
  - Added proper text view configuration (isEditable, isSelectable, etc.)
  - Fixed scroll view setup and border configuration
  - Ensured proper first responder handling

- **File Loading Issues**
  - Fixed plain text files (JS, Swift, etc.) being read as RTF
  - Added file extension detection for proper encoding
  - Plain text files now load correctly with UTF-8 encoding
  - Fixed drag & drop file content not displaying

- **Text Visibility**
  - Fixed missing font attributes causing invisible text
  - Ensured proper theme colors are applied to all text
  - Fixed initial document state with proper attributed text

- **Compilation Errors**
  - Fixed optional unwrapping errors in AppState.swift
  - Fixed closure capture semantics in CustomTextView.swift
  - Cleaned up unused variable warnings across multiple files

### Drag and Drop Functionality
- Implemented complete drag and drop file opening
- Added drag and drop support to ContentView with visual feedback
- File validation for supported types (txt, rtf, md, swift, js, py, html, css, json, xml, log)
- Multiple file drop support opening each as new tab
- Integration with existing file opening system
- Comprehensive test suite for drag and drop operations

### Performance & Stability Fixes
- Fixed StateObject access before View installation by moving AppDelegate setup to onAppear
- Added safe fallback for NSApp.effectiveAppearance during theme initialization
- Resolved fatal error in ThemeConstants.swift nil unwrapping issue
- Application now launches cleanly without crashes or warnings

### Previous Updates (Same Day)
- Fixed search functionality by integrating FindPanel into ContentView
- Updated theme implementation to properly apply colors to all UI components
- Fixed CustomTextView to use theme-specific colors for editor background and text
- Updated TabBarView to use theme colors for tab bar background and selection
- Added theme change notifications to ensure UI updates when theme switches
- Fixed build errors related to WindowToolbarStyle and module imports
- Note: Tab switching preference works correctly - first tab must always be selected, preference applies to subsequent tabs
- Added line numbers display in the editor with theme-aware styling
- Added toggle for line numbers in View menu (Cmd+Shift+L)
- Line numbers update dynamically as text changes
- Implemented split pane view for editing multiple files side-by-side
- Added split editor toggle in View menu (Cmd+\)
- Added ability to switch between horizontal and vertical split (Cmd+Shift+\)
- Split panes show document names and allow independent scrolling
- Implemented Find in Files functionality (foundation complete, UI requires Xcode project update)
- Created comprehensive tests for Find in Files following TDD principles
- Added file filtering options, exclude patterns, and regex support
- Implemented context display for search results
- Added jump to line functionality with notification system
- Enhanced status bar with line:column position display
- Added selection information (character count) in status bar
- Added file encoding display in status bar (UTF-8, UTF-16, ASCII, etc.)
- Added clickable status bar items for go to line and encoding selection
- Added cursor position tracking in Document model
- Added selection change notifications from CustomTextView
- Created comprehensive unit tests for enhanced status bar functionality
- Fixed state modification during view updates that caused "undefined behavior" warnings
- Resolved sporadic typing issues by removing async state updates in text change handlers
- Optimized performance by reducing excessive notifications and refresh calls
- Added debouncing for selection changes and view refreshes
- Created comprehensive typing performance tests
- Simplified bindings in ContentView to prevent circular updates
- Fixed circular update issues between text and attributedText in Document model
- Fixed invisible text issue where typed text wasn't showing in dark themes
- Updated Document model to track app theme and use correct text colors
- Fixed syntax highlighter to use theme-aware colors for plain text

## 2025-05-11
- Added option to control automatic tab switching behavior
- Fixed API call in AppDelegate (currentDrawing)
- Removed erroneous termination call in AppDelegate
- Implemented concrete window restoration handler
- Consolidated theme selection to a single "Theme" menu
- Created centralized notification handling system 
- Added Notepad++ inspired theme

## 2025-05-10
- Initial implementation of NotepadClone2
- Multi-tab interface for document management
- Rich text editing with syntax highlighting
- File management (open, save, save as)
- Basic search functionality (find, replace)
- Tab management with keyboard shortcuts
- Auto-save functionality
- Session state restoration