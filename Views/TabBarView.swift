import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(appState.tabs.enumerated()), id: \.offset) { index, tab in
                    TabButton(
                        index: index,
                        tab: tab,
                        isSelected: index == appState.currentTab
                    )
                    .environmentObject(appState)
                    .onDrag {
                        // Provide the index of the dragged tab
                        NSItemProvider(object: String(index) as NSString)
                    }
                }
                
                // Add New Tab Button - Modified for direct action
                Button(action: {
                    // Call directly without dispatch queue wrapping
                    appState.newDocument()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(appState.appTheme.tabBarBackgroundColor()))
                .cornerRadius(4)
                .padding(.leading, 4)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .background(Color(appState.appTheme.tabBarBackgroundColor()))
        .onDrop(of: [UTType.text], delegate: TabDropDelegate(appState: appState, currentTabs: $appState.tabs))
    }
}

struct TabDropDelegate: DropDelegate {
    let appState: AppState
    @Binding var currentTabs: [Document]

    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [UTType.text]) else {
            return false
        }

        let items = info.itemProviders(for: [UTType.text])
        guard let item = items.first else { return false }

        item.loadObject(ofClass: NSString.self) { (draggedString, error) in
            if let draggedString = draggedString as? String, let sourceIndex = Int(draggedString) {
                DispatchQueue.main.async {
                    let dropLocation = info.location
                    var calculatedDestinationIndex = self.currentTabs.count // Default to end

                    // This approximation needs to be robust.
                    // It assumes TabButtons are of a somewhat consistent width.
                    // The padding/spacing of HStack and TabButton also matters.
                    // For an Hstack with spacing 0, and TabButtons with padding:
                    // Effective width = Text width + padding + close button width etc.
                    let tabButtonPadding: CGFloat = 8 * 2 // padding.horizontal for TabButton's HStack
                    let closeButtonWidth: CGFloat = 10 + 2 // Approx. systemName("xmark").width + padding
                    let textWidthApproximation: CGFloat = 60 // Average text width
                    let approximateTabWidth: CGFloat = textWidthApproximation + tabButtonPadding + closeButtonWidth
                    // Spacing in the parent HStack is 0.

                    if self.currentTabs.isEmpty {
                        calculatedDestinationIndex = 0
                    } else {
                        var currentXOffset: CGFloat = 0
                        var foundDestination = false
                        for i in 0..<self.currentTabs.count {
                            let tabMidX = currentXOffset + approximateTabWidth / 2
                            if dropLocation.x < tabMidX {
                                calculatedDestinationIndex = i
                                foundDestination = true
                                break
                            }
                            currentXOffset += approximateTabWidth
                        }
                        if !foundDestination {
                             // If dropLocation.x was greater than all midpoints, it's at the end
                            calculatedDestinationIndex = self.currentTabs.count
                        }
                    }

                    // `calculatedDestinationIndex` is the "visual slot" index.
                    // This is the index where the tab should appear in the list.
                    // If sourceIndex is 0, and we drop it at visual slot 2 (among 3 tabs A, B, C -> B, C, A (visually B, A, C initially))
                    // sourceIndex = 0 (A)
                    // calculatedDestinationIndex = 2 (meaning after C, if A was not there)
                    // A B C -> remove A -> B C. Insert A at index 2 -> B C A. Correct.

                    // If sourceIndex is 2 (C), and we drop it at visual slot 0
                    // A B C -> remove C -> A B. Insert C at index 0 -> C A B. Correct.

                    print("Drop attempt: source \(sourceIndex), visual dest \(calculatedDestinationIndex), dropLoc.x \(dropLocation.x), approxTabWidth \(approximateTabWidth)")

                    // No need to adjust calculatedDestinationIndex due to removal of sourceIndex,
                    // as AppState.moveTab's destinationIndex is the target index in the list *after* removal.
                    // However, if we are moving an item from left to right, and the target visual slot is `d`,
                    // after removing the item at `s` (where `s < d`), the target slot `d` effectively becomes `d-1`.
                    // If moving from right to left (`s > d`), the target slot `d` remains `d`.

                    var finalDestinationIndex = calculatedDestinationIndex
                    if sourceIndex < calculatedDestinationIndex {
                        // Dragging left-to-right. If tab is dropped at visual index `d`
                        // it means it should be placed *before* the item currently at `d`.
                        // After removing `sourceIndex`, items from `sourceIndex+1` to `d-1` shift left.
                        // So the insertion index becomes `d-1`.
                        finalDestinationIndex = calculatedDestinationIndex - 1
                    }
                    // If sourceIndex > calculatedDestinationIndex, finalDestinationIndex is calculatedDestinationIndex.
                    // If sourceIndex == calculatedDestinationIndex, it's a no-op (or should be handled by guard in moveTab).

                    // Clamp to valid range for insertion into (potentially) smaller list
                    finalDestinationIndex = max(0, min(finalDestinationIndex, self.currentTabs.count -1 < 0 ? 0 : self.currentTabs.count -1 ))


                    // The guard in AppState.moveTab checks:
                    // guard sourceIndex != destinationIndex (where destinationIndex is for insertion after removal)
                    // So, we can call it directly.
                    self.appState.moveTab(from: sourceIndex, to: finalDestinationIndex)
                }
            }
        }
        return true
    }

    // Optional: Provide visual feedback during dragging over
    func validateDrop(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }

    // Optional: Handle entering the drop zone
    func dropEntered(info: DropInfo) {
        // You can use this to change some state for visual feedback
    }

    // Optional: Handle exiting the drop zone
    func dropExited(info: DropInfo) {
        // Reset visual feedback state
    }
}

struct TabButton: View {
    @EnvironmentObject var appState: AppState
    let index: Int
    let tab: Document
    let isSelected: Bool
    
    // Computed properties to simplify expressions
    private var displayName: String {
        tab.displayName
    }
    
    private var hasUnsavedIndicator: some View {
        Circle()
            .fill(Color.orange)
            .frame(width: 6, height: 6)
    }
    
    private var closeButton: some View {
        Button(action: {
            // Call directly without dispatch queue wrapping
            appState.closeDocument(at: index)
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 2)
    }
    
    private var backgroundStyle: some View {
        let backgroundColor = isSelected ? Color(appState.appTheme.tabBarSelectedColor()) : Color.clear
        return RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
    }
    
    private var borderStyle: some View {
        let borderColor = isSelected ? Color(appState.appTheme.tabBarSelectedColor()) : Color.clear
        let lineWidth: CGFloat = 1
        return RoundedRectangle(cornerRadius: 4)
            .stroke(borderColor, lineWidth: lineWidth)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(displayName)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            if tab.hasUnsavedChanges {
                hasUnsavedIndicator
            }
            
            closeButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(backgroundStyle)
        .overlay(borderStyle)
        .onTapGesture {
            // Call directly without dispatch queue wrapping
            appState.selectTab(at: index)
        }
        .contextMenu {
            Button("Rename Tab") {
                showRenameAlert()
            }
            Button("Move to New Window") {
                appState.requestDetachTabToNewWindow(tabIndex: index)
            }
        }
    }

    private func showRenameAlert() {
        let alert = NSAlert()
        alert.messageText = "Rename Tab"
        alert.informativeText = "Enter the new name for the tab:"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = tab.displayName // Pre-fill with current name
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // Ensure alert runs on the main thread if this function could be called from elsewhere
        // For contextMenu, it's usually fine, but good practice for UI.
        DispatchQueue.main.async {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let newName = textField.stringValue
                if !newName.isEmpty {
                    appState.renameTab(at: index, newName: newName)
                }
            }
        }
    }
}

// Preview for Xcode development
#Preview {
    let appState = AppState()
    return tabBarView(appState: appState)
}

private func tabBarView(appState: AppState) -> some View {
    // Add a few tabs for preview
    appState.tabs.append(Document())
    appState.tabs[0].fileURL = URL(fileURLWithPath: "/test/document1.rtf")
    appState.tabs.append(Document())
    appState.tabs[1].text = "Some content"
    appState.currentTab = 0
    
    return TabBarView()
        .environmentObject(appState)
        .frame(height: 50)
}
