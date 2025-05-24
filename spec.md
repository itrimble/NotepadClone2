# NotepadClone2 Project Specification

## Project Overview

**Name:** NotepadClone2  
**Type:** macOS Desktop Application  
**Purpose:** A feature-rich text editor inspired by Notepad++ for macOS, providing advanced text editing capabilities with a native macOS experience  
**Target Platform:** macOS 15.4+ (Sequoia)  
**Technology Stack:** Swift 5, SwiftUI, AppKit  

**Key Features Summary:**
- 📑 Tabbed editing with session management
- 🎨 Syntax highlighting & folding for dozens of languages
- 🔍 Advanced search & replace with regex support
- 🤖 Auto-completion and code intelligence
- 🎯 Multi-language support with customizable definitions
- 🎬 Macro recording & playback for automation
- 🔌 Extensible plugin system
- 🗺️ Document map for navigation
- ✂️ Split editing and column mode
- 🎨 Fully customizable GUI with themes
- 🌐 Multiple encoding support
- 📍 Line numbering & bookmarking
- 🔗 Bracket & indent highlighting
- 💾 Auto-save and crash recovery
- 🖱️ Drag & drop support  

## Core Requirements

### 1. Document Management
- **Tabbed Editing Interface**
  - Support unlimited open documents
  - Visual tab bar with document titles
  - Tab switching via keyboard shortcuts (Cmd+1-9)
  - Close tabs with confirmation for unsaved changes
  - Reorderable tabs (drag and drop)
  - Tab session management and restoration
  
- **File Operations**
  - New document creation
  - Open existing files (Cmd+O)
  - Save (Cmd+S) and Save As (Cmd+Shift+S)
  - Auto-save functionality with configurable interval
  - Crash recovery with autosave
  - Recent files menu
  - Session restoration on app launch
  - Multi-language support for file types

### 2. Text Editing Features
- **Basic Editing**
  - Cut, copy, paste operations
  - Undo/redo with unlimited history
  - Select all functionality
  - Word wrap toggle
  - Drag & drop text editing
  - Drag & drop file support
  
- **Advanced Editing**
  - Line numbers display (toggleable)
  - Syntax highlighting for dozens of languages
  - Syntax folding for code blocks
  - Auto-indentation
  - Tab/space conversion
  - Line ending conversion (LF/CRLF)
  - Column mode editing (vertical selection)
  - Bracket matching and highlighting
  - Indent guide highlighting
  - Auto-completion for words and functions
  - Bookmarking important lines
  
### 3. Search and Replace
- **Find Panel**
  - Basic text search (Cmd+F)
  - Case-sensitive option
  - Regular expression support
  - Find next/previous (Cmd+G/Cmd+Shift+G)
  
- **Replace Panel**
  - Find and replace (Cmd+Option+F)
  - Replace all functionality
  - Confirmation dialogs
  
- **Find in Files**
  - Search across multiple files in directories
  - File extension filtering
  - Exclude patterns
  - Results panel with context
  - Click to navigate to results

### 4. View Options
- **Split View**
  - Horizontal/vertical split editing
  - Independent scrolling
  - Synchronized scrolling option
  - Multiple documents in split panes
  
- **Display Options**
  - Show/hide status bar
  - Show/hide line numbers
  - Font selection
  - Zoom in/out functionality
  
### 5. Theme System & Customization
- **Built-in Themes**
  - System (follows macOS appearance)
  - Light theme
  - Dark theme
  - Notepad++ classic theme
  - Material Dark theme
  - Nord theme
  
- **Theme Features**
  - Syntax highlighting color schemes
  - UI element theming
  - Real-time theme switching
  - Theme persistence
  - Custom theme creation
  
- **GUI Customization**
  - Customizable fonts and sizes
  - Toolbar layout customization
  - Interface color adjustments
  - Window transparency options

### 6. Status Bar
- **Information Display**
  - Character count
  - Word count
  - Line:column position
  - Selection information
  - File encoding (UTF-8, ANSI, etc.)
  - Line ending type
  
- **Interactive Elements**
  - Click to change encoding
  - Click to change line endings
  - Click to go to line
  - Encoding conversion support

### 7. Productivity Features
- **Macro System**
  - Record macros for repetitive tasks
  - Playback recorded macros
  - Save and load macro sets
  - Assign keyboard shortcuts to macros
  
- **Session Management**
  - Auto-save session state
  - Restore tabs and cursor positions
  - Multiple session profiles
  - Quick session switching
  
- **Navigation**
  - Document map (minimap) for large files
  - Bookmark management
  - Go to line/column
  - Function/symbol navigation
  - Breadcrumb navigation

## Technical Requirements

### Architecture
- **Design Pattern:** MVVM (Model-View-ViewModel)
- **State Management:** Centralized AppState with ObservableObject
- **Data Persistence:** UserDefaults for preferences, file system for documents
- **Concurrency:** Swift async/await for file operations
- **Plugin Architecture:** Dynamic loading system for extensions
- **Language Support:** Extensible syntax definition system

### Performance
- **Large File Support:** Handle files up to 100MB efficiently
- **Syntax Highlighting:** Lazy loading for large documents
- **Memory Management:** Efficient text storage with NSTextStorage
- **Responsiveness:** All UI operations < 16ms for 60fps

### Code Quality
- **Testing:** Minimum 80% code coverage
- **Documentation:** Inline documentation for all public APIs
- **Error Handling:** Graceful degradation with user-friendly messages
- **Accessibility:** VoiceOver support for all UI elements

## User Interface Requirements

### Window Management
- **Main Window**
  - Minimum size: 600x400
  - Remember window size and position
  - Full screen support
  - Window restoration after restart
  
### Menus
- **File Menu**
  - New, Open, Save, Save As
  - Recent files submenu
  - Close tab, Close all tabs
  - Print functionality
  
- **Edit Menu**
  - Standard editing operations
  - Find and replace options
  - Text transformation options
  
- **View Menu**
  - Theme selection
  - Display toggles
  - Split view options
  - Zoom controls
  
- **Format Menu**
  - Font selection
  - Text formatting options
  - Indentation controls

### Keyboard Shortcuts
- Follow standard macOS conventions
- Customizable shortcuts (future enhancement)
- Shortcut hints in menus
- Context-sensitive shortcuts

## Future Enhancements (Phase 3+)

### 1. File Explorer Sidebar
- Project-based file organization
- Tree view navigation
- File operations (create, delete, rename)
- Drag and drop support

### 2. Code Intelligence ✅ (Partially in Core)
- Code folding/unfolding
- Bracket matching and highlighting
- Auto-completion for words and functions
- Function/class navigation
- Syntax-aware indentation
- Smart selections

### 3. Advanced Features ✅ (Partially in Core)
- Document map/minimap ✅ (In Core)
- Multiple cursor editing
- Column selection mode ✅ (In Core)
- Macro recording and playback ✅ (In Core)

### 4. Plugin System
- Plugin API definition
- Rich plugin ecosystem support
- Plugin marketplace integration
- Built-in plugin editor
- Hot-reload plugin development

### 5. Integration Features
- Git integration
- Terminal integration
- External tool integration
- Cloud sync support

## Quality Attributes

### Usability
- Intuitive interface following macOS HIG
- Consistent keyboard shortcuts
- Clear error messages
- Comprehensive help documentation

### Reliability
- Crash recovery with document restoration
- Data loss prevention
- Automatic backups
- Stable performance under load

### Maintainability
- Modular architecture
- Comprehensive test suite
- Clear code organization
- Version control with Git

### Security
- Sandboxed application
- No network access by default
- Secure file handling
- Privacy-focused design

## Success Criteria

1. **Functional Completeness:** All core features implemented and working
2. **Performance Benchmarks:** 
   - Open 10MB file < 1 second
   - Search in 1000 files < 5 seconds
   - Syntax highlighting lag < 50ms
3. **Quality Metrics:**
   - Zero critical bugs
   - < 5 minor bugs per release
   - 95% user satisfaction rate
4. **User Adoption:**
   - 1000+ downloads in first month
   - 4.5+ star rating
   - Active user community

## Constraints and Assumptions

### Constraints
- Must run on macOS 15.4 or later
- Must use native macOS technologies
- File size limit of 100MB per document
- Memory usage < 500MB for typical use

### Assumptions
- Users have basic text editing knowledge
- Users prefer native macOS applications
- Performance is more important than features
- Simplicity is valued over complexity

## Revision History

- **v1.0** (2025-05-24): Initial specification created
- **v1.1** (2025-05-24): Added comprehensive feature list from Notepad++ inspiration:
  - Enhanced text editing features (column mode, drag & drop)
  - Code intelligence features (folding, bracket highlighting, auto-completion)
  - Macro system for automation
  - Document map and advanced navigation
  - Encoding conversion support
  - Bookmarking and line management
  - Session management enhancements
- **v1.2** (TBD): Add cloud sync requirements
- **v1.3** (TBD): Add collaborative editing features