# NotepadClone2 Changelog

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