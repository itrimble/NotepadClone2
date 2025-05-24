import SwiftUI

struct SplitEditorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var refreshTrigger = RefreshTrigger()
    
    var body: some View {
        GeometryReader { geometry in
            if appState.splitViewOrientation == .horizontal {
                HSplitView {
                    // Main editor
                    editorView(for: appState.currentTab, label: "Main")
                        .frame(minWidth: 200)
                    
                    // Split editor
                    editorView(for: appState.splitViewTabIndex, label: "Split")
                        .frame(minWidth: 200)
                }
            } else {
                VSplitView {
                    // Main editor
                    editorView(for: appState.currentTab, label: "Main")
                        .frame(minHeight: 100)
                    
                    // Split editor
                    editorView(for: appState.splitViewTabIndex, label: "Split")
                        .frame(minHeight: 100)
                }
            }
        }
    }
    
    @ViewBuilder
    private func editorView(for tabIndex: Int?, label: String) -> some View {
        if let index = tabIndex,
           index >= 0 && index < appState.tabs.count {
            let document = appState.tabs[index]
            
            VStack(spacing: 0) {
                // Editor header showing which file is open
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.secondary)
                    Text(document.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // Tab selector menu
                    Menu {
                        ForEach(Array(appState.tabs.enumerated()), id: \.offset) { idx, tab in
                            Button(action: {
                                if label == "Main" {
                                    appState.selectTab(at: idx)
                                } else {
                                    appState.setSplitViewTab(idx)
                                }
                            }) {
                                HStack {
                                    Text(tab.displayName)
                                    if (label == "Main" && idx == appState.currentTab) ||
                                       (label == "Split" && idx == appState.splitViewTabIndex) {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(appState.appTheme.tabBarBackgroundColor()))
                
                Divider()
                
                // Text editor
                CustomTextView(
                    text: Binding(
                        get: { document.text },
                        set: { newValue in
                            appState.tabs[index].text = newValue
                            refreshTrigger.refresh()
                        }
                    ),
                    attributedText: Binding(
                        get: { document.attributedText },
                        set: { newValue in
                            appState.tabs[index].attributedText = newValue
                            refreshTrigger.refresh()
                        }
                    ),
                    appTheme: appState.appTheme,
                    showLineNumbers: appState.showLineNumbers,
                    language: document.language,
                    document: document
                )
                .id("split_editor_\(label)_\(index)_\(document.id)")
            }
        } else {
            // Empty state
            VStack {
                Spacer()
                Text("No document selected")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

// Preview
#Preview {
    let appState = AppState()
    appState.tabs.append(Document())
    appState.tabs[0].text = "First document content"
    appState.tabs.append(Document())
    appState.tabs[1].text = "Second document content"
    appState.currentTab = 0
    appState.splitViewTabIndex = 1
    appState.splitViewEnabled = true
    
    return SplitEditorView()
        .environmentObject(appState)
}