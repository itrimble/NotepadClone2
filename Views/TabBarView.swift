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
                }
                
                // Add New Tab Button
                Button(action: { appState.newDocument() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .padding(.leading, 4)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .background(Color.secondary.opacity(0.1))
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
        Button(action: { appState.closeDocument(at: index) }) {
            Image(systemName: "xmark")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 2)
    }
    
    private var backgroundStyle: some View {
        let backgroundColor = isSelected ? Color.accentColor.opacity(0.2) : Color.clear
        return RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
    }
    
    private var borderStyle: some View {
        let borderColor = isSelected ? Color.accentColor : Color.clear
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
            appState.selectTab(at: index)
        }
    }
}

// Preview for Xcode development
#Preview {
    let appState = AppState()
    tabBarView(appState: appState)
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
