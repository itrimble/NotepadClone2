# Claude Code Prompt Plan & Best Practices

## Overview
This document outlines the recommended workflow and best practices for using Claude Code effectively on the NotepadClone2 project, based on proven strategies from Harper's blog and current Claude Code best practices as of May 24, 2025.

**Important Project Documents:**
- 📋 `spec.md` - Complete project requirements and specifications
- 🤖 `CLAUDE.md` - Project context and AI-specific guidelines  
- ✅ `prompt_plan.md` - This file, tracking tasks and workflow
- 📝 `Changelog.md` - Detailed history of all changes

## Core Workflow

### 1. Initial Setup
- [x] Review `spec.md` for project requirements ✅ (Created 2025-05-24)
- [x] Check `CLAUDE.md` for project-specific guidelines ✅
- [x] Review this `prompt_plan.md` for incomplete tasks ✅
- [x] Set up development environment if needed ✅

### 2. Task Execution Protocol
When working with Claude Code, follow this systematic approach:

```
1. Check prompt_plan.md for next incomplete task
2. Implement the unfinished prompt
3. Test the implementation
4. Commit changes to repository
5. Update prompt_plan.md status
6. Pause for user review
7. Continue to next task
```

## Best Practices (May 2025)

### 1. Test-Driven Development (TDD)
**Claude Code excels at TDD - use it extensively!**

- [ ] Write tests BEFORE implementation
- [ ] Create comprehensive test suites for new features
- [ ] Use mocks and stubs to isolate components
- [ ] Run tests after each significant change
- [ ] Fix failing tests immediately

Example prompt:
```
"Write comprehensive unit tests for the split view functionality, including edge cases for empty documents, single document, and orientation changes. Then implement the feature to pass all tests."
```

### 2. Code Quality Tools
**Always use linters and formatters:**

- [ ] SwiftLint for Swift code quality
- [ ] Run `xcodebuild` to catch compilation errors
- [ ] Use Xcode's built-in analyzers
- [ ] Set up pre-commit hooks for automatic checks

### 3. Incremental Development
**Break large features into small, testable chunks:**

- [ ] Limit each task to 1-3 files maximum
- [ ] Complete one feature fully before moving to the next
- [ ] Use `TodoWrite` tool to track subtasks
- [ ] Commit after each successful implementation

### 4. Context Management
**Keep Claude Code's context focused:**

- [ ] Use specific file paths when asking questions
- [ ] Reference line numbers for precise edits
- [ ] Summarize progress regularly in CLAUDE.md
- [ ] Clear irrelevant context with targeted questions

### 5. Error Handling Strategy
**Defensive coding prevents cascading failures:**

- [ ] Add guard statements and nil checks
- [ ] Implement proper error messages
- [ ] Use Swift's Result type for fallible operations
- [ ] Test error paths explicitly

## Project-Specific Tasks

### Phase 1: Core Functionality ✅ COMPLETED
- [x] Fix search/replace functionality ✅
- [x] Fix theme implementation ✅
- [x] Verify tab switching behavior ✅
- [x] Add line numbers display ✅
- [x] Implement split pane view ✅

### Phase 2: Enhanced Features ✅ COMPLETED
- [x] Add Find in Files functionality ✅
  - [x] Create search results panel ✅
  - [x] Implement directory traversal ✅
  - [x] Add file filtering options ✅
  - [x] Display results with context ✅
  - Note: UI files created but need to be added to Xcode project
- [x] Enhance status bar ✅
  - [x] Add line:column position ✅
  - [x] Show selection information ✅
  - [x] Display file encoding ✅
  - [x] Add click actions for items ✅
- [x] Performance & Stability Fixes ✅
  - [x] Fix state modification warnings causing undefined behavior ✅
  - [x] Resolve typing responsiveness issues ✅
  - [x] Fix invisible text in dark themes ✅
  - [x] Add comprehensive typing performance tests ✅
  - [x] Optimize view refresh and notification systems ✅

### Phase 2.5: Drag & Drop and File Operations ✅ COMPLETED
- [x] Implement drag and drop file opening ✅
  - [x] Add drag and drop support to ContentView ✅
  - [x] Handle file URL validation and opening ✅
  - [x] Support multiple file drops at once ✅
  - [x] Add visual feedback during drag operations ✅
  - [x] Create comprehensive tests for drag and drop functionality ✅
  - [x] Integrate with existing file opening system ✅

### Phase 2.6: Code Intelligence ✅ COMPLETED (2025-05-24)
- [x] Implement code folding & intelligence ✅
  - [x] Detect foldable regions (functions, classes, blocks) ✅
  - [x] Add fold/unfold UI controls in gutter ✅
  - [x] Persist fold state per document ✅
  - [x] Bracket matching and highlighting ✅
  - [x] Smart indentation based on syntax ✅
  - Note: Auto-completion deferred to later phase

### Phase 2.7: Critical Bug Fixes ✅ COMPLETED (2025-05-24)
- [x] Fix text view initialization issues ✅
  - [x] Text view not accepting input ✅
  - [x] Missing cursor in editor ✅
  - [x] Proper first responder management ✅
- [x] Fix file loading issues ✅
  - [x] Plain text files read as RTF ✅
  - [x] Drag & drop content not displaying ✅
  - [x] UTF-8 encoding for text files ✅
- [x] Fix compilation errors ✅
  - [x] Optional unwrapping in AppState ✅
  - [x] Closure capture semantics ✅
  - [x] Unused variable warnings ✅

### Phase 2.8: Debug Logging System ✅ COMPLETED (2025-05-24 Session 2)
- [x] Add comprehensive debug logging ✅
  - [x] Create DebugLogger.swift utility ✅
  - [x] Add system-wide keyboard monitoring ✅
  - [x] Log text view lifecycle and delegate calls ✅
  - [x] Visual console output with emojis ✅
- [x] Fix color picker issue ✅
  - [x] Disabled usesFontPanel ✅
  - [x] No longer appears on launch ✅
- [x] Write text input tests ✅
  - [x] TDD approach for typing functionality ✅
  - [x] Tests written but need fixing ✅

### Known Issues 🔄
- [ ] Text input still not working
  - Debug logs added to diagnose issue
  - Need to analyze console output when typing
  - Check responder chain and delegate callbacks
- [x] Fix file loading issues ✅
  - [x] Plain text files read as RTF ✅
  - [x] Drag & drop content not displaying ✅
  - [x] UTF-8 encoding for text files ✅
- [x] Fix compilation errors ✅
  - [x] Optional unwrapping in AppState ✅
  - [x] Closure capture semantics ✅
  - [x] Unused variable warnings ✅

### Phase 3: File Management & Navigation
- [ ] Add file explorer sidebar
  - [ ] Create tree view component
  - [ ] Implement file operations
  - [ ] Add context menus
  - [ ] Support drag and drop
  - [ ] Show/hide with keyboard shortcut
  - [ ] Remember collapsed state
  - [ ] File watching for changes
- [ ] Implement document map/minimap
  - [ ] Create miniature view
  - [ ] Add navigation controls
  - [ ] Sync with main editor
  - [ ] Highlight visible area
  - [ ] Clickable navigation
  - [ ] Theme-aware rendering

### Phase 4: Advanced Editing Features
- [ ] Column Mode & Advanced Editing
  - [ ] Implement column/vertical selection mode
  - [ ] Multi-cursor editing support
  - [ ] Rectangular text operations
  - [ ] Column mode indicators
  - [ ] Alt+drag for column selection
  - [ ] Column copy/paste operations
- [ ] Auto-completion System
  - [ ] Word completion from current document
  - [ ] Language-specific keyword completion
  - [ ] Function/method suggestions
  - [ ] Path completion for imports
  - [ ] Snippet support
  - [ ] Customizable triggers
- [ ] Advanced Find & Replace
  - [ ] Regex builder UI
  - [ ] Find in selection
  - [ ] Preserve case replacements
  - [ ] History of searches
  - [ ] Saved search patterns

### Phase 5: Productivity Features
- [ ] Macro System
  - [ ] Record user actions as macros
  - [ ] Playback recorded macros
  - [ ] Save/load macro sets
  - [ ] Assign shortcuts to macros
  - [ ] Edit macro scripts
  - [ ] Share macros between documents
- [ ] Bookmarking System
  - [ ] Add/remove bookmarks on lines
  - [ ] Navigate between bookmarks
  - [ ] Bookmark indicators in gutter
  - [ ] Persist bookmarks per file
  - [ ] Named bookmarks
  - [ ] Bookmark panel
- [ ] Code Navigation
  - [ ] Go to definition
  - [ ] Find all references
  - [ ] Symbol browser
  - [ ] Breadcrumb navigation
  - [ ] Quick outline view

### Phase 6: Extended Support
- [ ] Encoding Support
  - [ ] Detect file encoding automatically
  - [ ] Convert between encodings (UTF-8, ANSI, etc.)
  - [ ] Encoding selection in status bar
  - [ ] Handle encoding errors gracefully
  - [ ] BOM detection and handling
  - [ ] Line ending conversion (CRLF/LF)
- [ ] Advanced Drag & Drop Features
  - [ ] Drag text within editor
  - [ ] Drop text from external apps
  - [ ] Drag and drop text reordering
  - [ ] Drag to create duplicates
  - [ ] Drop handlers for different content types

### Phase 7: Extensions & Integration
- [ ] Plugin System Architecture
  - [ ] Define plugin API
  - [ ] Create plugin loader
  - [ ] Implement sample plugins
  - [ ] Plugin marketplace UI
  - [ ] Plugin settings management
  - [ ] Security sandboxing
- [ ] Session Management
  - [ ] Save workspace sessions
  - [ ] Quick session switching
  - [ ] Session templates
  - [ ] Cloud session sync
  - [ ] Session history
  - [ ] Auto-save sessions
- [ ] External Tool Integration
  - [ ] Terminal integration
  - [ ] Build system support
  - [ ] Version control integration
  - [ ] External diff tools
  - [ ] Custom tool configuration

## Claude Code Interaction Prompts

### For New Features
```
"Let's implement [feature] following TDD principles. First, write comprehensive tests for [feature] including edge cases. Show me the test file, then implement the feature to pass all tests."
```

### For Bug Fixes
```
"I'm experiencing [issue]. Please:
1. Write a failing test that reproduces the bug
2. Fix the implementation to pass the test
3. Run all related tests to ensure no regression
4. Explain the root cause and fix"
```

### For Refactoring
```
"Let's refactor [component] for better [performance/readability/maintainability]. First, ensure comprehensive test coverage exists, then refactor while keeping all tests green."
```

### For Code Review
```
"Review the recent changes in [file] for:
1. Swift best practices
2. Potential bugs or edge cases
3. Performance implications
4. Suggestions for improvement"
```

## Memory and Context Tips

### 1. Use Explicit References
Instead of: "Fix the bug in the editor"
Use: "Fix the line number display bug in CustomTextView.swift:280-295"

### 2. Batch Related Operations
Instead of multiple separate requests, combine:
```
"In AppState.swift:
1. Add property for code folding state
2. Implement toggleFold method
3. Add notification for fold changes
Show all changes together."
```

### 3. Regular Summaries
After completing major features:
```
"Update CLAUDE.md with:
1. Summary of changes made today
2. Current state of the feature
3. Any outstanding issues
4. Next steps planned"
```

## Testing Checklist

Before considering any feature complete:
- [ ] Unit tests written and passing
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] UI tests for user interactions
- [ ] Performance tests for large documents
- [ ] Integration tests with other features

## Commit Message Format

Use clear, descriptive commit messages:
```
feat: Add split pane view with horizontal/vertical options
- Implement HSplitView/VSplitView for document editing
- Add menu items and keyboard shortcuts
- Support independent scrolling and selection
- Update theme colors for split pane headers
```

## Daily Workflow

1. **Start of Session**
   - Review this prompt_plan.md
   - Check incomplete tasks
   - Run tests to ensure clean state

2. **During Development**
   - Follow TDD cycle: Red → Green → Refactor
   - Commit after each green test
   - Update documentation as you go

3. **End of Session**
   - Run full test suite
   - Update prompt_plan.md progress
   - Summarize changes in CLAUDE.md
   - Commit all changes

## Anti-Patterns to Avoid

1. **Don't skip tests** - Claude Code excels at TDD
2. **Don't make massive changes** - Small, incremental steps
3. **Don't ignore linter warnings** - Fix them immediately
4. **Don't forget to commit** - Preserve working states
5. **Don't lose context** - Update docs regularly

## Useful Claude Code Commands

- `/memory` - Manage Claude's memory about the project
- `/help` - Get help with Claude Code features
- `continue` - Progress through multi-step tasks
- Use tool calls efficiently - batch related operations

## Project-Specific Guidelines

1. **SwiftUI + AppKit Bridge**
   - Test both SwiftUI and AppKit components
   - Ensure proper view update cycles
   - Handle platform-specific behaviors

2. **Theme System**
   - Test all themes when adding UI components
   - Ensure colors are theme-aware
   - Update both light and dark mode

3. **Performance**
   - Test with large documents (10k+ lines)
   - Profile memory usage
   - Optimize syntax highlighting

## Recent Achievements (2025-05-24)

### Code Intelligence Implementation
- ✅ Created comprehensive code folding system
- ✅ Implemented real-time bracket matching
- ✅ Added smart indentation with language awareness
- ✅ Fixed critical text view initialization bugs
- ✅ Resolved file loading issues for plain text
- ✅ Cleaned up all compilation warnings

### Next Priority: File Explorer Sidebar
The file explorer will provide project-wide navigation and should integrate with:
- Existing drag & drop system
- Theme system for consistent appearance
- Session state for remembering expanded folders
- Context menus for file operations

Remember: Claude Code works best with clear, specific instructions and a systematic approach. Use this plan as your guide for efficient, high-quality development.