import SwiftUI

// Helper class to force view refreshes
class RefreshTrigger: ObservableObject {
    @Published var id = UUID()
    
    func refresh() {
        DispatchQueue.main.async { [weak self] in
            self?.id = UUID()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    // Add explicit refresh trigger for forcing UI updates
    @StateObject private var refreshTrigger = RefreshTrigger()
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            if appState.tabs.count > 1 {
                TabBarView()
                    .environmentObject(appState)
            }
            
            // Current Tab Content
            if let currentIndex = appState.currentTab,
               currentIndex >= 0 && currentIndex < appState.tabs.count {
                
                let currentDocument = appState.tabs[currentIndex]
                
                CustomTextView(
                    text: Binding(
                        get: { currentDocument.text },
                        set: { newValue in
                            appState.tabs[currentIndex].text = newValue
                            // Force refresh when text changes
                            refreshTrigger.refresh()
                        }
                    ),
                    attributedText: Binding(
                        get: { currentDocument.attributedText },
                        set: { newValue in
                            appState.tabs[currentIndex].attributedText = newValue
                            // Force refresh when attributed text changes
                            refreshTrigger.refresh()
                        }
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id("tab_\(currentIndex)_\(currentDocument.id)")
                
                // Status Bar with Transition
                if appState.showStatusBar {
                    StatusBar(
                        characterCount: currentDocument.text.count,
                        wordCount: currentDocument.wordCount
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    // Make status bar dependent on refresh trigger
                    .id("status_\(refreshTrigger.id)")
                }
            } else {
                // Fallback for invalid tab state
                Text("No document selected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(appState.colorScheme)
        .navigationTitle(appState.windowTitle)
        .animation(.easeInOut(duration: 0.2), value: appState.showStatusBar)
        // Subscribe to document text change notifications
        .onAppear {
            setupNotificationObservers()
        }
        // Make view dependent on refresh trigger
        .id("content_\(refreshTrigger.id)")
        // Cleanup on disappear
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    // Separate method for observer setup to improve code organization
    private func setupNotificationObservers() {
        // Observe document text changes
        NotificationCenter.default.addObserver(
            forName: .documentTextDidChange,
            object: nil,
            queue: .main
        ) { [weak refreshTrigger] _ in
            // Force refresh when text changes
            refreshTrigger?.refresh()
        }
        
        // Observe document state changes (word count, etc.)
        NotificationCenter.default.addObserver(
            forName: .documentStateDidChange,
            object: nil,
            queue: .main
        ) { [weak refreshTrigger] _ in
            // Force refresh when state changes
            refreshTrigger?.refresh()
        }
        
        // Observe tab changes in app state
        NotificationCenter.default.addObserver(
            forName: .appStateTabDidChange,
            object: nil,
            queue: .main
        ) { [weak refreshTrigger] _ in
            // Force refresh when tabs change
            refreshTrigger?.refresh()
        }
    }
}

// Preview for Xcode development
#Preview {
    ContentView()
        .environmentObject(AppState())
}
