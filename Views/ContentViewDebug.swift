import SwiftUI

// Debug version of ContentView with colored rectangles for layout debugging
struct ContentViewDebug: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var refreshTrigger = RefreshTrigger()
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // File Explorer Sidebar - BLUE
                if appState.showFileExplorer {
                    Color.blue
                        .frame(width: 250)
                        .overlay(
                            Text("File Explorer\n(Blue)")
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        )
                    
                    Divider()
                }
                
                // Main Content Area
                VStack(spacing: 0) {
                    // Tab Bar - GREEN
                    if !appState.tabs.isEmpty {
                        Color.green
                            .frame(height: 30)
                            .overlay(
                                Text("Tab Bar (Green)")
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Editor Content - RED
                    if appState.splitViewEnabled {
                        // Split view mode - ORANGE/PURPLE
                        GeometryReader { geometry in
                            if appState.splitViewOrientation == .horizontal {
                                HSplitView {
                                    Color.orange
                                        .frame(minWidth: 200)
                                        .overlay(Text("Split Pane 1\n(Orange)").foregroundColor(.white))
                                    Divider()
                                    Color.purple
                                        .frame(minWidth: 200)
                                        .overlay(Text("Split Pane 2\n(Purple)").foregroundColor(.white))
                                }
                            } else {
                                VSplitView {
                                    Color.orange
                                        .frame(minHeight: 100)
                                        .overlay(Text("Split Pane 1\n(Orange)").foregroundColor(.white))
                                    Divider()
                                    Color.purple
                                        .frame(minHeight: 100)
                                        .overlay(Text("Split Pane 2\n(Purple)").foregroundColor(.white))
                                }
                            }
                        }
                    } else {
                        // Single editor mode - RED
                        Color.red
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                VStack {
                                    Text("Editor Area (Red)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    Text("splitViewEnabled: \(appState.splitViewEnabled ? "true" : "false")")
                                        .foregroundColor(.white)
                                    Text("tabs.count: \(appState.tabs.count)")
                                        .foregroundColor(.white)
                                    Text("currentTab: \(String(describing: appState.currentTab))")
                                        .foregroundColor(.white)
                                }
                            )
                    }
                    
                    // Status Bar - YELLOW
                    if appState.showStatusBar {
                        Color.yellow
                            .frame(height: 25)
                            .overlay(
                                Text("Status Bar (Yellow)")
                                    .foregroundColor(.black)
                            )
                    }
                } // End Main Content VStack
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } // End HStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            print("ContentViewDebug onAppear")
            print("  showFileExplorer: \(appState.showFileExplorer)")
            print("  splitViewEnabled: \(appState.splitViewEnabled)")
            print("  tabs.count: \(appState.tabs.count)")
            print("  currentTab: \(String(describing: appState.currentTab))")
            print("  showStatusBar: \(appState.showStatusBar)")
            
            // Force refresh
            refreshTrigger.refresh()
        }
        .id("contentViewDebug_\(refreshTrigger.id)_\(appState.showFileExplorer)_\(appState.splitViewEnabled)")
    }
}

// To use this debug view, temporarily replace ContentView() with ContentViewDebug() 
// in NotepadCloneApp.swift