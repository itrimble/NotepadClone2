import SwiftUI

struct DetachDropZoneView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted: Bool = false

    var body: some View {
        Rectangle()
            .fill(isTargeted ? Color.blue.opacity(0.4) : Color.gray.opacity(0.2))
            .frame(height: isTargeted ? 60 : 40) // Make it slightly taller when targeted
            .overlay(
                Text("Drag tab here to open in new window")
                    .foregroundColor(isTargeted ? .white : .gray)
            )
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
            .onDrop(of: [UTType.text], isTargeted: $isTargeted) { providers in
                guard let item = providers.first else {
                    isTargeted = false
                    return false
                }

                item.loadObject(ofClass: NSString.self) { (draggedString, error) in
                    DispatchQueue.main.async { // Ensure UI updates on main thread
                        self.isTargeted = false // Reset highlight after drop attempt
                        if let error = error {
                            print("Error loading dragged tab data: \(error.localizedDescription)")
                            return
                        }
                        if let draggedString = draggedString as? String, let sourceIndex = Int(draggedString) {
                            print("DetachDropZone: Dropped tab with index \(sourceIndex)")
                            // Check if the sourceIndex is valid before calling.
                            // AppState will also guard, but good to be safe.
                            if sourceIndex >= 0 && sourceIndex < appState.tabs.count {
                                appState.requestDetachTabToNewWindow(tabIndex: sourceIndex)
                            } else {
                                print("DetachDropZone: Invalid sourceIndex \(sourceIndex). Tabs count: \(appState.tabs.count)")
                            }
                        } else {
                            print("DetachDropZone: Could not decode sourceIndex from dragged item.")
                        }
                    }
                }
                return true // Indicate that the drop was handled (or attempted)
            }
    }
}

#Preview {
    DetachDropZoneView()
        .environmentObject(AppState()) // Provide a dummy AppState for preview
}
