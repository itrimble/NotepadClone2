# NotepadClone2

A powerful, modern text editor built for macOS using SwiftUI. Features multi-tab editing, syntax highlighting, and seamless session management.

## Features

### Core Functionality
- ✨ **Multi-tab Interface** - Work with multiple documents simultaneously
- 🎨 **Syntax Highlighting** - Support for Swift, Python, JavaScript, Bash, and AppleScript
- 💾 **Auto-save** - Configurable automatic saving with custom intervals
- 🔍 **Advanced Search** - Find, replace, and jump to line with regex support
- 📄 **Rich Text Support** - Full RTF editing capabilities
- 🌓 **Dark/Light Mode** - System appearance support with smooth transitions

### User Experience
- ⌨️ **Keyboard Shortcuts** - Comprehensive keyboard navigation
- 🎯 **Tab Management** - Easy tab creation, closing, and navigation (Cmd+1-9)
- 📊 **Status Bar** - Real-time character and word count
- 💾 **Session Restoration** - Automatically restore your work on app restart
- 🎨 **Customizable Themes** - Built-in syntax highlighting themes

## Screenshots

![NotepadClone2 Main Interface](screenshots/main-interface.png)
*Main interface with multi-tab support and syntax highlighting*

![Search and Replace](screenshots/search-replace.png)
*Powerful search and replace functionality*

## Installation

### Requirements
- macOS 13.0 or later
- Xcode 15.0 or later for building from source

### Building from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/NotepadClone2.git
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
1. Download the latest release from [GitHub Releases](https://github.com/your-username/NotepadClone2/releases)
2. Drag NotepadClone2.app to your Applications folder
3. Launch from Applications or Spotlight

## Usage

### Quick Start
1. Launch NotepadClone2
2. Start typing immediately or press ⌘O to open a file
3. Use ⌘T to create new tabs
4. Enable syntax highlighting by saving files with appropriate extensions

### Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| New Tab | ⌘T |
| Open File | ⌘O |
| Save | ⌘S |
| Save As | ⇧⌘S |
| Close Tab | ⌘W |
| Find | ⌘F |
| Replace | ⌥⌘F |
| Jump to Line | ⌘L |
| Switch Tabs | ⌘1-9 |
| Next Tab | ⌘] |
| Previous Tab | ⌘[ |

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

#### Auto-save Configuration
```swift
// Auto-save is enabled by default
// Customize interval in Preferences (coming soon)
```

#### Syntax Highlighting
Files are automatically detected by extension:
- `.swift` - Swift highlighting
- `.py` - Python highlighting
- `.js` - JavaScript highlighting
- `.sh` - Bash highlighting
- `.applescript` - AppleScript highlighting

## Architecture

### Project Structure
```
NotepadClone2/
├── NotepadCloneApp.swift          # App entry point
├── Components/
│   └── CustomTextView.swift       # NSTextView wrapper
├── Managers/
│   ├── AppState.swift            # Application state
│   └── FindPanelManager.swift    # Search functionality
├── Models/
│   └── Document.swift            # Document model
├── Utilities/
│   └── SyntaxHighlighter.swift   # Syntax highlighting
└── Views/
    ├── ContentView.swift         # Main interface
    ├── TabBarView.swift          # Tab management
    ├── StatusBar.swift           # Status display
    └── PreferencesWindow.swift   # Settings UI
```

### Key Components

#### AppState
- Manages all application state
- Handles document lifecycle
- Coordinates between views and models

#### Document
- Represents individual text documents
- Manages syntax highlighting
- Handles file I/O operations

#### CustomTextView
- SwiftUI wrapper for NSTextView
- Handles text editing and formatting
- Manages first responder status

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

### Testing
- Run all tests before submitting PR:
  ```bash
  xcodebuild test -scheme NotepadClone2
  ```
- Add tests for new features
- Ensure backward compatibility

## Troubleshooting

### Common Issues

#### App Crashes When Closing Tabs
- **Solution**: Ensure you're running the latest version with responder chain fixes

#### Syntax Highlighting Not Working
- **Check**: File extension is recognized
- **Try**: Manually set language via Format menu

#### Performance Issues with Large Files
- **Note**: Files over 5000 characters use debounced highlighting
- **Tip**: Consider splitting very large files

### Debug Mode
Enable debug logging by setting the environment variable:
```bash
NOTEPAD_DEBUG=1 open NotepadClone2.app
```

## Known Issues

- [ ] Auto-complete functionality not yet implemented
- [ ] Code folding pending development
- [ ] Limited language support for syntax highlighting

## Roadmap

### Version 2.0.0
- [ ] Plugin architecture
- [ ] Custom themes support
- [ ] Line numbers
- [ ] Code folding

### Version 2.1.0
- [ ] Auto-completion
- [ ] Multiple cursors
- [ ] Integrated terminal

### Version 2.2.0
- [ ] Git integration
- [ ] Collaborative editing

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

- Apple's SF Symbols for iconography
- SwiftUI community for inspiration
- Contributors and beta testers

## Contact

- GitHub: [@your-username](https://github.com/your-username)
- Email: your.email@example.com
- Twitter: [@your_handle](https://twitter.com/your_handle)

---

**Made with ❤️ using SwiftUI**
