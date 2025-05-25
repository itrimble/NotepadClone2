import SwiftUI
import WebKit
import Markdown

struct MarkdownPreviewView: NSViewRepresentable {
    let markdownText: String
    @Binding var scrollPosition: CGFloat
    let theme: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let htmlContent = renderMarkdownToHTML()
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MarkdownPreviewView
        
        init(_ parent: MarkdownPreviewView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Scroll to saved position after content loads
            let scrollScript = "window.scrollTo(0, \(parent.scrollPosition));"
            webView.evaluateJavaScript(scrollScript)
        }
    }
    
    private func renderMarkdownToHTML() -> String {
        // Parse markdown using swift-markdown
        let document = Document(parsing: markdownText)
        
        // Convert to HTML
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                \(getMarkdownStyles())
            </style>
        </head>
        <body>
            <div class="markdown-body">
                \(document.renderHTML())
            </div>
        </body>
        </html>
        """
        
        return htmlContent
    }
    
    private func getMarkdownStyles() -> String {
        let isDark = theme == "Dark" || theme == "Material Dark" || theme == "Nord"
        
        return """
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
            font-size: 14px;
            line-height: 1.6;
            color: \(isDark ? "#c9d1d9" : "#24292e");
            background-color: \(isDark ? "#0d1117" : "#ffffff");
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
        
        h1 { font-size: 2em; border-bottom: 1px solid \(isDark ? "#30363d" : "#e1e4e8"); padding-bottom: .3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid \(isDark ? "#30363d" : "#e1e4e8"); padding-bottom: .3em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: .875em; }
        h6 { font-size: .85em; color: \(isDark ? "#8b949e" : "#6a737d"); }
        
        p { margin-bottom: 16px; }
        
        code {
            padding: .2em .4em;
            margin: 0;
            font-size: 85%;
            background-color: \(isDark ? "#161b22" : "#f6f8fa");
            border-radius: 3px;
            font-family: 'SF Mono', Consolas, 'Liberation Mono', Menlo, monospace;
        }
        
        pre {
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: \(isDark ? "#161b22" : "#f6f8fa");
            border-radius: 6px;
        }
        
        pre code {
            padding: 0;
            background-color: transparent;
        }
        
        blockquote {
            padding: 0 1em;
            color: \(isDark ? "#8b949e" : "#6a737d");
            border-left: .25em solid \(isDark ? "#30363d" : "#dfe2e5");
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
            color: \(isDark ? "#58a6ff" : "#0366d6");
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
        }
        
        table th, table td {
            padding: 6px 13px;
            border: 1px solid \(isDark ? "#30363d" : "#dfe2e5");
        }
        
        table th {
            font-weight: 600;
            background-color: \(isDark ? "#161b22" : "#f6f8fa");
        }
        
        table tr {
            background-color: \(isDark ? "#0d1117" : "#ffffff");
        }
        
        table tr:nth-child(2n) {
            background-color: \(isDark ? "#161b22" : "#f6f8fa");
        }
        
        hr {
            height: .25em;
            padding: 0;
            margin: 24px 0;
            background-color: \(isDark ? "#30363d" : "#e1e4e8");
            border: 0;
        }
        """
    }
}

// Extension to render Markdown AST to HTML
extension Markup {
    func renderHTML() -> String {
        var renderer = HTMLRenderer()
        return renderer.render(self)
    }
}

// Basic HTML renderer for swift-markdown
struct HTMLRenderer {
    mutating func render(_ markup: Markup) -> String {
        switch markup {
        case let document as Document:
            return document.children.map { render($0) }.joined()
            
        case let heading as Heading:
            let level = heading.level
            let content = heading.children.map { render($0) }.joined()
            return "<h\(level)>\(content)</h\(level)>\n"
            
        case let paragraph as Paragraph:
            let content = paragraph.children.map { render($0) }.joined()
            return "<p>\(content)</p>\n"
            
        case let text as Text:
            return text.string.htmlEscaped()
            
        case let emphasis as Emphasis:
            let content = emphasis.children.map { render($0) }.joined()
            return "<em>\(content)</em>"
            
        case let strong as Strong:
            let content = strong.children.map { render($0) }.joined()
            return "<strong>\(content)</strong>"
            
        case let code as InlineCode:
            return "<code>\(code.code.htmlEscaped())</code>"
            
        case let codeBlock as CodeBlock:
            let language = codeBlock.language ?? ""
            let code = codeBlock.code.htmlEscaped()
            return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"
            
        case let link as Link:
            let content = link.children.map { render($0) }.joined()
            let href = link.destination ?? ""
            return "<a href=\"\(href.htmlEscaped())\">\(content)</a>"
            
        case let image as Image:
            let alt = image.children.map { render($0) }.joined()
            let src = image.source ?? ""
            return "<img src=\"\(src.htmlEscaped())\" alt=\"\(alt.htmlEscaped())\">"
            
        case let list as UnorderedList:
            let items = list.children.map { "<li>\(render($0))</li>" }.joined()
            return "<ul>\n\(items)\n</ul>\n"
            
        case let list as OrderedList:
            let items = list.children.map { "<li>\(render($0))</li>" }.joined()
            return "<ol>\n\(items)\n</ol>\n"
            
        case let listItem as ListItem:
            return listItem.children.map { render($0) }.joined()
            
        case let blockquote as BlockQuote:
            let content = blockquote.children.map { render($0) }.joined()
            return "<blockquote>\n\(content)</blockquote>\n"
            
        case let thematicBreak as ThematicBreak:
            return "<hr>\n"
            
        case let softBreak as SoftBreak:
            return " "
            
        case let lineBreak as LineBreak:
            return "<br>\n"
            
        case let htmlBlock as HTMLBlock:
            return htmlBlock.rawHTML
            
        case let inlineHTML as InlineHTML:
            return inlineHTML.rawHTML
            
        case let table as Table:
            return renderTable(table)
            
        default:
            // For any unhandled markup types, render children
            if let container = markup as? MarkupContainer {
                return container.children.map { render($0) }.joined()
            }
            return ""
        }
    }
    
    private mutating func renderTable(_ table: Table) -> String {
        var html = "<table>\n"
        
        // Render header if present
        if let head = table.head {
            html += "<thead>\n<tr>\n"
            for cell in head.cells {
                html += "<th>\(cell.children.map { render($0) }.joined())</th>\n"
            }
            html += "</tr>\n</thead>\n"
        }
        
        // Render body
        if let body = table.body {
            html += "<tbody>\n"
            for row in body.rows {
                html += "<tr>\n"
                for cell in row.cells {
                    html += "<td>\(cell.children.map { render($0) }.joined())</td>\n"
                }
                html += "</tr>\n"
            }
            html += "</tbody>\n"
        }
        
        html += "</table>\n"
        return html
    }
}

// HTML escaping extension
extension String {
    func htmlEscaped() -> String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}