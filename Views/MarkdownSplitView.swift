import SwiftUI
import WebKit // Added import for WKWebView
import Markdown // Added import for Markdown package

struct MarkdownSplitView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var document: Document
    @State private var previewScrollPosition: CGFloat = 0
    @State private var editorScrollPosition: CGFloat = 0
    @State private var splitRatio: CGFloat = 0.5
    @State private var syncScrolling: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Editor side
                VStack(spacing: 0) {
                    // Editor header
                    HStack {
                        Text("Editor")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        // Sync scrolling toggle
                        Button(action: { syncScrolling.toggle() }) {
                            Image(systemName: syncScrolling ? "link" : "link.badge.plus")
                                .foregroundColor(syncScrolling ? .accentColor : .secondary)
                                .help(syncScrolling ? "Disable synchronized scrolling" : "Enable synchronized scrolling")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    CustomTextView(
                        text: .constant(document.text),
                        attributedText: .constant(document.attributedText),
                        appTheme: appState.appTheme,
                        showLineNumbers: appState.showLineNumbers,
                        language: document.language,
                        document: document
                    )
                }
                .frame(width: geometry.size.width * splitRatio)
                
                // Divider
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 8)
                            .contentShape(Rectangle())
                            .cursor(.resizeLeftRight)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newRatio = value.location.x / geometry.size.width
                                        splitRatio = max(0.2, min(0.8, newRatio))
                                    }
                            )
                    )
                
                // Preview side
                VStack(spacing: 0) {
                    // Preview header
                    HStack {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Export menu
                        Menu {
                            Button(action: { exportToHTML() }) {
                                Label("Export as HTML", systemImage: "doc.text")
                            }
                            Button(action: { exportToPDF() }) {
                                Label("Export as PDF", systemImage: "doc.pdf")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Markdown preview
                    MarkdownPreviewView(
                        markdownText: document.text,
                        scrollPosition: $previewScrollPosition,
                        theme: appState.appTheme.rawValue // Changed .name to .rawValue
                    )
                }
                .frame(width: geometry.size.width * (1 - splitRatio))
            }
        }
    }
    
    private func exportToHTML() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.html]
        savePanel.nameFieldStringValue = (document.fileURL?.deletingPathExtension().lastPathComponent ?? "untitled") + ".html"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                let htmlContent = generateHTMLExport()
                do {
                    try htmlContent.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to export HTML: \(error)")
                }
            }
        }
    }
    
    private func exportToPDF() {
        // Create a temporary web view to render the content
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        let htmlContent = generateHTMLExport()
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        // Wait for content to load then print to PDF
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let printInfo = NSPrintInfo()
            printInfo.paperSize = NSSize(width: 595, height: 842) // A4
            printInfo.topMargin = 36
            printInfo.bottomMargin = 36
            printInfo.leftMargin = 36
            printInfo.rightMargin = 36
            
            let printOperation = webView.printOperation(with: printInfo)
            printOperation.showsPrintPanel = true
            printOperation.showsProgressPanel = true
            
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.pdf]
            savePanel.nameFieldStringValue = (document.fileURL?.deletingPathExtension().lastPathComponent ?? "untitled") + ".pdf"
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    printOperation.pdfPanel = NSPDFPanel()
                    printOperation.pdfPanel.options = [.showsPaperSize, .showsOrientation]
                    
                    if let pdfData = printOperation.createPDF() {
                        do {
                            try pdfData.write(to: url)
                        } catch {
                            print("Failed to export PDF: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func generateHTMLExport() -> String {
        let markdownDocument = Markdown.Document(parsing: document.text) // Restored Markdown parsing
        
        let isDark = appState.appTheme.rawValue == "Dark" || // Changed .name to .rawValue
                    appState.appTheme.rawValue == "Notepad++ Material Dark" || // Changed .name to .rawValue and updated string
                    appState.appTheme.rawValue == "Notepad++ Nord" // Changed .name to .rawValue and updated string
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(document.fileURL?.deletingPathExtension().lastPathComponent ?? "Markdown Document")</title>
            <style>
                \(getExportStyles(isDark: isDark))
            </style>
        </head>
        <body>
            <div class="markdown-body">
                \(markdownDocument.renderHTML()) 
            </div>
        </body>
        </html>
        """
    }
    
    private func getExportStyles(isDark: Bool) -> String {
        var styles = """
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            font-size: 16px;
            line-height: 1.6;
            color: #24292e;
            background-color: #ffffff;
            padding: 20px;
            max-width: 900px;
            margin: 0 auto;
        }
        
        .markdown-body {
            box-sizing: border-box;
            min-width: 200px;
            max-width: 980px;
            margin: 0 auto;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; border-bottom: 1px solid #e1e4e8; padding-bottom: .3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid #e1e4e8; padding-bottom: .3em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: .875em; }
        h6 { font-size: .85em; color: #6a737d; }
        
        p { margin-bottom: 16px; }
        
        code {
            padding: .2em .4em;
            margin: 0;
            font-size: 85%;
            background-color: #f0f0f0; /* Slightly adjusted light mode for inline code */
            border-radius: 3px;
            font-family: 'SF Mono', Consolas, 'Liberation Mono', Menlo, monospace;
            color: #24292e; /* Ensure inline code text color is set for light mode */
        }
        
        pre {
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: #f6f8fa;
            border-radius: 6px;
            color: #24292e; /* Ensure pre text color is set for light mode */
        }
        
        pre code {
            padding: 0;
            background-color: transparent;
            color: inherit; /* Inherit color from pre for code within pre */
        }
        
        blockquote {
            padding: 0 1em;
            color: #6a737d;
            border-left: .25em solid #dfe2e5;
            margin-bottom: 16px;
        }
        
        ul, ol {
            padding-left: 2em;
            margin-bottom: 16px;
        }
        
        li + li {
            margin-top: .25em;
        }
        
        a {
            color: #0366d6;
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        img {
            max-width: 100%;
            box-sizing: content-box;
        }
        
        table {
            border-spacing: 0;
            border-collapse: collapse;
            margin-bottom: 16px;
            width: 100%;
        }
        
        table th, table td {
            padding: 6px 13px;
            border: 1px solid #dfe2e5;
        }
        
        table th {
            font-weight: 600;
            background-color: #f6f8fa;
        }
        
        table tr {
            background-color: #ffffff;
        }
        
        table tr:nth-child(2n) {
            background-color: #f6f8fa;
        }
        
        hr {
            height: .25em;
            padding: 0;
            margin: 24px 0;
            background-color: #e1e4e8;
            border: 0;
        }
        """

        if isDark {
            styles += """
            body {
                color: #c9d1d9;
                background-color: #0d1117;
            }
            h1, h2 {
                border-bottom-color: #21262d; /* Darker border for dark mode */
            }
            h6 {
                color: #8b949e; /* Lighter gray for h6 in dark mode */
            }
            code {
                background-color: #22272e; /* Darker background for inline code */
                color: #c9d1d9; /* Light text for inline code */
            }
            pre {
                background-color: #161b22; /* Dark background for pre */
                color: #c9d1d9; /* Light text for pre */
            }
            blockquote {
                color: #8b949e; /* Lighter gray for blockquote text */
                border-left-color: #30363d; /* Darker border for blockquote */
            }
            a {
                color: #58a6ff; /* Brighter blue for links in dark mode */
            }
            table th, table td {
                border: 1px solid #30363d; /* Darker borders for table cells */
            }
            table th {
                background-color: #161b22; /* Darker background for table header */
            }
            table tr {
                background-color: #0d1117; /* Dark background for table rows */
            }
            table tr:nth-child(2n) {
                background-color: #161b22; /* Slightly lighter dark for alternate rows */
            }
            hr {
                background-color: #21262d; /* Darker hr */
            }
            """
        }

        styles += """
        @media print {
            body {
                background-color: white;
                color: black;
            }
            
            .markdown-body {
                padding: 0;
            }
            
            pre, code {
                background-color: #f6f8fa !important;
            }
            
            a {
                color: black;
                text-decoration: underline;
            }
        }
        """
    }
}

// Helper extension for cursor
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}