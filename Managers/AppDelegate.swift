import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    weak var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable macOS native tabs for a Notepad++ like experience
        NSWindow.allowsAutomaticWindowTabbing = false
        
        // Configure app appearance and behavior
        // FIXED: Use currentDrawing() with parentheses as required by the API
        let appearance = NSAppearance.currentDrawing()
        NSApp.appearance = appearance
        
        // Set appState reference from application delegate
        if let appStateObject = (NSApp.delegate as? NotepadCloneApp)?.appState {
            self.appState = appStateObject
        }
        
        // Ensure menus are properly set up
        setupApplicationMenus()
        
        // Debug log
        print("NotepadClone2 launched with native tabbing disabled")
    }
    
    private func setupApplicationMenus() {
        // Ensure the Edit menu supports all standard text editing commands
        let editMenu = NSApp.mainMenu?.item(withTitle: "Edit")
        if editMenu == nil {
            print("Warning: Edit menu not found. Some keyboard shortcuts may not work properly.")
        }
        
        // NOTE: Do not call terminate here - it would immediately close the app
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Final cleanup and state saving when app quits
        print("NotepadClone2 terminating, saving application state")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Behave like Notepad++ - quit when the last window is closed
        return true
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
