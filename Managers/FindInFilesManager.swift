import Foundation
import AppKit

// MARK: - Search Options
struct SearchOptions {
    var caseSensitive: Bool = false
    var useRegex: Bool = false
    var fileExtensions: [String] = []
    var excludePatterns: [String] = []
    var maxResults: Int? = nil
    var contextLineCount: Int = 2
}

// MARK: - Search Result
struct SearchResult: Identifiable {
    let id = UUID()
    let file: URL
    let lineNumber: Int
    let matchedLine: String
    let contextLines: [String]
    let matchRange: NSRange
    
    var displayPath: String {
        file.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~")
    }
}

// MARK: - Find in Files Manager
class FindInFilesManager: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching: Bool = false
    @Published var searchProgress: Double = 0.0
    @Published var currentSearchPath: String = ""
    
    private var searchTask: Task<Void, Never>?
    private let fileManager = FileManager.default
    
    // MARK: - Search Implementation
    
    func search(for searchTerm: String, in directory: URL, options: SearchOptions) -> [SearchResult] {
        guard !searchTerm.isEmpty else { return [] }
        
        var results: [SearchResult] = []
        let searchPattern = prepareSearchPattern(searchTerm, options: options)
        
        // Get all files in directory
        guard let enumerator = fileManager.enumerator(at: directory,
                                                     includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles]) else {
            return []
        }
        
        for case let fileURL as URL in enumerator {
            // Check if we've reached max results
            if let maxResults = options.maxResults, results.count >= maxResults {
                break
            }
            
            // Apply filters
            if !shouldSearchFile(fileURL, options: options) {
                continue
            }
            
            // Search in file
            let fileResults = searchInFile(fileURL, pattern: searchPattern, options: options)
            results.append(contentsOf: fileResults)
            
            // Apply max results limit
            if let maxResults = options.maxResults, results.count > maxResults {
                results = Array(results.prefix(maxResults))
                break
            }
        }
        
        return results
    }
    
    // MARK: - Async Search
    
    @MainActor
    func performAsyncSearch(for searchTerm: String, in directory: URL, options: SearchOptions) async {
        // Cancel previous search
        searchTask?.cancel()
        
        searchResults = []
        isSearching = true
        searchProgress = 0.0
        
        searchTask = Task {
            await performSearch(searchTerm: searchTerm, directory: directory, options: options)
            
            await MainActor.run {
                isSearching = false
                searchProgress = 1.0
            }
        }
    }
    
    private func performSearch(searchTerm: String, directory: URL, options: SearchOptions) async {
        guard !searchTerm.isEmpty else { return }
        
        let searchPattern = prepareSearchPattern(searchTerm, options: options)
        // Removed: var results: [SearchResult] = [] - Results are now directly appended to self.searchResults
        
        // Count total files for progress
        let totalFiles = countFiles(in: directory, options: options)
        var processedFiles = 0
        
        guard let enumerator = fileManager.enumerator(at: directory,
                                                     includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles]) else {
            return
        }
        
        let allFileURLs = enumerator.allObjects.compactMap { $0 as? URL }
        
        for fileURL in allFileURLs {
            // Check cancellation
            if Task.isCancelled { break }
            
            // Update progress
            processedFiles += 1
            let progress = Double(processedFiles) / Double(max(totalFiles, 1))
            await MainActor.run {
                self.searchProgress = progress
                self.currentSearchPath = fileURL.lastPathComponent
            }
            
            // Apply filters
            if !shouldSearchFile(fileURL, options: options) {
                continue
            }
            
            // Search in file
            let fileResults = searchInFile(fileURL, pattern: searchPattern, options: options)
            
            if !fileResults.isEmpty {
                await MainActor.run {
                    self.searchResults.append(contentsOf: fileResults)
                }
            }
            
            // Check max results
            if let maxResults = options.maxResults, self.searchResults.count >= maxResults { // Check against self.searchResults
                break
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func prepareSearchPattern(_ searchTerm: String, options: SearchOptions) -> NSRegularExpression? {
        let pattern: String
        
        if options.useRegex {
            pattern = searchTerm
        } else {
            pattern = NSRegularExpression.escapedPattern(for: searchTerm)
        }
        
        let regexOptions: NSRegularExpression.Options = options.caseSensitive ? [] : .caseInsensitive
        
        return try? NSRegularExpression(pattern: pattern, options: regexOptions)
    }
    
    private func shouldSearchFile(_ fileURL: URL, options: SearchOptions) -> Bool {
        // Check if it's a regular file
        guard let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
              isRegularFile == true else {
            return false
        }
        
        let filename = fileURL.lastPathComponent
        let path = fileURL.path
        
        // Check file extensions
        if !options.fileExtensions.isEmpty {
            let fileExtension = fileURL.pathExtension.lowercased()
            if !options.fileExtensions.contains(where: { $0.lowercased() == fileExtension }) {
                return false
            }
        }
        
        // Check exclude patterns
        for pattern in options.excludePatterns {
            if path.contains(pattern) || filename.contains(pattern) {
                return false
            }
        }
        
        // Skip binary files
        if isBinaryFile(fileURL) {
            return false
        }
        
        return true
    }
    
    private func isBinaryFile(_ fileURL: URL) -> Bool {
        // Simple heuristic: check first 8KB for null bytes
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else { return true }
        defer { try? handle.close() }
        
        let sampleData = handle.readData(ofLength: 8192)
        return sampleData.contains(0)
    }
    
    private func searchInFile(_ fileURL: URL, pattern: NSRegularExpression?, options: SearchOptions) -> [SearchResult] {
        guard let pattern = pattern,
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        
        var results: [SearchResult] = []
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let lineRange = NSRange(location: 0, length: line.utf16.count)
            let matches = pattern.matches(in: line, options: [], range: lineRange)
            
            for match in matches {
                let contextLines = getContextLines(lines: lines, 
                                                  centerIndex: index, 
                                                  contextCount: options.contextLineCount)
                
                let result = SearchResult(
                    file: fileURL,
                    lineNumber: index + 1,
                    matchedLine: line,
                    contextLines: contextLines,
                    matchRange: match.range
                )
                
                results.append(result)
            }
        }
        
        return results
    }
    
    private func getContextLines(lines: [String], centerIndex: Int, contextCount: Int) -> [String] {
        let startIndex = max(0, centerIndex - contextCount)
        let endIndex = min(lines.count - 1, centerIndex + contextCount)
        
        var context: [String] = []
        for i in startIndex...endIndex {
            if i == centerIndex {
                context.append("> \(lines[i])")
            } else {
                context.append("  \(lines[i])")
            }
        }
        
        return context
    }
    
    private func countFiles(in directory: URL, options: SearchOptions) -> Int {
        var count = 0
        
        guard let enumerator = fileManager.enumerator(at: directory,
                                                     includingPropertiesForKeys: [.isRegularFileKey],
                                                     options: [.skipsHiddenFiles]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if shouldSearchFile(fileURL, options: options) {
                count += 1
            }
        }
        
        return count
    }
    
    // MARK: - Public Methods
    
    func cancelSearch() {
        searchTask?.cancel()
        isSearching = false
    }
    
    func clearResults() {
        searchResults = []
        searchProgress = 0.0
        currentSearchPath = ""
    }
}