import Foundation
import Combine
import AppKit // For NSTextView in playback (even if placeholder)

class MacroManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordedMacros: [String: Macro] = [:] // Keyed by Macro name

    private var currentRecordingActions: [MacroAction] = []
    private var lastRecordedUnsavedMacro: Macro?

    private let macrosFileURL: URL

    init() {
        // Determine file URL for storing macros
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.NotepadClone2" // Fallback bundle ID
        let macrosDir = appSupportDir.appendingPathComponent(bundleID).appendingPathComponent("Macros")

        // Create Macros directory if it doesn't exist
        try? FileManager.default.createDirectory(at: macrosDir, withIntermediateDirectories: true, attributes: nil)

        self.macrosFileURL = macrosDir.appendingPathComponent("macros.json")

        loadMacros()
    }

    func startRecording() {
        currentRecordingActions = []
        isRecording = true
        lastRecordedUnsavedMacro = nil // Clear any previously recorded unsaved macro
        print("Macro recording started.")
    }

    func stopRecording() -> Macro? {
        guard isRecording else { return nil }
        isRecording = false

        if currentRecordingActions.isEmpty {
            print("Macro recording stopped. No actions recorded.")
            lastRecordedUnsavedMacro = nil
            return nil
        }

        let newMacro = Macro(actions: currentRecordingActions)
        lastRecordedUnsavedMacro = newMacro // Store it in case user wants to play back immediately
        currentRecordingActions = [] // Clear for next recording
        print("Macro recording stopped. Recorded \(newMacro.actions.count) actions.")
        return newMacro
    }

    func recordAction(action: MacroAction) {
        guard isRecording else { return }
        currentRecordingActions.append(action)
        // print("Recorded action: \(action)") // Optional: for debugging
    }

    func saveNamedMacro(_ macro: Macro, name: String) {
        var macroToSave = macro
        if macroToSave.name == nil { // If it's an unnamed macro (e.g., from stopRecording)
            macroToSave.name = name
        } else if macroToSave.name != name { // If renaming an existing macro being saved under new name
             macroToSave.name = name // Ensure its internal name matches the key
        }

        recordedMacros[name] = macroToSave
        saveMacros()
        print("Saved macro: \(name)")
    }

    func getMacro(named name: String) -> Macro? {
        return recordedMacros[name]
    }

    func deleteMacro(name: String) {
        if recordedMacros.removeValue(forKey: name) != nil {
            saveMacros()
            print("Deleted macro: \(name)")
        }
    }

    func getLastRecordedMacro() -> Macro? {
        return lastRecordedUnsavedMacro
    }

    func playbackMacro(_ macro: Macro, on textView: NSTextView) {
        print("Playing back macro: \(macro.name ?? "Unnamed") with \(macro.actions.count) actions on \(textView).")

        guard !macro.actions.isEmpty else {
            print("Macro is empty, nothing to play back.")
            return
        }

        // Ensure playback happens on the main thread as it involves UI updates
        // and interactions with NSTextView.
        // If this method is already guaranteed to be called on main, DispatchQueue.main.async might be redundant
        // but it's safer for UI operations.
        // However, direct simulation might be better to ensure actions are sequential
        // and don't get reordered by async if not careful.
        // Let's assume for now it's called from a context that allows direct UI manipulation.
        // If issues arise, we can wrap it in DispatchQueue.main.async.

        textView.undoManager?.beginUndoGrouping()

        for action in macro.actions {
            // print("  Executing action: \(action)") // Optional: for debugging
            switch action {
            case .insertText(let text):
                // Ensure the replacement range is the current selection,
                // which is usually zero-length if just typing.
                // If the macro was recorded with selections being replaced, this will also work.
                textView.insertText(text, replacementRange: textView.selectedRange())
            case .deleteBackward:
                textView.deleteBackward(nil)
            case .deleteForward:
                textView.deleteForward(nil)
            case .moveCursorBackward:
                textView.moveLeft(nil) // Corresponds to moving the cursor left
            case .moveCursorForward:
                textView.moveRight(nil) // Corresponds to moving the cursor right
            // Add cases for other actions if they were defined and recorded
            // e.g., .setSelectedRange(let loc, let len):
            //   textView.setSelectedRange(NSRange(location: loc, length: len))
            }
            // Optional: Add a very small delay here if needed for very fast, long macros
            // to allow UI to update or to make playback observable.
            // However, for functional correctness, direct execution is usually preferred.
            // For example: RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01)) // Use with caution
        }

        textView.undoManager?.endUndoGrouping()

        // After playback, ensure the text view has focus if it doesn't already,
        // and that it scrolls to the final caret position.
        textView.window?.makeFirstResponder(textView)
        textView.scrollRangeToVisible(textView.selectedRange())

        print("Macro playback finished for: \(macro.name ?? "Unnamed")")
    }

    private func loadMacros() {
        guard FileManager.default.fileExists(atPath: macrosFileURL.path) else {
            print("Macro file not found at \(macrosFileURL.path). Starting with no saved macros.")
            return
        }

        do {
            let data = try Data(contentsOf: macrosFileURL)
            let decoder = JSONDecoder()
            recordedMacros = try decoder.decode([String: Macro].self, from: data)
            print("Successfully loaded \(recordedMacros.count) macros from \(macrosFileURL.path)")
        } catch {
            print("Error loading macros from \(macrosFileURL.path): \(error.localizedDescription)")
            // Handle error, e.g., by starting with an empty dictionary or attempting to recover/backup old file.
            recordedMacros = [:]
        }
    }

    private func saveMacros() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // For readability
            let data = try encoder.encode(recordedMacros)
            try data.write(to: macrosFileURL, options: .atomicWrite)
            print("Successfully saved \(recordedMacros.count) macros to \(macrosFileURL.path)")
        } catch {
            print("Error saving macros to \(macrosFileURL.path): \(error.localizedDescription)")
        }
    }
}
