//
//  AppDelegate.swift
//  NotepadClone2
//
//  Created by Ian Trimble on 5/10/25.
//  Updated by Ian Trimble on 5/12/25.
//  Version: 2025-05-12
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    // Create a shared instance for easier access
    static let shared = AppDelegate()
    
    // Event monitor for debugging keyboard input
    private var eventMonitor: Any?
    
    // Static property to hold the app state
    private static var _appState: AppState?
    
    // Static setter method that doesn't require capturing self
    static func setAppState(_ appState: AppState) {
        _appState = appState
    }
    
    // Instance property that accesses the static property
    var appState: AppState? {
        return AppDelegate._appState
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable macOS native tabs for a Notepad++ like experience
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Configure app appearance and behavior
        // FIXED: Use currentDrawing() with parentheses as required by the API
        let appearance = NSAppearance.currentDrawing()
        NSApp.appearance = appearance
        
        // No casting needed - we access our app state directly
        
        // Ensure menus are properly set up
        setupApplicationMenus()
        
        // Set up keyboard event monitoring for debugging
        setupKeyboardMonitoring()
        
        // Debug log
        print("NotepadClone2 launched with native tabbing disabled")
        debugLog("🚀 Application launched, keyboard monitoring enabled")
    }
    
    private func setupApplicationMenus() {
        // Ensure the Edit menu supports all standard text editing commands
        let editMenu = NSApp.mainMenu?.item(withTitle: "Edit")
        if editMenu == nil {
            print("Warning: Edit menu not found. Some keyboard shortcuts may not work properly.")
        }
        
        // NOTE: Do not call terminate here - it would immediately close the app
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Behave like Notepad++ - quit when the last window is closed
        return true
    }
    
    private func setupKeyboardMonitoring() {
        // Monitor all keyboard events for debugging
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            debugLog("⌨️ KeyDown event: keyCode=\(event.keyCode), chars='\(event.characters ?? "")', modifiers=\(event.modifierFlags.rawValue)")
            
            // Log the responder chain
            if let window = NSApp.keyWindow {
                debugLog("🪟 Key window: \(window)")
                debugLog("🎯 First responder: \(window.firstResponder)")
                
                // Trace responder chain
                var responder: NSResponder? = window.firstResponder
                var chainDepth = 0
                while let r = responder, chainDepth < 10 {
                    debugLog("   📍 Responder[\(chainDepth)]: \(r)")
                    responder = r.nextResponder
                    chainDepth += 1
                }
            } else {
                debugLog("⚠️ No key window available")
            }
            
            return event // Pass the event through
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Final cleanup and state saving when app quits
        print("NotepadClone2 terminating, saving application state")
        debugLog("Application terminating")
    }
}

// Window Restoration Handler
class NotepadWindowRestorer: NSObject, NSWindowRestoration {
    static func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier,
                             state: NSCoder,
                             completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        // Implement window restoration
        print("Restoring window with identifier: \(identifier)")
        
        // For a more comprehensive restoration, you could:
        // 1. Create a new window
        // 2. Restore window position and size from state
        // 3. Restore document tabs from state
        
        // For now, we'll defer to the app's standard window creation
        completionHandler(nil, nil)
    }
}
