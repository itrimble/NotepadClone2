import Foundation
import AppKit

// Enum to represent different types of user actions that can be recorded
enum MacroActionType {
    case insertText(String)
    case deleteBackward
    case deleteForward
    // TODO: Add other actions like mouse clicks, selections, etc.
}

// Struct to store a single recorded action
struct MacroAction {
    let type: MacroActionType
    let timestamp: TimeInterval // Optional: for more advanced playback timing

    // TODO: Add properties for storing action-specific data, e.g., range for selection
}

class MacroManager {
    static let shared = MacroManager() // Singleton instance

    var recordedActions: [MacroAction] = [] // Made public for menu item enablement
    var isRecording: Bool = false // Made public for menu item title and enablement
    private var startTime: TimeInterval = 0
    var isPlayingBack: Bool = false // To prevent recording playback actions

    private init() {} // Private initializer for singleton

    func startRecording() {
        if isPlayingBack {
            print("MacroManager: Cannot start recording during playback.")
            return
        }
        guard !isRecording else {
            print("MacroManager: Already recording.")
            return
        }
        isRecording = true
        recordedActions.removeAll()
        startTime = ProcessInfo.processInfo.systemUptime
        print("MacroManager: Started recording.")
        NotificationCenter.default.post(name: .macroRecordingStateChanged, object: nil)
        NotificationCenter.default.post(name: .macroActionsUpdated, object: nil) // Actions are now empty
    }

    func stopRecording() {
        if isPlayingBack {
            print("MacroManager: Cannot stop recording during playback.")
            return
        }
        guard isRecording else {
            print("MacroManager: Not recording.")
            return
        }
        isRecording = false
        print("MacroManager: Stopped recording. Recorded \(recordedActions.count) actions.")
        NotificationCenter.default.post(name: .macroRecordingStateChanged, object: nil)
        // TODO: Optionally, save the recorded macro
    }

    func toggleRecording() {
        if isPlayingBack {
             print("MacroManager: Cannot toggle recording during playback.")
            return
        }
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func recordAction(type: MacroActionType) {
        if isPlayingBack { return } // Do not record actions performed during playback
        guard isRecording else { return }

        let action = MacroAction(type: type, timestamp: ProcessInfo.processInfo.systemUptime - startTime)
        recordedActions.append(action)
        print("MacroManager: Recorded action - \(type)")
        NotificationCenter.default.post(name: .macroActionsUpdated, object: nil)
    }

    func playback(on textView: NSTextView) {
        guard !recordedActions.isEmpty else {
            print("MacroManager: No actions to playback.")
            return
        }

        if isRecording {
            print("MacroManager: Stopping recording before playback.")
            stopRecording()
        }

        print("MacroManager: Starting playback of \(recordedActions.count) actions.")
        isPlayingBack = true // Set flag
        NotificationCenter.default.post(name: .macroPlaybackStateChanged, object: nil)


        // It's crucial that the textView is the first responder and ready for input.
        guard let window = textView.window, window.makeFirstResponder(textView) else {
            print("MacroManager: Could not make textView first responder for playback.")
            isPlayingBack = false // Reset flag
            NotificationCenter.default.post(name: .macroPlaybackStateChanged, object: nil)
            return
        }

        for action in recordedActions {
            // TODO: Consider playback timing using action.timestamp
            switch action.type {
            case .insertText(let text):
                // Using insertText:replacementRange: is generally safer as it respects delegate methods
                // and handles things like undo registration more cleanly than direct textStorage manipulation.
                textView.insertText(text, replacementRange: textView.selectedRange())
            case .deleteBackward:
                textView.deleteBackward(nil)
            case .deleteForward:
                textView.deleteForward(nil)
            // TODO: Handle other action types
            }
            // Optional: Add a small delay between actions for more realistic playback
            // RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }

        isPlayingBack = false // Reset flag
        print("MacroManager: Playback finished.")
        NotificationCenter.default.post(name: .macroPlaybackStateChanged, object: nil)
        NotificationCenter.default.post(name: .macroActionsUpdated, object: nil) // Refresh UI dependent on actions
    }

    // TODO: Add methods for saving/loading macros (e.g., to UserDefaults or a file)
}

extension Notification.Name {
    static let macroRecordingStateChanged = Notification.Name("macroRecordingStateChanged")
    static let macroActionsUpdated = Notification.Name("macroActionsUpdated")
    static let macroPlaybackStateChanged = Notification.Name("macroPlaybackStateChanged") // For playback start/finish
}
