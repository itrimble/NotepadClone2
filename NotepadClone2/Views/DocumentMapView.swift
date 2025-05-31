// Views/DocumentMapView.swift

import SwiftUI

struct DocumentMapView: View {
    @EnvironmentObject var appState: AppState
    var documentText: AttributedString // Or String, depending on how syntax highlighting is handled
    var visibleRect: CGRect // Represents the visible portion of the main editor

    // Configuration for drawing the minimap
    private let lineSpacing: CGFloat = 2.0 // Spacing between lines in the minimap
    private let charWidth: CGFloat = 1.0   // Width of a character representation in the minimap
    private let lineHeight: CGFloat = 1.5  // Height of a line representation

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Background
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(appState.currentTheme.editorBackgroundColor))

                // Simple representation of text lines
                let lines = documentText.description.split(separator: "\n", omittingEmptySubsequences: false)
                var yOffset: CGFloat = 0

                for lineText in lines {
                    // For now, just draw a small rectangle for each line
                    // Later, this can be more sophisticated, perhaps showing actual downscaled text or syntax colors
                    let lineWidth = min(CGFloat(lineText.count) * charWidth, size.width)
                    let lineRect = CGRect(x: 0, y: yOffset, width: lineWidth, height: lineHeight)
                    context.fill(Path(lineRect), with: .color(appState.currentTheme.textColor.opacity(0.5)))
                    yOffset += lineHeight + lineSpacing
                    if yOffset > size.height {
                        break // Stop if we exceed the minimap's height
                    }
                }

                // Draw visible area indicator
                // This needs to be scaled from the main editor's visibleRect to the minimap's coordinate space
                let documentTotalHeight = CGFloat(lines.count) * (lineHeight + lineSpacing)
                if documentTotalHeight > 0 {
                    let visibleRectHeightRatio = visibleRect.height / documentTotalHeight
                    let visibleRectYRatio = visibleRect.origin.y / documentTotalHeight

                    let indicatorHeight = min(size.height * visibleRectHeightRatio, size.height)
                    let indicatorY = size.height * visibleRectYRatio

                    let indicatorRect = CGRect(x: 0, y: indicatorY, width: size.width, height: indicatorHeight)
                    context.fill(Path(indicatorRect), with: .color(appState.currentTheme.textColor.opacity(0.2))) // Semi-transparent overlay
                     context.stroke(Path(indicatorRect), with: .color(appState.currentTheme.textColor.opacity(0.4)), lineWidth: 1) // Border for indicator
                }

            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let localClickY = value.location.y
                        let totalHeight = geometry.size.height

                        // Ensure totalHeight is not zero to prevent division by zero
                        guard totalHeight > 0 else { return }

                        // Clamp the clickY to be within the bounds of the view
                        let clampedY = max(0, min(localClickY, totalHeight))

                        let clickYRatio = clampedY / totalHeight

                        print("Minimap clicked at: \(value.location), ratio: \(clickYRatio)")
                        NotificationCenter.default.post(name: .minimapNavigateToRatio, object: clickYRatio)
                    }
            )
        }
        .frame(minWidth: 50, idealWidth: 80, maxWidth: 120) // Example frame, adjust as needed
        .background(appState.currentTheme.editorBackgroundColor)
        .border(appState.currentTheme.borderColor, width: 1) // Optional border
    }
}

// Basic Preview (won't work perfectly without full AppState)
struct DocumentMapView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock AppState or use a simplified one for previewing
        let mockAppState = AppState()
        // Populate with some dummy data if needed for preview
        // For example, set a theme:
        // mockAppState.setTheme(theme: .defaultLight)

        let sampleText = AttributedString("""
        func helloWorld() {
            print("Hello, world!")
            // This is a longer line to test wrapping or truncation in the minimap
            // Another line
            // And another
        }

        struct ContentView: View {
            var body: some View {
                Text("Preview")
            }
        }
        """)

        DocumentMapView(documentText: sampleText, visibleRect: CGRect(x: 0, y: 0, width: 500, height: 100))
            .environmentObject(mockAppState)
            .frame(width: 80, height: 300)
            .previewLayout(.sizeThatFits)
    }
}
