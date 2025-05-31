# NotepadClone2

A powerful, feature-rich text editor for macOS inspired by Notepad++. Built with SwiftUI and AppKit, offering advanced text editing capabilities with a native macOS experience.

## Features

### Core Functionality ✅
- 📑 **Tabbed Editing** - Work with unlimited documents in a single window ✅
- 🎨 **Syntax Highlighting** - Support for multiple programming languages ✅
- 🔍 **Advanced Search & Replace** - Find, replace with regex support ✅
- 🔍 **Find in Files** - Search across multiple documents with filtering ✅
- 💾 **Auto-save & Session Recovery** - Never lose your work ✅
- 🌓 **Theme System** - Multiple built-in themes including Notepad++, Material Dark, Nord ✅
- 📏 **Line Numbers** - Toggleable line number display with theme-aware styling ✅
- ✂️ **Split View** - Edit multiple files side-by-side (horizontal/vertical) ✅
- 📊 **Enhanced Status Bar** - Character/word count, line:column position, encoding ✅
- 📂 **Drag & Drop** - Drop files directly into the editor to open them ✅

### Advanced Editing ✅
- 🔗 **Bracket Matching** - Real-time bracket highlighting and navigation ✅
- 📁 **Code Folding** - Collapse and expand code blocks with visual controls ✅
- 🔤 **Smart Indentation** - Language-aware automatic indentation ✅
- ⌨️ **Auto Indent** - Format code with proper indentation (Cmd+Option+I) ✅

### File Management ✅
- 📁 **File Explorer** - Built-in project file browser with tree view ✅
- 🖱️ **File Operations** - Create, rename, and delete files/folders ✅
- 📋 **Context Menus** - Right-click for file operations ✅
- 🌳 **Tree Navigation** - Expandable directory structure ✅
- ⌨️ **Keyboard Toggle** - Show/hide with ⌘⇧E ✅

### Advanced Features ✅
- 📝 **Markdown Preview** - Live preview of Markdown text using the integrated Markdown package, with synchronized scrolling. Export to HTML/PDF available. ✅
- 📤 **Markdown Export** - Export to HTML and PDF formats ✅
- 💻 **Integrated Terminal** - Built-in terminal with multiple sessions ✅

### In Development
- 📍 **Bookmarking** - Mark and navigate important lines
- 📐 **Column Mode** - Vertical selection and editing
- 🎬 **Macro Recording** - Record and playback repetitive tasks
- 🌐 **Advanced Encoding** - Handle multiple file encodings with conversion
- 🤖 **Auto-completion** - Context-aware code completion

### User Experience ✅
- ⌨️ **Comprehensive Shortcuts** - Full keyboard navigation ✅
- 🎯 **Smart Tab Management** - Reorderable tabs with keyboard shortcuts ✅
- 🎨 **Customizable Themes** - System, Light, Dark, Notepad++, Material Dark, Nord ✅
- 🚀 **Performance Optimized** - Responsive typing and smooth scrolling ✅
- 🔧 **Native macOS Integration** - Follows macOS design guidelines ✅
- 🗺️ **Document Map/Minimap** - Displays a miniature overview of the document, showing the current visible portion and allowing quick navigation by clicking. ✅

## Why NotepadClone2?

### Notepad++ Features on macOS
If you're missing Notepad++ on macOS, NotepadClone2 brings you:
- ✅ Native macOS performance and integration
- ✅ Familiar multi-tab interface
- ✅ Powerful search capabilities including Find in Files
- ✅ Extensive language support with syntax highlighting
- ✅ Split view editing
- ✅ Theme customization
- ✅ Session management
- ✅ Code folding with visual indicators
- ✅ Bracket matching with highlighting
- ✅ Smart indentation
- ✅ And much more...

### Built for macOS
Unlike ports or Wine-based solutions, NotepadClone2 is:
- 🚀 Native Swift/SwiftUI application
- 🎨 Follows macOS design guidelines
- ⚡ Optimized for Apple Silicon
- 🔒 Sandboxed and secure
- 🌐 Supports macOS features like Continuity

## Screenshots

![NotepadClone2 Main Interface](screenshots/main-interface.png)
*Main interface with multi-tab support and syntax highlighting*

![Search and Replace](screenshots/search-replace.png)
*Powerful search and replace functionality*

![Split View Editing](screenshots/split-view.png)
*Edit multiple files side-by-side*

![Theme Options](screenshots/themes.png)
*Multiple built-in themes including Notepad++ classic*

## Latest Updates (v3.1.1 - Stability and Bugfix Update)

### What's New (YYYY-MM-DD)
- 💻 **Terminal Integration** - Terminal components are now integrated into the application. ✅
- 📝 **Markdown Rendering** - Correctly integrated the existing Markdown package for rendering in exports and preview.
- ✨ **New Themes Added** - "Aqua," "Turbo Pascal," and "Mac OS 8" (placeholders for Turbo Pascal & Mac OS 8).
- 🐛 **Bug Fixes** - Addressed issues with typing, UI visibility, window restoration, line numbers, tab selection, and "Jump to Line".
- 🛠️ **Build Fixes** - Resolved compilation errors in `MarkdownSplitView.swift` and `FindInFilesManager.swift`.
- 💅 **Markdown Export Styling** - Placeholder HTML export is now dark-mode aware.
- 💾 **Session State Enhanced** - Split view settings are now saved and restored; improved error handling for document session data.
- 🪵 **Debug Logging** - Added extensive "TYPING_DEBUG:" logs to `CustomTextView`.

### Recent Features (v3.0.0)
- 📁 **File Explorer Sidebar** - Complete file management with tree view
- 🖱️ **File Operations** - Create, rename, and delete files/folders via context menus
- 🎨 **Menu System Fix** - Resolved duplicate View menu issue
- ⚙️ **Preferences** - Added to app menu with ⌘, shortcut
- 🚀 **App Initialization** - Fixed "No document selected" blank screen issue

### v2.6.0 Features
- ✅ Code folding with visual controls
- ✅ Real-time bracket matching
- ✅ Smart indentation system
- ✅ Auto-indent command (Cmd+Option+I)

## Installation

### Requirements
- macOS 15.4 (Sequoia) or later
- Xcode 16.3 or later for building from source

### Building from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/itrimble/NotepadClone2.git
   cd NotepadClone2
   ```

2. Open in Xcode:
   ```bash
   open NotepadClone2.xcodeproj
   ```

3. Build and run:
   - Select `NotepadClone2` scheme
   - Press ⌘R to build and run

### Release Installation
1. Download the latest release from [GitHub Releases](https://github.com/itrimble/NotepadClone2/releases)
2. Drag NotepadClone2.app to your Applications folder
3. Launch from Applications or Spotlight

## Usage

### Quick Start
1. Launch NotepadClone2
2. Start typing immediately or press ⌘O to open a file
3. Use ⌘T to create new tabs
4. Drag and drop files directly onto the window to open them
5. Enable syntax highlighting by saving files with appropriate extensions

### Keyboard Shortcuts

#### File Operations
| Action | Shortcut |
|--------|----------|
| New Tab | ⌘T |
| Open File | ⌘O |
| Save | ⌘S |
| Save As | ⇧⌘S |
| Close Tab | ⌘W |
| Print | ⌘P |

#### Editing
| Action | Shortcut |
|--------|----------|
| Undo | ⌘Z |
| Redo | ⇧⌘Z |
| Cut | ⌘X |
| Copy | ⌘C |
| Paste | ⌘V |
| Select All | ⌘A |
| Auto Indent | ⌥⌘I |

#### Search & Navigation
| Action | Shortcut |
|--------|----------|
| Find | ⌘F |
| Find & Replace | ⌥⌘F |
| Find in Files | ⇧⌘F |
| Find Next | ⌘G |
| Find Previous | ⇧⌘G |
| Jump to Line | ⌘L |

#### View & Display
| Action | Shortcut |
|--------|----------|
| Toggle Line Numbers | ⇧⌘L |
| Toggle File Explorer | ⇧⌘E |
| Toggle Split View | ⌘\\ |
| Toggle Split Direction | ⇧⌘\\ |
| Toggle Markdown Preview | ⇧⌘M |
| Enter Full Screen | ⌃⌘F |
| Preferences | ⌘, |
| Zoom In | ⌘+ |
| Zoom Out | ⌘- |

#### Tab Navigation
| Action | Shortcut |
|--------|----------|
| Switch to Tab 1-9 | ⌘1-9 |
| Next Tab | ⌘] |
| Previous Tab | ⌘[ |

### File Explorer

#### Basic Usage
- Press ⇧⌘E to toggle the file explorer sidebar
- Click folders to expand/collapse
- Double-click files to open them in the editor
- Right-click for context menu options

#### File Operations
- **New File**: Right-click a folder → New File...
- **New Folder**: Right-click a folder → New Folder...
- **Rename**: Right-click any item → Rename...
- **Delete**: Right-click any item → Delete (moves to trash)
- **Reveal in Finder**: Right-click → Reveal in Finder
- **Copy Path**: Right-click → Copy Path

### Code Intelligence Features

#### Code Folding
- Click the **-** button in the gutter to collapse a code block
- Click the **+** button to expand a collapsed block
- Supports functions, classes, loops, and other language constructs
- Fold state is preserved when switching tabs

#### Bracket Matching
- Place cursor next to any bracket: (), [], {}, <>, "", '', ``
- Matching bracket is highlighted automatically
- Blue highlight for matched pairs
- Red highlight for unmatched brackets

#### Smart Indentation
- Press Enter for automatic indentation based on context
- Use ⌥⌘I to auto-indent selected text or current line
- Language-specific rules for Swift, Python, JavaScript, Bash, AppleScript

### Markdown Preview

#### Basic Usage
- Open any `.md`, `.markdown`, `.mdown`, or `.mkd` file
- Press ⇧⌘M to toggle markdown preview
- Choose between Split View or Preview Only modes

#### Preview Features
- **Live Preview**: Updates as you type
- **Synchronized Scrolling**: Editor and preview scroll together
- **Theme Adaptation**: Preview matches your current theme
- **Export Options**: Export to HTML or PDF via the export menu

#### Export to HTML/PDF
1. Open a markdown file and enable preview
2. Click the export button (↗) in the preview header
3. Choose "Export as HTML" or "Export as PDF"
4. Select destination and save

### Search & Replace

#### Basic Search
1. Press ⌘F to open the search panel
2. Type your search query
3. Use ⌘G for next match, ⇧⌘G for previous

#### Advanced Search
- Enable **Case Sensitive** for exact matches
- Enable **Regular Expression** for pattern matching
- Use **Replace All** to change multiple instances at once

### Customization

#### Themes
Access themes via the Theme menu:
- System (follows macOS appearance)
- Light
- Dark
- Notepad++ (classic theme)
- Material Dark
- Nord

#### Syntax Highlighting
Files are automatically detected by extension:
- `.swift` - Swift highlighting
- `.py` - Python highlighting
- `.js/.jsx/.ts/.tsx` - JavaScript/TypeScript highlighting
- `.sh/.bash` - Bash highlighting
- `.applescript` - AppleScript highlighting
- `.java` - Java highlighting
- `.cpp/.c` - C/C++ highlighting
- `.html/.xml` - Markup highlighting
- `.json` - JSON highlighting
- `.md` - Markdown highlighting
- `.css` - CSS highlighting
- `.log` - Log file highlighting
- And many more...

## Troubleshooting

### Debug Logging

The application includes comprehensive debug logging to help diagnose issues:

1. **Console Output**: Look for emoji-prefixed logs in Xcode console:
   - 🔧 Setup and initialization
   - ✏️ Text changes
   - 🎹 Keyboard input
   - 🎯 First responder status
   - ⌨️ System-wide keyboard events

2. **Debug Areas**: 
   - `CustomTextView.swift` - Text view lifecycle and input handling
   - `AppDelegate.swift` - System keyboard monitoring
   - `DebugLogger.swift` - Centralized logging utility

3. **Known Issues**:
   - Text input may not work in some cases (debugging in progress)
   - If you can't type, check console logs for responder chain issues

## Architecture

### Project Structure
```
NotepadClone2/
├── NotepadCloneApp.swift             # App entry point and menu configuration
├── Components/
│   └── CustomTextView.swift          # NSTextView wrapper with code intelligence
├── Managers/
│   ├── AppState.swift               # Central application state
│   ├── AppDelegate.swift            # App lifecycle and window restoration
│   ├── FindPanelManager.swift       # Search and replace functionality
│   ├── FindInFilesManager.swift     # Multi-file search
│   └── TerminalManager.swift        # Terminal session management (ready)
├── Models/
│   ├── Document.swift               # Document model with fold state persistence
│   └── Terminal.swift               # Terminal session model (ready)
├── Utilities/
│   ├── SyntaxHighlighter.swift      # Language syntax highlighting
│   ├── ThemeConstants.swift         # Theme definitions and colors
│   ├── Notifications.swift          # Centralized notifications
│   ├── CodeFolder.swift             # Code folding detection
│   ├── BracketMatcher.swift         # Bracket matching logic
│   └── SmartIndenter.swift          # Intelligent indentation
├── Views/
│   ├── ContentView.swift            # Main interface with split view
│   ├── TabBarView.swift             # Tab management UI
│   ├── StatusBar.swift              # Enhanced status information
│   ├── PreferencesWindow.swift      # Settings and preferences
│   ├── FindInFilesView.swift        # Find in Files UI
│   ├── SplitEditorView.swift        # Split pane editing
│   ├── FileExplorerView.swift       # File explorer sidebar with operations
│   ├── MarkdownPreviewView.swift     # WebKit-based markdown preview
│   ├── MarkdownSplitView.swift      # Split view for markdown editing
│   ├── TerminalView.swift           # Terminal emulation (ready)
│   └── TerminalPanelView.swift      # Terminal panel UI (ready)
└── Tests/
    ├── FindInFilesTests.swift       # Find in Files test suite
    └── DragDropTests.swift          # Drag & drop test suite
```

### Key Components

#### AppState
- Manages all application state
- Handles document lifecycle
- Coordinates between views and models
- Manages code folding operations

#### Document
- Represents individual text documents
- Manages syntax highlighting
- Handles file I/O operations
- Persists code folding state

#### CustomTextView
- SwiftUI wrapper for NSTextView
- Handles text editing and formatting
- Manages first responder status
- Implements code intelligence features

#### Code Intelligence
- **CodeFolder**: Detects foldable regions in multiple languages
- **BracketMatcher**: Real-time bracket matching with highlighting
- **SmartIndenter**: Language-aware automatic indentation

## Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to the branch:
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

### Code Style
- Follow SwiftUI best practices
- Use meaningful variable and function names
- Document complex logic with comments
- Keep functions focused and small
- Add tests for new features

### Testing
- Run all tests before submitting PR:
  ```bash
  xcodebuild test -scheme NotepadClone2
  ```
- Add tests for new features
- Ensure backward compatibility
- Test with large documents (10k+ lines)

## Troubleshooting

### Common Issues

#### Text Not Appearing / Can't Type
- **Solution**: Update to latest version with text view initialization fixes
- **Check**: Ensure the window has focus

#### Drag & Drop Files Not Opening
- **Solution**: Update to latest version with plain text file loading fixes
- **Note**: JavaScript and other text files now load correctly

#### Syntax Highlighting Not Working
- **Check**: File extension is recognized
- **Try**: Save file with proper extension

#### Performance Issues with Large Files
- **Note**: Files over 5000 characters use debounced highlighting
- **Tip**: Consider splitting very large files

### Debug Mode
Enable debug logging by setting the environment variable:
```bash
NOTEPAD_DEBUG=1 open NotepadClone2.app
```

## Recent Updates (v3.0.0 - May 24, 2025)

### File Explorer & UI Polish
- ✅ **File Explorer Sidebar**: Complete file management with tree view
- ✅ **File Operations**: Create, rename, and delete files/folders
- ✅ **Context Menus**: Right-click for comprehensive file operations
- ✅ **Menu System Fix**: Resolved duplicate View menu issue
- ✅ **Preferences**: Added to app menu with standard ⌘, shortcut
- ✅ **App Initialization**: Fixed blank screen on startup

### Code Intelligence Features (v2.6.0)
- ✅ **Code Folding**: Collapse/expand functions, classes, and code blocks
- ✅ **Bracket Matching**: Real-time highlighting of matching brackets
- ✅ **Smart Indentation**: Language-aware automatic indentation
- ✅ **Enhanced Ruler View**: Wider gutter with fold controls

### Previous Updates
- ✅ Fixed search/replace functionality with overlay panel
- ✅ Implemented proper theme system with 6 built-in themes
- ✅ Added line numbers with theme-aware styling
- ✅ Implemented split pane view (horizontal/vertical)
- ✅ Added Find in Files functionality with context display
- ✅ Enhanced status bar with line:column position, selection info, and encoding
- ✅ Complete drag & drop file opening support

## Known Issues

- [ ] Find in Files UI requires manual addition to Xcode project (though backend logic is present).
- [ ] Auto-completion system planned for next release.
- [🚧] Styling for "Turbo Pascal" and "Mac OS 8" themes are placeholders and need refinement.
- [ ] Full Markdown parsing and rendering (beyond current placeholder) for exported HTML.

## Roadmap

### Version 3.2.0 (Next)
- [ ] Integrate terminal into UI (files ready)
- [x] Document map/minimap
- [ ] Enhanced auto-completion
- [ ] Drag & drop in file explorer
- [ ] File watching for external changes

### Version 3.3.0
- [ ] Column mode editing
- [ ] Multi-cursor support
- [ ] Bookmarking system
- [ ] Advanced encoding support

### Version 3.0.0
- [ ] Macro recording and playback
- [ ] Plugin system architecture
- [ ] Git integration
- [ ] Custom theme editor

### Future Versions
- [ ] Collaborative editing
- [ ] Cloud sync
- [ ] Integrated terminal
- [ ] Remote file editing

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- Apple's SF Symbols for iconography
- SwiftUI community for inspiration
- Contributors and beta testers
- Notepad++ for the inspiration

## Documentation

- 📋 [Project Specification](spec.md) - Complete feature requirements
- 🤖 [AI Development Guide](CLAUDE.md) - Claude Code context and guidelines
- 📝 [Development Plan](prompt_plan.md) - Task tracking and workflow
- 📜 [Change Log](Changelog.md) - Detailed version history

## Contact

- GitHub: [@itrimble](https://github.com/itrimble)
- Project: [NotepadClone2](https://github.com/itrimble/NotepadClone2)

---

**Made with ❤️ using SwiftUI and Claude Code**

*Inspired by Notepad++ - Bringing powerful text editing to macOS*