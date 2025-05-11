import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var cachedViews: [Int: AnyView] = [:]
    @State private var lastRefresh = Date()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Tab Bar
                if appState.tabs.count > 1 {
                    TabBarView()
                        .environmentObject(appState)
                        .animation(.easeInOut(duration: 0.2), value: appState.tabs.count)
                }
                
                // Cached Tab Content - instant switching
                if let currentTab = appState.currentTab,
                   currentTab >= 0 && currentTab < appState.tabs.count {
                    
                    // Use cached view or create new one
                    getCachedView(for: currentTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .animation(.none, value: currentTab)  // No animation for instant switching
                    
                    if appState.showStatusBar {
                        StatusBar(
                            characterCount: appState.tabs[currentTab].text.count,
                            wordCount: appState.tabs[currentTab].wordCount
                        )
                    }
                }
            }
            
            // Find Panel Overlay
            if appState.findManager?.showFindPanel == true {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        appState.findManager?.showFindPanel = false
                        appState.findManager?.showReplacePanel = false
                    }
                
                VStack {
                    Spacer()
                        .frame(height: 60)
                    
                    Group {
                        if let findManager = appState.findManager {
                            FindPanelWindow(findManager: findManager)
                                .background(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        }
                    }
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .preferredColorScheme(appState.colorScheme)
        .navigationTitle(appState.windowTitle)
        .onChange(of: appState.currentTab) { newTab in
            // Pre-cache adjacent tabs for faster switching
            if let current = newTab {
                preCacheTabs(around: current)
                
                // Trigger syntax highlighting refresh for new tab
                if let tab = appState.tabs[safe: current] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        tab.applyHighlighting()
                    }
                }
            }
        }
        .onAppear {
            // Initial setup
            if let currentTab = appState.currentTab {
                preCacheTabs(around: currentTab)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didChangeBackingPropertiesNotification)) { _ in
            // Refresh highlighting when display properties change
            refreshCurrentTabHighlighting()
        }
    }
    
    // MARK: - View Caching for Fast Tab Switching
    
    private func getCachedView(for index: Int) -> AnyView {
        // Return cached view if available
        if let cached = cachedViews[index] {
            return cached
        }
        
        // Create new view and cache it
        let view = AnyView(
            CustomTextView(
                text: $appState.tabs[index].text,
                attributedText: $appState.tabs[index].attributedText
            )
        )
        
        cachedViews[index] = view
        
        // Limit cache size to prevent memory issues
        if cachedViews.count > 10 {
            // Keep only the current tab and adjacent tabs
            let keysToKeep = Set([index - 1, index, index + 1].filter { $0 >= 0 && $0 < appState.tabs.count })
            cachedViews = cachedViews.filter { keysToKeep.contains($0.key) }
        }
        
        return view
    }
    
    private func preCacheTabs(around current: Int) {
        let indices = [current - 1, current, current + 1].filter { $0 >= 0 && $0 < appState.tabs.count }
        
        for index in indices {
            if cachedViews[index] == nil {
                _ = getCachedView(for: index)
            }
        }
    }
    
    private func refreshCurrentTabHighlighting() {
        guard let currentTab = appState.currentTab,
              currentTab >= 0 && currentTab < appState.tabs.count else { return }
        
        // Debounce rapid refresh calls
        let now = Date()
        if now.timeIntervalSince(lastRefresh) > 0.1 {
            lastRefresh = now
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appState.tabs[currentTab].applyHighlighting()
            }
        }
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Preview for Xcode development
#Preview {
    ContentView()
        .environmentObject(AppState())
}
