import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
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
                        }
                    ),
                    attributedText: Binding(
                        get: { currentDocument.attributedText },
                        set: { newValue in
                            appState.tabs[currentIndex].attributedText = newValue
                        }
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id("tab_\(currentIndex)_\(currentDocument.id)") // Fixed: Use UUID without optional unwrapping
                
                // Status Bar with Transition
                if appState.showStatusBar {
                    StatusBar(
                        characterCount: currentDocument.text.count,
                        wordCount: currentDocument.wordCount
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
    }
}

// Preview for Xcode development
#Preview {
    ContentView()
        .environmentObject(AppState())
}
