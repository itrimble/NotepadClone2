// Utilities/FileSystemWatcher.swift
import Foundation

class FileSystemWatcher {
    private let urlToWatch: URL
    private let eventHandler: () -> Void // Called when a file system event occurs

    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue(label: "com.notepadclone2.filesystemwatcher", qos: .utility)

    /// Initializes a new file system watcher.
    /// - Parameters:
    ///   - url: The URL of the directory or file to watch.
    ///   - eventHandler: A closure to be called when a file system event is detected.
    ///                  This handler is called on the main queue.
    init(url: URL, eventHandler: @escaping () -> Void) {
        self.urlToWatch = url
        self.eventHandler = eventHandler
        print("[FileSystemWatcher] Initialized for URL: \(url.path)")
    }

    deinit {
        stop()
        print("[FileSystemWatcher] Deinitialized for URL: \(urlToWatch.path)")
    }

    /// Starts monitoring the specified URL for file system changes.
    /// - Returns: `true` if watching started successfully, `false` otherwise.
    @discardableResult
    func start() -> Bool {
        // Ensure not already started
        guard dispatchSource == nil else {
            print("[FileSystemWatcher] Already watching URL: \(urlToWatch.path)")
            return true // Or false, depending on desired behavior for re-start
        }

        // Open a file descriptor for the URL
        // O_EVTONLY is important for watching directory changes without blocking deletion/renaming of the dir itself.
        self.fileDescriptor = open(urlToWatch.path, O_EVTONLY)
        if self.fileDescriptor == -1 {
            perror("[FileSystemWatcher] Failed to open file descriptor for URL: \(urlToWatch.path)")
            return false
        }

        // Create a dispatch source
        // Monitoring for: .write, .delete, .rename, .extend, .link, .attrib
        // .write is often triggered for many changes within a directory.
        let monitoredEvents: DispatchSource.FileSystemEvent = [
            .write, .delete, .rename, .extend, .link, .attrib
        ]

        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: self.fileDescriptor,
            eventMask: monitoredEvents,
            queue: self.queue // Process events on a background queue
        )

        guard let source = dispatchSource else {
            close(self.fileDescriptor) // Clean up file descriptor if source creation fails
            self.fileDescriptor = -1
            print("[FileSystemWatcher] Failed to create dispatch source for URL: \(urlToWatch.path)")
            return false
        }

        // Set the event handler
        source.setEventHandler { [weak self] in
            // It's good practice to dispatch UI-related updates or primary logic to the main queue
            DispatchQueue.main.async {
                print("[FileSystemWatcher] Event detected for URL: \(self?.urlToWatch.path ?? "unknown") - Flags: \(source.data)")
                self?.eventHandler()
            }
        }

        // Set the cancel handler to close the file descriptor
        source.setCancelHandler { [weak self] in
            guard let fd = self?.fileDescriptor, fd != -1 else { return }
            print("[FileSystemWatcher] Closing file descriptor \(fd) for URL: \(self?.urlToWatch.path ?? "unknown")")
            close(fd)
            self?.fileDescriptor = -1
        }

        // Resume the source to start receiving events
        source.resume()

        print("[FileSystemWatcher] Started watching URL: \(urlToWatch.path) with FD: \(self.fileDescriptor)")
        return true
    }

    /// Stops monitoring the URL for file system changes.
    func stop() {
        guard let source = dispatchSource else {
            // Not started or already stopped
            return
        }

        // Cancel the source. The cancel handler will close the file descriptor.
        source.cancel()
        self.dispatchSource = nil // Release the source
        print("[FileSystemWatcher] Stopped watching URL: \(urlToWatch.path)")
    }
}
