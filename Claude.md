# Project Context for Claude (v2025-05-11)

## Project Overview

* **Project Name:** NotepadClone2
* **Project Description:** A macOS rich text editor with multi-tab support, inspired by Notepad++. Features include syntax highlighting, file management, search/replace functionality, and theme customization.
* **Contact Information:** Developer: Ian

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

* **Last conversation summary:** Fixing three primary issues in the application: unwanted automatic tab switching behavior, non-functional theme switching, and broken search/replace functionality. Additionally, a deprecated API call in AppDelegate needed to be updated and a type ambiguity error in window restoration needed to be resolved.

## File Descriptions

### Managers
* `AppDelegate.swift`: Application lifecycle management, appearance settings, and window restoration handling.
* `AppState.swift`: Central state management for the application, handling tabs, documents, and user interactions.
* `FindPanelManager.swift`: Handles search and replace functionality for text documents.

### Models
* `Document.swift`: Data model for text documents, including text content, file URL, and syntax highlighting settings.

### Components
* `CustomTextView.swift`: SwiftUI wrapper for NSTextView to enable rich text editing with bridging to AppKit.

### Views
* `ContentView.swift`: Main view of the application combining tab bar, text editor, and status bar.
* `TabBarView.swift`: Custom tab implementation for document switching.
* `StatusBar.swift`: Shows document statistics like word and character count.
* `PreferencesWindow.swift`: Settings interface for the application.

### Utilities
* `SyntaxHighlighter.swift`: Provides syntax highlighting for various programming languages.
* `ThemeConstants.swift`: Defines the available themes and their visual properties.
* `Notifications.swift`: Central place for all notification name declarations.

### Project Files
* `NotepadCloneApp.swift`: Main app entry point and menu configuration.
* `NotepadClone2.xcodeproj`: Xcode project file.

## Current Issues

1. **Tab Switching Behavior:** New tabs automatically become active when created, which should be optional.
2. **Theme Implementation:** Themes aren't working correctly, and there's confusion with duplicate Theme/Appearance menus.
3. **Search Functionality:** The search menu items (find, replace) don't perform any actions when clicked.

## Additional Notes

* The application uses a mix of SwiftUI and AppKit components to provide advanced text editing capabilities.
* Window state restoration is important for preserving user sessions.
* Theme management should support System, Light, Dark, and Notepad++-inspired themes.
* Uses the NSWindowRestoration protocol for window state persistence.
* Built using Xcode version 16.3 (16E140).
