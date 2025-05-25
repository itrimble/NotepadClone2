import SwiftUI

struct TerminalPanelView: View {
    @ObservedObject var terminalManager: TerminalManager
    @State private var config = TerminalConfig()
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal tabs bar
            HStack(spacing: 0) {
                ForEach(terminalManager.terminals) { terminal in
                    TerminalTabView(
                        terminal: terminal,
                        isActive: terminal.id == terminalManager.activeTerminalId,
                        onSelect: {
                            terminalManager.activeTerminalId = terminal.id
                        },
                        onClose: {
                            terminalManager.closeTerminal(terminal)
                        }
                    )
                }
                
                // New terminal button
                Button(action: {
                    terminalManager.createNewTerminal()
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(NSColor.controlBackgroundColor))
                
                Spacer()
                
                // Close terminal panel button
                Button(action: {
                    terminalManager.showTerminal = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(NSColor.controlBackgroundColor))
            }
            .frame(height: 25)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Terminal content
            if let activeTerminal = terminalManager.activeTerminal {
                TerminalView(terminal: activeTerminal, config: config)
                    .background(Color(config.backgroundColor))
            } else {
                Text("No terminal selected")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
    }
}

struct TerminalTabView: View {
    let terminal: Terminal
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(terminal.title)
                .font(.system(size: 11))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .padding(.leading, 8)
            
            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 4)
            }
        }
        .frame(height: 25)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isActive ? Color(NSColor.controlAccentColor).opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect()
        }
    }
}