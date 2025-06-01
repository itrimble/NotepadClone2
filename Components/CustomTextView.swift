import SwiftUI
import AppKit
import Combine // For auto-completion debouncing

// Custom NSTextView subclass for Column Mode features
class ColumnarNSTextView: NSTextView {
    static let columnarTextPasteboardType = NSPasteboard.PasteboardType("com.example.NotepadClone2.columnarText")
    weak var columnCoordinator: CustomTextView.Coordinator?

    // MARK: - Columnar Selection Properties
    // Note: isOptionKeyDown is now directly managed by ColumnarNSTextView through flagsChanged
    var isPerformingColumnSelection: Bool = false
    var columnSelectionAnchorCharacterIndex: Int? // Character index at mousedown
    var columnSelectionEndCharacterIndex: Int?   // Character index at current mouse position during drag

    // The primary store for column selection. Each NSRange is for a line segment.
    var columnSelectedTextRanges: [NSRange]? {
        didSet {
            if columnSelectedTextRanges != nil {
                // When column selection is active, we might want to set
                // the primary selection differently or suppress default selection drawing.
                // For now, just mark that we need display update.
                self.needsDisplay = true
            } else {
                isPerformingColumnSelection = false // Ensure this is reset if ranges are cleared
                self.needsDisplay = true
            }
            // Update the AppState's isColumnModeActive based on the new selection state
            if let coordinator = self.columnCoordinator {
                 let isActive = columnSelectedTextRanges != nil && !(columnSelectedTextRanges?.isEmpty ?? true)
                 if coordinator.appState.isColumnModeActive != isActive {
                     DispatchQueue.main.async {
                         coordinator.appState.isColumnModeActive = isActive
                     }
                 }
            }
        }
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        // Update isOptionKeyDown based on the event directly here,
        // rather than relying on the coordinator to do it.
        // This is important if we are initiating selection from ColumnarNSTextView.
        let currentOptionState = event.modifierFlags.contains(.option)
        if self.isOptionKeyDown != currentOptionState {
            self.isOptionKeyDown = currentOptionState
            // print("TYPING_DEBUG: Option key is now \(self.isOptionKeyDown ? "DOWN" : "UP") from ColumnarNSTextView.flagsChanged")
        }

        // If option key is released during a column selection, finalize it or clear it.
        if !self.isOptionKeyDown && self.isPerformingColumnSelection {
            // Decide whether to keep the selection or clear it.
            // For now, let's clear it to simplify, similar to releasing the mouse button.
            // A more advanced implementation might keep the selection.
            // clearColumnSelection() // Or handle differently
        }
    }

    // It's generally good for custom NSTextView subclasses to explicitly state they can be first responder.
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
       self.isOptionKeyDown = event.modifierFlags.contains(.option) // Check at the start of mouse down
       if self.isOptionKeyDown {
           self.isPerformingColumnSelection = true
           // Clear previous column selection
           self.columnSelectedTextRanges = nil
           // Store the starting character index for the column selection
           let startingPoint = self.convert(event.locationInWindow, from: nil)
           self.columnSelectionAnchorCharacterIndex = self.characterIndexForInsertion(at: startingPoint)

           // Set a single caret at the mousedown location to provide immediate feedback
           if let anchorIndex = self.columnSelectionAnchorCharacterIndex {
               self.setSelectedRange(NSRange(location: anchorIndex, length: 0))
           }
           // Prevent normal text selection from starting by not calling super
       } else {
           self.isPerformingColumnSelection = false
           self.columnSelectedTextRanges = nil // Clear any existing column selection
           super.mouseDown(with: event) // Default behavior
       }
    }

    override func mouseDragged(with event: NSEvent) {
       if self.isPerformingColumnSelection, let layoutMgr = self.layoutManager, let textContainer = self.textContainer {
           guard let startCharIndex = self.columnSelectionAnchorCharacterIndex else { return }

           let currentPoint = self.convert(event.locationInWindow, from: nil)
           let currentCharIndex = self.characterIndexForInsertion(at: currentPoint)
           self.columnSelectionEndCharacterIndex = currentCharIndex

           // Determine the visual start and end points of the drag for rectangle calculation
           // We use characterIndexForInsertion to find the character index first, then get its bounding box.
           // This helps ensure the start/end points are valid insertion points.
           let startGlyphIndex = layoutMgr.glyphIndexForCharacter(at: startCharIndex)
           let currentGlyphIndex = layoutMgr.glyphIndexForCharacter(at: currentCharIndex)

           let startPointCoords = layoutMgr.boundingRect(forGlyphRange: NSRange(location: startGlyphIndex, length: 0), in: textContainer).origin
           let endPointCoords = layoutMgr.boundingRect(forGlyphRange: NSRange(location: currentGlyphIndex, length: 0), in: textContainer).origin

           let columnRect = NSRect(
               x: min(startPointCoords.x, endPointCoords.x),
               y: min(startPointCoords.y, endPointCoords.y), // Y might be less intuitive if dragging up/down across lines
               width: abs(startPointCoords.x - endPointCoords.x),
               height: abs(startPointCoords.y - endPointCoords.y) + layoutMgr.defaultLineHeight(for: NSFont.systemFont(ofSize: 14)) // Add line height to ensure full line coverage
           )

           var newRanges: [NSRange] = []
           let textNSString = self.string as NSString

           var lineCharIdx = 0
           while lineCharIdx < textNSString.length {
               let currentLineRange = textNSString.lineRange(for: NSRange(location: lineCharIdx, length: 0))
               let lineGlyphRange = layoutMgr.glyphRange(forCharacterRange: currentLineRange, actualCharacterRange: nil)
               let lineBoundingRect = layoutMgr.boundingRect(forGlyphRange: lineGlyphRange, in: textContainer)

               // Check if the line's Y range intersects with the columnRect's Y range
               if max(columnRect.minY, lineBoundingRect.minY) < min(columnRect.maxY, lineBoundingRect.maxY) {
                   // Determine start column character index for the current line
                   let startXPointInLine = NSPoint(x: columnRect.minX, y: lineBoundingRect.midY)
                   var selectionStartOnLine = layoutMgr.characterIndex(for: startXPointInLine, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                   selectionStartOnLine = max(currentLineRange.location, min(selectionStartOnLine, NSMaxRange(currentLineRange)))


                   // Determine end column character index for the current line
                   let endXPointInLine = NSPoint(x: columnRect.maxX, y: lineBoundingRect.midY)
                   var selectionEndOnLine = layoutMgr.characterIndex(for: endXPointInLine, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
                   selectionEndOnLine = max(currentLineRange.location, min(selectionEndOnLine, NSMaxRange(currentLineRange)))

                   let finalStart = min(selectionStartOnLine, selectionEndOnLine)
                   let finalEnd = max(selectionStartOnLine, selectionEndOnLine)

                   if finalStart <= finalEnd {
                        newRanges.append(NSRange(location: finalStart, length: finalEnd - finalStart))
                   }
               }
               if NSMaxRange(currentLineRange) >= textNSString.length { break }
               lineCharIdx = NSMaxRange(currentLineRange)
           }
           self.columnSelectedTextRanges = newRanges.isEmpty ? nil : newRanges
           self.setSelectedRange(NSMakeRange(currentCharIndex, 0)) // Keep a primary caret at current drag location
           self.setNeedsDisplay(self.bounds, avoidAdditionalLayout: false)

       } else {
           super.mouseDragged(with: event)
       }
    }

    override func mouseUp(with event: NSEvent) {
       if self.isPerformingColumnSelection {
           // Finalize column selection. `columnSelectedTextRanges` is already set.
           if self.columnSelectedTextRanges == nil || self.columnSelectedTextRanges?.isEmpty == true {
               self.columnSelectedTextRanges = nil // Ensure it's nil if empty
               // Restore a normal cursor at the mouse up position
               let clickPoint = self.convert(event.locationInWindow, from: nil)
               let charIndex = self.characterIndexForInsertion(at: clickPoint)
               self.setSelectedRange(NSRange(location: charIndex, length: 0))
           } else {
                // Successfully created a column selection.
                // The main selectedRange could be set to the first range, or the range containing the endCharIndex.
                if let endIdx = self.columnSelectionEndCharacterIndex,
                   let containingRange = self.columnSelectedTextRanges?.first(where: { NSLocationInRange(endIdx, $0) || $0.location == endIdx }) {
                    self.setSelectedRange(containingRange)
                } else if let firstRange = self.columnSelectedTextRanges?.first {
                    self.setSelectedRange(firstRange)
                }
           }
           // self.isPerformingColumnSelection remains true until Option key is up or new selection starts
           // Reset isOptionKeyDown because the mouse gesture has ended.
           // The isPerformingColumnSelection flag will be fully reset if Option key is released or new non-option click.
       } else {
           super.mouseUp(with: event)
       }
       // isOptionKeyDown should reflect the current actual key state after the event.
       // However, for the logic of a single drag, it might be better to clear it here
       // or ensure flagsChanged handles the reset of isPerformingColumnSelection if Option is released.
       // For now, let flagsChanged handle isOptionKeyDown state for subsequent events.
       // self.isOptionKeyDown = false; // This was in the prompt, but might be better handled by flagsChanged
    }

    // Add a helper to clear column selection state if needed
    func clearColumnSelection() {
        self.isPerformingColumnSelection = false
        self.columnSelectedTextRanges = nil
        // self.isOptionKeyDown = false; // isOptionKeyDown is managed by flagsChanged
        self.needsDisplay = true
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        if isPerformingColumnSelection, let currentRanges = columnSelectedTextRanges, !currentRanges.isEmpty, let ts = self.textStorage {
            guard let textToInsert = string as? String else {
                super.insertText(string, replacementRange: replacementRange)
                return
            }

            ts.beginEditing()
            var newCarets: [NSRange] = []
            let textNSString = ts.string as NSString

            // Determine the target visual column for padding.
            // This could be based on the columnSelectionAnchorCharacterIndex's line position,
            // or the maximum desired starting column among selections.
            // For simplicity, let's use the character index of each selection range's start
            // as the desired minimum column for that line.

            var accumulatedOffset = 0 // Tracks changes in length from previous insertions for current iteration

            for var currentRange in currentRanges.sorted(by: { $0.location > $1.location }) {
                // Adjust currentRange based on previous changes in this loop iteration
                // This is complex because sorted ranges are by original location.
                // A better way is to apply changes and rebuild the ranges array, or adjust offsets carefully.
                // For now, this simplified approach will have issues if textToInsert.count > 1 on multiple lines.
                // Let's assume textToInsert is usually a single character for typing.

                let lineRange = textNSString.lineRange(for: NSMakeRange(currentRange.location, 0))
                let actualLineEndCharIndex = NSMaxRange(lineRange) - (textNSString.substring(with: lineRange).hasSuffix("\n") ? 1 : 0)
                                     - (textNSString.substring(with: lineRange).hasSuffix("\r\n") ? 1 : 0)


                var spacesToInsert = ""
                if currentRange.location > actualLineEndCharIndex { // Caret is beyond the actual characters on the line
                    let paddingNeeded = currentRange.location - actualLineEndCharIndex
                    if paddingNeeded > 0 {
                        spacesToInsert = String(repeating: " ", count: paddingNeeded)
                    }
                }

                // The range where text/padding will actually be inserted/replaced.
                // If padding is needed, it's at actualLineEndCharIndex. Otherwise, it's at currentRange.location.
                let insertionPoint = spacesToInsert.isEmpty ? currentRange.location : actualLineEndCharIndex
                let effectiveReplacementLength = spacesToInsert.isEmpty ? currentRange.length : 0
                                                // If padding, we are inserting, not replacing existing selection part with spaces.
                                                // Any selected text in the column beyond actual line end is "virtual".

                let textToActuallyInsert = spacesToInsert + textToInsert

                let currentRangeToReplace = NSMakeRange(insertionPoint, effectiveReplacementLength)

                // Validate range before replacement
                let validLocation = max(0, min(currentRangeToReplace.location, ts.length))
                let validLength = max(0, min(currentRangeToReplace.length, ts.length - validLocation))
                let finalRangeToReplace = NSMakeRange(validLocation, validLength)

                ts.replaceCharacters(in: finalRangeToReplace, with: textToActuallyInsert)
                newCarets.append(NSMakeRange(finalRangeToReplace.location + (textToActuallyInsert as NSString).length, 0))
            }
            ts.endEditing()
            self.columnSelectedTextRanges = newCarets.isEmpty ? nil : newCarets.sorted(by: { $0.location < $1.location })
            self.needsDisplay = true
            // Let the textDidChange notification handle further updates.
            // Do not call super.insertText if we handled it.
            return
        }
        super.insertText(string, replacementRange: replacementRange)
    }

    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn: Bool) {
        // If column selection is active, draw multiple carets for zero-length ranges
        if isPerformingColumnSelection, let ranges = self.columnSelectedTextRanges, turnedOn {
            let caretColor = self.insertionPointColor
            caretColor.set()

            for range in ranges where range.length == 0 { // Only draw for zero-length ranges (carets)
                 if let layoutMgr = self.layoutManager, let textContainer = self.textContainer {
                    // Ensure location is valid
                    let charIdx = max(0, min(range.location, self.string.count))
                    let glyphIndex = layoutMgr.glyphIndexForCharacter(at: charIdx)

                    // Get rect for the insertion point.
                    // Using lineFragmentRect to get Y and height, and boundingRect for X.
                    var effectiveRange = NSRange()
                    let lineFragRect = layoutMgr.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange)
                    var insertionPointRect = layoutMgr.boundingRect(forGlyphRange: NSMakeRange(glyphIndex,0), in: textContainer)

                    insertionPointRect.origin.x += self.textContainerOrigin.x
                    // Use lineFragmentRect's Y for caret Y to ensure it's aligned with the line.
                    insertionPointRect.origin.y = lineFragRect.origin.y + self.textContainerOrigin.y
                    insertionPointRect.size.width = 1.0 // Caret width
                    insertionPointRect.size.height = lineFragRect.height // Caret height as line height

                    insertionPointRect.fill()
                }
            }
            // If we drew custom carets, or if there are non-caret selections, don't draw the default one.
            if !ranges.isEmpty { return }
        }
        // Default behavior if not in column selection or if column selection has no carets.
        super.drawInsertionPoint(in: rect, color: color, turnedOn: turnedOn)
    }

    override func drawBackground(in clipRect: NSRect) {
        super.drawBackground(in: clipRect) // Draw default background first

        // If column selection is active and we have ranges, draw them
        if isPerformingColumnSelection, let ranges = self.columnSelectedTextRanges,
           let layoutMgr = self.layoutManager, let textContainer = self.textContainer {

            var selectionColor: NSColor
            if let bgColor = self.selectedTextAttributes[.backgroundColor] as? NSColor {
                selectionColor = bgColor
            } else {
                selectionColor = NSColor.selectedTextBackgroundColor
            }
            // Apply transparency to the chosen color
            selectionColor.withAlphaComponent(0.3).set()

            for range in ranges where range.length > 0 { // Only draw for ranges with actual length
            guard range.location + range.length <= (textStorage?.length ?? 0) else { continue } // Bounds check

            // Get glyph range, handling potential errors if character range is invalid.
            let glyphRange: NSRange
            do {
                glyphRange = try layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            } catch {
                print("Error getting glyph range for char range \(range): \(error)")
                continue
            }

            layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange,
                                                 withinSelectedGlyphRange: NSMakeRange(NSNotFound, 0),
                                                 in: textContainer) { (rect, stop) in
                var viewRect = rect
                viewRect.origin.x += self.textContainerOrigin.x
                viewRect.origin.y += self.textContainerOrigin.y

                // Intersect with clipRect to avoid drawing outside dirty area (optional optimization)
                // let drawingRect = viewRect.intersection(clipRect)
                // if !drawingRect.isNull {
                //    NSBezierPath(rect: drawingRect).fill()
                // }
                // For simplicity, fill the viewRect. NSTextView handles clipping.
                NSBezierPath(rect: viewRect).fill()
            }
        }
    }

    override func deleteBackward(_ sender: Any?) {
        if isPerformingColumnSelection, let ranges = columnSelectedTextRanges, !ranges.isEmpty, let ts = self.textStorage {
            ts.beginEditing()
            var newCarets: [NSRange] = []
            // Iterate in reverse to maintain correct indices during modification
            ranges.sorted(by: { $0.location > $1.location }).forEach { range in
                var rangeToDelete = range
                if range.length == 0 { // Caret
                    if range.location > 0 { rangeToDelete = NSMakeRange(range.location - 1, 1) }
                    else {
                        newCarets.append(range) // Keep caret at beginning if nothing to delete
                        return
                    }
                }
                // Ensure rangeToDelete is valid before replacing
                if rangeToDelete.location < ts.length || (rangeToDelete.location == ts.length && rangeToDelete.length == 0) {
                     let actualLength = min(rangeToDelete.length, ts.length - rangeToDelete.location)
                     let validRangeToDelete = NSMakeRange(rangeToDelete.location, actualLength)
                     if validRangeToDelete.length > 0 || (range.length == 0 && range.location > 0) { // Ensure something is actually deleted for caret case
                        ts.replaceCharacters(in: validRangeToDelete, with: "")
                        newCarets.append(NSMakeRange(validRangeToDelete.location, 0))
                     } else {
                        newCarets.append(NSMakeRange(rangeToDelete.location,0)) // If nothing deleted, keep caret
                     }
                } else {
                     newCarets.append(NSMakeRange(ts.length,0)) // If range is somehow out of bounds, move caret to end
                }
            }
            ts.endEditing()
            // Update column selection to new caret positions
            self.columnSelectedTextRanges = newCarets.isEmpty ? nil : newCarets.sorted(by: { $0.location < $1.location })
            self.needsDisplay = true // Redraw to reflect changes
            return
        }
        // Fallback to super if not performing column selection with new system
        // The old coordinator-based logic is now removed.
        super.deleteBackward(sender)
    }

    override func deleteForward(_ sender: Any?) {
        if isPerformingColumnSelection, let ranges = columnSelectedTextRanges, !ranges.isEmpty, let ts = self.textStorage {
            ts.beginEditing()
            var newCarets: [NSRange] = []
            ranges.sorted(by: { $0.location > $1.location }).forEach { range in
                var rangeToDelete = range
                if range.length == 0 { // Caret
                    if range.location < ts.length { rangeToDelete = NSMakeRange(range.location, 1) }
                    else {
                        newCarets.append(range) // Keep caret at end if nothing to delete
                        return
                    }
                }
                // Ensure rangeToDelete is valid before replacing
                if rangeToDelete.location < ts.length {
                     let actualLength = min(rangeToDelete.length, ts.length - rangeToDelete.location)
                     let validRangeToDelete = NSMakeRange(rangeToDelete.location, actualLength)
                     if validRangeToDelete.length > 0 {
                         ts.replaceCharacters(in: validRangeToDelete, with: "")
                         newCarets.append(NSMakeRange(validRangeToDelete.location, 0)) // Caret stays at original location
                     } else {
                         newCarets.append(NSMakeRange(range.location, 0)) // If nothing deleted, keep caret
                     }
                } else {
                     newCarets.append(NSMakeRange(ts.length, 0)) // If range is somehow out of bounds, move caret to end
                }
            }
            ts.endEditing()
            self.columnSelectedTextRanges = newCarets.isEmpty ? nil : newCarets.sorted(by: { $0.location < $1.location })
            self.needsDisplay = true
            return
        }
        // Fallback to super if not performing column selection with new system
        // The old coordinator-based logic is now removed.
        super.deleteForward(sender)
    }

    override func copy(_ sender: Any?) {
        if isPerformingColumnSelection, let ranges = columnSelectedTextRanges, !ranges.isEmpty, let ts = self.textStorage {
            let strings = ranges.map { range -> String in
                // Ensure range is valid before attempting to substring
                let validLocation = max(0, min(range.location, ts.length))
                let validLength = max(0, min(range.length, ts.length - validLocation))
                let validRange = NSMakeRange(validLocation, validLength)
                if validRange.length > 0 || (range.length == 0 && validLocation <= ts.length) { // Allow empty string for carets
                    return (ts.string as NSString).substring(with: validRange)
                }
                return "" // Return empty string for invalid or truly empty ranges if not carets
            }
            let strings = ranges.map { range -> String in
                let validLocation = max(0, min(range.location, ts.length))
                let validLength = max(0, min(range.length, ts.length - validLocation))
                let validRange = NSMakeRange(validLocation, validLength)
                if validRange.length > 0 || (range.length == 0 && validLocation <= ts.length) {
                    return (ts.string as NSString).substring(with: validRange)
                }
                return ""
            }
            let finalTextToCopy = strings.joined(separator: "\n")

            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.declareTypes([.string, ColumnarNSTextView.columnarTextPasteboardType], owner: nil)
            pasteboard.setString(finalTextToCopy, forType: .string)
            // For the custom type, we can just set the same string, or a special marker/data if needed later.
            // Setting the same string for simplicity now.
            pasteboard.setString(finalTextToCopy, forType: ColumnarNSTextView.columnarTextPasteboardType)
            return
        }
        super.copy(sender)
    }

    override func paste(_ sender: Any?) {
        if isPerformingColumnSelection, let currentRanges = columnSelectedTextRanges, !currentRanges.isEmpty, let ts = self.textStorage {
            let pasteboard = NSPasteboard.general
            var pastedText: String? = nil
            var isColumnarData = false

            // Prioritize custom columnar type
            if let types = pasteboard.types, types.contains(ColumnarNSTextView.columnarTextPasteboardType) {
                pastedText = pasteboard.string(forType: ColumnarNSTextView.columnarTextPasteboardType)
                isColumnarData = true // Assume it's columnar if this type is present, even if string is same
                                      // For more robust check, custom type could store metadata.
            } else {
                pastedText = pasteboard.string(forType: .string)
            }

            guard let textToPaste = pastedText else {
                super.paste(sender)
                return
            }

            ts.beginEditing()
            var newCarets: [NSRange] = []
            let linesFromPasteboard = textToPaste.components(separatedBy: "\n")

            // Sort ranges from bottom to top (reverse by location) to preserve validity during modification
            let sortedRanges = currentRanges.sorted(by: { $0.location > $1.location })

            if linesFromPasteboard.count == 1 || !isColumnarData { // Single line from pasteboard OR standard (non-columnar) paste
                let singleLineToPaste = linesFromPasteboard.first ?? "" // Use first line, or full string if no newlines
                for range in sortedRanges {
                    let validLocation = max(0, min(range.location, ts.length))
                    let validLength = max(0, min(range.length, ts.length - validLocation))
                    let currentRangeToReplace = NSMakeRange(validLocation, validLength)

                    ts.replaceCharacters(in: currentRangeToReplace, with: singleLineToPaste)
                    newCarets.append(NSMakeRange(currentRangeToReplace.location + (singleLineToPaste as NSString).length, 0))
                }
            } else { // Multi-line columnar data from pasteboard AND multiple selection ranges
                if linesFromPasteboard.count == sortedRanges.count {
                    // Number of lines matches number of selections, paste line by line
                    for (index, range) in sortedRanges.enumerated() {
                        // Since sortedRanges is reversed, map linesFromPasteboard from its end
                        let pasteLine = linesFromPasteboard[linesFromPasteboard.count - 1 - index]

                        let validLocation = max(0, min(range.location, ts.length))
                        let validLength = max(0, min(range.length, ts.length - validLocation))
                        let currentRangeToReplace = NSMakeRange(validLocation, validLength)

                        ts.replaceCharacters(in: currentRangeToReplace, with: pasteLine)
                        newCarets.append(NSMakeRange(currentRangeToReplace.location + (pasteLine as NSString).length, 0))
                    }
                } else {
                    // Mismatched line counts: paste the ENTIRE multi-line string at each selection point
                    for range in sortedRanges {
                        let validLocation = max(0, min(range.location, ts.length))
                        let validLength = max(0, min(range.length, ts.length - validLocation))
                        let currentRangeToReplace = NSMakeRange(validLocation, validLength)

                        ts.replaceCharacters(in: currentRangeToReplace, with: textToPaste) // textToPaste is the full multi-line string
                        newCarets.append(NSMakeRange(currentRangeToReplace.location + (textToPaste as NSString).length, 0))
                    }
                }
            }

            ts.endEditing()
            self.columnSelectedTextRanges = newCarets.isEmpty ? nil : newCarets.sorted(by: { $0.location < $1.location })
            self.needsDisplay = true
            return
        }
        super.paste(sender: sender)
    }

    // Override keyDown to handle auto-completion navigation

            var stringForThisCaret: String
            if linesToPaste.count == 1 {
                stringForThisCaret = linesToPaste.first ?? ""
            } else {
                stringForThisCaret = (originalSelectionOrderIndex < linesToPaste.count) ? linesToPaste[originalSelectionOrderIndex] : ""
            }

            let currentTextLength = textStorage.length
            // Ensure location is valid before proceeding with replacement
            guard rangeToReplace.location <= currentTextLength else {
                 // If the original location is now beyond the text (due to shorter pastes on prior lines),
                 // decide on a strategy: skip, or append at end.
                 // For now, let's try to append at the current end of the text if it's truly out of bounds.
                 // This might break column alignment but prevents crashes.
                 // A more robust solution might involve complex tracking of line endings or padding.
                 // However, the reverse iteration should largely prevent this unless lines are deleted entirely.
                 // A simpler skip:
                 // newCaretPositions.append(NSMakeRange(min(rangeToReplace.location, currentTextLength), 0)) // keep a caret at a safe spot
                 // continue

                 // For this iteration, let's use the provided logic which includes a safeguard:
                 let safeLocation = min(rangeToReplace.location, currentTextLength)
                 let safeLength = min(rangeToReplace.length, max(0, currentTextLength - safeLocation)) // max(0,...) ensures length isn't negative
                 let safeRangeToReplace = NSMakeRange(safeLocation, safeLength)

                 textStorage.replaceCharacters(in: safeRangeToReplace, with: stringForThisCaret)
                 newCaretPositions.append(NSMakeRange(safeRangeToReplace.location + (stringForThisCaret as NSString).length, 0))
                 continue
            }

            let validLength = min(rangeToReplace.length, currentTextLength - rangeToReplace.location)
            let actualRangeToReplace = NSMakeRange(rangeToReplace.location, validLength)

            textStorage.replaceCharacters(in: actualRangeToReplace, with: stringForThisCaret)

            let newCaretLocation = actualRangeToReplace.location + (stringForThisCaret as NSString).length
            newCaretPositions.append(NSMakeRange(newCaretLocation, 0))
        }

        coordinator.currentColumnSelections = newCaretPositions.sorted(by: { $0.location < $1.location })

        textStorage.endEditing()
        self.needsDisplay = true

        print("TYPING_DEBUG: Column paste performed.")
    }

    // Override keyDown to handle auto-completion navigation
    override func keyDown(with event: NSEvent) {
        if isPerformingColumnSelection {
            // Check for Escape key first
            if event.keyCode == 53 { // Escape Key
                // Try to restore selection to where column mode started, or first selection
                let caretToRestore = columnSelectionAnchorCharacterIndex ?? columnSelectedTextRanges?.first?.location ?? selectedRange().location
                clearColumnSelection()
                setSelectedRange(NSRange(location: caretToRestore, length: 0))
                // print("Column mode cancelled by Escape. Caret restored to \(caretToRestore)")
                return // Event handled
            }
            // Check for Arrow keys
            // 123: Left, 124: Right, 125: Down, 126: Up
            if event.keyCode >= 123 && event.keyCode <= 126 {
                 // Determine a primary caret position to restore to before clearing column mode.
                 // This could be the anchor, or the start/end of the first/last range.
                 // Using columnSelectionAnchorCharacterIndex is a good candidate.
                let caretToRestore = columnSelectionAnchorCharacterIndex ?? columnSelectedTextRanges?.first?.location ?? selectedRange().location
                clearColumnSelection()
                setSelectedRange(NSRange(location: caretToRestore, length: 0))
                // print("Column mode cancelled by Arrow key. Caret restored to \(caretToRestore)")
                // Do NOT call super.keyDown. Let the system handle the arrow key in the next event cycle
                // on the now normal (single) selection. This avoids double-processing the arrow key.
                // The user will press arrow again if they want to navigate from this new caret.
                // Alternatively, to make it move on the first press:
                // super.keyDown(with: event) // after clearing mode and setting cursor
                return // Event handled by cancelling column mode
            }
        }

        if let coordinator = self.columnCoordinator, coordinator.isCompletionViewPresented {
            switch event.keyCode {
            case 126: // Up Arrow (Completion List Navigation)
                coordinator.navigateCompletionList(direction: -1)
                return
            case 125: // Down Arrow (Completion List Navigation)
                coordinator.navigateCompletionList(direction: 1)
                return
            case 36:  // Enter (Completion List Confirmation)
                coordinator.confirmCurrentSuggestion(in: self)
                return
            case 48: // Tab (Completion List Confirmation)
                 coordinator.confirmCurrentSuggestion(in: self)
                 return
            case 53:  // Escape (Completion List Dismissal)
                coordinator.hideCompletionView()
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }

    func triggerCompletionManually() {
        if let coordinator = self.columnCoordinator {
            coordinator.triggerAutoCompletion(for: self, textContent: self.string)
        }
    }

    @objc func triggerAutoCompletionAction(_ sender: Any?) {
        // Call the existing manual trigger logic.
        // This assumes `triggerCompletionManually` is a method on ColumnarNSTextView itself.
        self.triggerCompletionManually()
    }
}

struct CustomTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @EnvironmentObject var appState: AppState // Added to access AppState
    @Environment(\.colorScheme) var colorScheme
    let appTheme: AppTheme
    let showLineNumbers: Bool
    let language: SyntaxHighlighter.Language
    let document: Document  // Pass the document directly
    let appState: AppState // Added AppState
    
    func makeNSView(context: Context) -> NSScrollView {
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Creating ColumnarNSTextView and NSScrollView")

        // Create the custom text view instance
        let textView = ColumnarNSTextView(frame: .zero)
        // Assign coordinator references
        textView.columnCoordinator = context.coordinator
        context.coordinator.textView = textView // For existing coordinator logic

        // Create the scroll view
        let scrollView = NSScrollView()
        scrollView.documentView = textView

        // Configure scroll view (moved up, applied to new scrollView instance)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false // Typically false for code editors
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - ScrollView: \(scrollView), TextView: \(textView)")

        // Configure text view for proper text handling (applied to new textView instance)
        textView.isRichText = true
        textView.usesFontPanel = false  // Disable font panel to prevent color picker
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: usesFontPanel = \(textView.usesFontPanel)")
        textView.allowsUndo = true
        textView.delegate = context.coordinator  // Set delegate after other properties
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Delegate set: \(textView.delegate != nil)")
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
        
        // CRITICAL: Make text view editable and visible
        textView.isEditable = true
        textView.isSelectable = true
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: isEditable = \(textView.isEditable), isSelectable = \(textView.isSelectable)")
        textView.importsGraphics = false
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Initial configuration: importsGraphics = \(textView.importsGraphics)")
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        // Ensure proper cursor and interaction
        textView.insertionPointColor = appTheme.editorTextColor()
        textView.isFieldEditor = false
        textView.usesInspectorBar = false
        textView.drawsBackground = true
        textView.backgroundColor = appTheme.editorBackgroundColor()
        
        // Enable ruler view for line numbers if enabled
        if showLineNumbers {
            scrollView.hasVerticalRuler = true
            scrollView.rulersVisible = true
            
            // Create and configure line number ruler with folding support
            let lineNumberView = CodeFoldingRulerView(scrollView: scrollView, orientation: .verticalRuler)
            lineNumberView.clientView = textView
            lineNumberView.ruleThickness = 60.0  // Wider to accommodate fold controls
            lineNumberView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
            lineNumberView.textColor = appTheme.editorTextColor() // Make base color more solid
            lineNumberView.language = language
            lineNumberView.coordinator = context.coordinator
            scrollView.verticalRulerView = lineNumberView

            // Add color clash logging for line number ruler
            if lineNumberView.textColor.isApproximatelyEqual(to: lineNumberView.backgroundColor) {
                print("TYPING_DEBUG: WARNING LineNumberView.makeNSView - Line number text color and background color are very similar. Line numbers may be invisible. Text Color: \(lineNumberView.textColor), Background Color: \(lineNumberView.backgroundColor)")
            }
        } else {
            scrollView.hasVerticalRuler = false
            scrollView.rulersVisible = false
        }
        
        // Set up initial theme
        context.coordinator.updateTheme(textView)
        context.coordinator.textView = textView // Store weak reference to textView

        // Setup bounds observer for scrolling
        if let clipView = scrollView.contentView as? NSClipView {
            context.coordinator.setupBoundsObserver(for: clipView)
        }
        
        // Set initial text with proper attributes
        let defaultAttributes = context.coordinator.defaultAttributes()
        
        // Clear approach: set the text directly with attributes
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: defaultAttributes))
        
        // Ensure text container is properly configured
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = CGSize(width: max(100, scrollView.frame.width), height: CGFloat.greatestFiniteMagnitude)
        }
        
        // Force initial layout
        textView.needsLayout = true
        scrollView.needsLayout = true
        
        // Set typing attributes for new text
        textView.typingAttributes = defaultAttributes
        print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Default typing attributes: \(defaultAttributes)") // Corrected typo makeNSVew -> makeNSView
        
        // Make text view the first responder when window is ready.
        // This is deferred to ensure the window and view hierarchy are fully set up.
        DispatchQueue.main.async {
            if let window = textView.window {
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Attempting to make first responder. Window: \(window), isKey: \(window.isKeyWindow), isVisible: \(window.isVisible)")
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Current first responder before attempt: \(String(describing: window.firstResponder))")
                let success = window.makeFirstResponder(textView)
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - First responder attempt outcome: \(success ? "SUCCESS" : "FAILURE")")
                print("TYPING_DEBUG: 🔧 CustomTextView.makeNSView - Current first responder after attempt: \(String(describing: window.firstResponder))")
            } else {
                print("TYPING_DEBUG: ❌ CustomTextView.makeNSView - No window available for first responder")
            }
        }
        
        print("TYPING_DEBUG: ✅ CustomTextView.makeNSView - Complete, returning scrollView")
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        print("TYPING_DEBUG: 🔄 CustomTextView.updateNSView - Called, textView: \(textView)")
        
        // Always update theme when view updates
        context.coordinator.updateTheme(textView)
        
        // Update line numbers visibility
        if showLineNumbers {
            nsView.hasVerticalRuler = true
            nsView.rulersVisible = true
            if let codeRulerView = nsView.verticalRulerView as? CodeFoldingRulerView {
                codeRulerView.backgroundColor = NSColor(appTheme.tabBarBackgroundColor())
                codeRulerView.textColor = appTheme.editorTextColor() // Make base color more solid
                
                // Add color clash logging for line number ruler
                if codeRulerView.textColor.isApproximatelyEqual(to: codeRulerView.backgroundColor) {
                    print("TYPING_DEBUG: WARNING LineNumberView.updateNSView - Line number text color and background color are very similar. Line numbers may be invisible. Text Color: \(codeRulerView.textColor), Background Color: \(codeRulerView.backgroundColor)")
                }

                codeRulerView.language = language // This was already here
                codeRulerView.needsDisplay = true    // This was already here
            }
        } else {
            nsView.hasVerticalRuler = false
            nsView.rulersVisible = false
        }
        
        // Update text if it has changed
        if let textStorage = textView.textStorage {
            let currentText = textStorage.string
            let newText = attributedText.string
            
            // Check if we need to update
            if currentText != newText || textStorage.length != attributedText.length {
                print("TYPING_DEBUG: 🔄 CustomTextView.updateNSView - Text content is being updated. currentText.count: \(currentText.count), newText.count: \(newText.count), textStorage.length: \(textStorage.length), attributedText.length: \(attributedText.length)")
                // Store the current selection
                let selectedRange = textView.selectedRange()
                
                // Update text storage
                textStorage.beginEditing()
                
                // If attributed text is empty but we have plain text, create attributed version
                if attributedText.length == 0 && !text.isEmpty {
                    let attrs = context.coordinator.defaultAttributes()
                    let attrString = NSAttributedString(string: text, attributes: attrs)
                    textStorage.setAttributedString(attrString)
                } else {
                    textStorage.setAttributedString(attributedText)
                }
                
                textStorage.endEditing()
                
                // Restore selection safely
                let maxLength = textStorage.length
                if selectedRange.location >= 0 && selectedRange.location <= maxLength {
                    let validLength = min(selectedRange.length, maxLength - selectedRange.location)
                    let safeRange = NSRange(location: selectedRange.location, length: max(0, validLength))
                    textView.setSelectedRange(safeRange)
                }
            }
        }
        
        // Ensure text view remains editable
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // Update cursor color for visibility
        textView.insertionPointColor = appTheme.editorTextColor()
        
        // CRITICAL FIX: Safe responder management - Removed redundant makeFirstResponder call from updateNSView.
        // The initial makeFirstResponder in makeNSView (async) should be the primary mechanism.
        // If focus is lost later, it's often due to other UI interactions or window lifecycle events
        // that should ideally be handled by the system or specific event handlers, not generically in updateNSView.
    }
    
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        print("TYPING_DEBUG: 🗑️ CustomTextView.dismantleNSView - Called")
        // CRITICAL FIX: Simplify responder handling
        coordinator.isBeingRemoved = true
        
        // Clean up delegate
        if let textView = nsView.documentView as? NSTextView {
            textView.delegate = nil
            
            // Remove bounds observer
            if let scrollView = textView.enclosingScrollView, let clipView = scrollView.contentView as? NSClipView {
                NotificationCenter.default.removeObserver(coordinator, name: NSView.boundsDidChangeNotification, object: clipView)
            }

            // Let AppKit handle responder transitions naturally
            // DO NOT call resignFirstResponder() directly
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, appState: appState) // Pass appState to Coordinator
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextView
        let appState: AppState // Store AppState
        weak var textView: NSTextView? // Weak reference to the text view
        private var isUpdating = false
        private var lastText = ""
        var isBeingRemoved = false // Track if view is being dismantled
        @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
        var foldableRegions: [FoldableRegion] = []

        // MARK: - Auto-Completion Properties
        let autoCompletionManager: AutoCompletionManager
        var completionSuggestions: [CompletionSuggestion] = []
        var selectedSuggestionId: UUID? = nil
        var isCompletionViewPresented: Bool = false
        var completionViewHostingController: NSHostingController<CompletionListView>?
        private var textChangeDebounceCancellable: AnyCancellable?
        private var lastCursorPositionForCompletion: Int = 0
        
        init(_ parent: CustomTextView, appState: AppState) { // Modified init
            self.parent = parent
            self.appState = appState // Store appState
            // Initialize AutoCompletionManager
            self.autoCompletionManager = AutoCompletionManager(providers: [
                KeywordCompletionProvider(),
                DocumentWordCompletionProvider()
            ])
            super.init()
            print("TYPING_DEBUG: 🔧 Coordinator.init - Created coordinator for document \(parent.document.id)")
            
            // Observe jump to line notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleJumpToLine(_:)),
                name: .jumpToLine,
                object: nil
            )

            // Observe minimap navigation clicks
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleMinimapNavigation(_:)),
                name: .minimapNavigateToRatio,
                object: nil
            )
        }
        
        deinit {
            print("TYPING_DEBUG: 🗑️ Coordinator.deinit - Coordinator is being deallocated")
            NotificationCenter.default.removeObserver(self)
        }
        
        func defaultAttributes() -> [NSAttributedString.Key: Any] {
            let theme = parent.appTheme
            return [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: theme.editorTextColor()
            ]
        }
        
        func updateTheme(_ textView: NSTextView) {
            let theme = parent.appTheme
            let foreground = theme.editorTextColor()
            let background = theme.editorBackgroundColor()
            print("TYPING_DEBUG: 🎨 Coordinator.updateTheme - Applying foreground: \(foreground), background: \(background)")

            // Explicitly check if text and background colors are too similar
            if foreground.isApproximatelyEqual(to: background) {
                print("TYPING_DEBUG: WARNING Coordinator.updateTheme - Text color and background color are very similar or identical. Text may be invisible. Foreground: \(foreground), Background: \(background)")
            }
            
            // Update background color
            textView.backgroundColor = background
            
            // Update typing attributes
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = foreground
            // attrs[.backgroundColor] = background // Removed: Let textView.backgroundColor handle background
            attrs[.font] = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular) // Consistent monospaced font
            textView.typingAttributes = attrs
            
            // Update existing text colors if needed
            if let textStorage = textView.textStorage {
                let range = NSRange(location: 0, length: textStorage.length)
                textStorage.addAttribute(.foregroundColor, value: theme.editorTextColor(), range: range)
                // Also ensure font is set
                if textStorage.length > 0 && textStorage.attribute(.font, at: 0, effectiveRange: nil) == nil {
                    textStorage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular), range: range) // Consistent monospaced font
                }
            }
        }
        
        func textDidChange(_ notification: Notification) {
            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Called. isUpdating: \(isUpdating)")

            // Auto-completion logic
            if let textView = notification.object as? ColumnarNSTextView { // Ensure it's our type
                // Debounce text changes for auto-completion
                // Cancel any previous debounce subscription
                textChangeDebounceCancellable?.cancel()
                textChangeDebounceCancellable = Just(textView.string) // Use Just to create a publisher
                    .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // 300ms debounce
                    .sink { [weak self] currentTextContent in
                        self?.triggerAutoCompletion(for: textView, textContent: currentTextContent)
                        // If text changed, clear column selection (new system)
                        // This ensures that programmatic text changes or normal typing
                        // while a column selection highlight might be visible, clears that visual state.
                        textView.clearColumnSelection()
                    }
            }

            guard let textView = notification.object as? ColumnarNSTextView else { // Ensure it's our type
                print("TYPING_DEBUG: ❌ Coordinator.textDidChange - Not a ColumnarNSTextView")
                return
            }
            guard !isUpdating else {
                print("TYPING_DEBUG: ⚠️ Coordinator.textDidChange - Blocked: isUpdating = true")
                return
            }
            guard !isBeingRemoved else {
                print("TYPING_DEBUG: ⚠️ Coordinator.textDidChange - Blocked: isBeingRemoved = true")
                return
            }
            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Current text from NSTextView: \(textView.string.prefix(50))...")
            
            let currentText = textView.string
            
            // Only update if text actually changed
            if currentText != lastText {
                lastText = currentText
                
                // Set flag to prevent circular updates
                isUpdating = true
                defer { 
                    isUpdating = false
                    print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Reset isUpdating to false")
                }
                print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Set isUpdating to true")
                
                do {
                    // Update foldable regions
                    updateFoldableRegions(for: currentText)
                    
                    // Update line numbers and ruler view
                    if let scrollView = textView.enclosingScrollView,
                       let rulerView = scrollView.verticalRulerView {
                        rulerView.needsDisplay = true
                    }
                    
                    // Update text binding synchronously to avoid state modification during view updates
                    if parent.text != currentText {
                        parent.text = currentText
                        print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Updated parent.text")
                    } else {
                        print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - parent.text was already up-to-date")
                    }
                    
                    // Update attributed text synchronously
                    if let textStorage = textView.textStorage {
                        let attributedString = textStorage.copy() as! NSAttributedString
                        if !attributedString.isEqual(to: parent.attributedText) {
                            parent.attributedText = attributedString
                            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - Updated parent.attributedText")
                        } else {
                            print("TYPING_DEBUG: ✏️ Coordinator.textDidChange - parent.attributedText was already up-to-date")
                        }
                    }
                    
                    // Update bracket highlighting after a short delay to allow syntax highlighting to complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                        self?.updateBracketHighlighting(in: textView)
                    }
                } catch {
                    print("TYPING_DEBUG: ERROR Coordinator.textDidChange - Error during text processing: \(error)")
                }
            }
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? "nil"
            print("TYPING_DEBUG: 🎹 Coordinator.shouldChangeTextIn - Range: \(affectedCharRange), Replacement: '\(replacement)', Length: \(replacement.count)")
            
            // Log current state
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Current state: isUpdating = \(isUpdating), isBeingRemoved = \(isBeingRemoved)")
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - TextView state: isEditable = \(textView.isEditable), window = \(textView.window != nil)")
            if let window = textView.window {
                print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Window: isKey = \(window.isKeyWindow), isVisible = \(window.isVisible), firstResponder = \(String(describing: window.firstResponder))")
            }
            print("TYPING_DEBUG:    📊 Coordinator.shouldChangeTextIn - Is TextView first responder: \(textView.window?.firstResponder == textView)")
            
            // Prevent changes during updates or when being removed
            guard !isUpdating && !isBeingRemoved else {
                print("TYPING_DEBUG:    ❌ Coordinator.shouldChangeTextIn - BLOCKED: isUpdating=\(isUpdating), isBeingRemoved=\(isBeingRemoved). Returning false.")
                return false
            }

            // Columnar input is now handled by ColumnarNSTextView.insertText.
            // The old logic for `self.currentColumnSelections` is removed here.
            
            // Handle smart indentation for newlines
            if let replacement = replacementString, replacement == "\n" {
                // Use smart indenter to handle newline with proper indentation
                let handled = SmartIndenter.handleNewlineIndentation(
                    in: textView,
                    language: parent.language
                )
                
                if handled {
                    return false // We handled the insertion ourselves
                }
            }
            
            print("TYPING_DEBUG:    ✅ Coordinator.shouldChangeTextIn - ALLOWING text change. Returning true.")
            return true
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  !isUpdating else { return }
            
            let newRange = textView.selectedRange()
            
            // Only post if selection actually changed
            if selectedRange != newRange {
                selectedRange = newRange
                
                // Hide completion view if selection changes significantly
                if isCompletionViewPresented {
                    // More sophisticated logic might be needed, e.g., if selection is just moving within a word being completed
                    hideCompletionView()
                }

                // Update bracket highlighting
                updateBracketHighlighting(in: textView)
                
                // Debounce selection notifications to avoid excessive updates
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(postSelectionChange), object: nil)
                perform(#selector(postSelectionChange), with: nil, afterDelay: 0.1)
            }
        }
        
        @objc private func postSelectionChange() {
            NotificationCenter.default.post(
                name: .textViewSelectionDidChange,
                object: nil,
                userInfo: ["selectedRange": selectedRange]
            )
        }
        
        @objc private func handleJumpToLine(_ notification: Notification) {
            print("TYPING_DEBUG:  JUMP_TO_LINE Coordinator.handleJumpToLine - Received notification: \(notification)")
            guard let lineNumber = notification.userInfo?["lineNumber"] as? Int,
                  let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Guard failed. LineNumber: \(String(describing: notification.userInfo?["lineNumber"])), TextView: \(String(describing: NSApp.keyWindow?.firstResponder))")
                return
            }
            
            // Check if this coordinator's parent view is the one that should handle this.
            // This is a simple check; more robust might involve passing a document ID.
            guard parent.document.id == (textView.delegate as? Coordinator)?.parent.document.id else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Notification is for a different document. Skipping.")
                return
            }
            
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Attempting to jump to line: \(lineNumber) in textView: \(textView)")
            
            let text = textView.string
            let lines = text.components(separatedBy: .newlines)
            
            guard lineNumber > 0 && lineNumber <= lines.count else {
                print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Invalid line number: \(lineNumber). Total lines: \(lines.count)")
                return
            }
            
            // Calculate character position for the line
            let lineIndex = lineNumber - 1
            var charPosition = 0
            
            for i in 0..<lineIndex {
                charPosition += lines[i].count + 1 // +1 for newline
            }
            
            // Create range for the line
            let lineLength = lines[lineIndex].count
            let lineRange = NSRange(location: charPosition, length: lineLength)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Calculated charPosition: \(charPosition), lineLength: \(lineLength), lineRange: \(lineRange)")
            
            // Scroll to and select the line
            textView.scrollRangeToVisible(lineRange)
            textView.setSelectedRange(lineRange)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Scrolled and set selection to range: \(lineRange)")
            
            // Make sure text view is first responder
            let responderSuccess = textView.window?.makeFirstResponder(textView)
            print("TYPING_DEBUG: JUMP_TO_LINE Coordinator.handleJumpToLine - Made textView first responder. Success: \(responderSuccess ?? false)")
        }
        
        // MARK: - Code Folding Methods
        
        func updateFoldableRegions(for text: String) {
            let folder = CodeFolder(language: parent.language)
            foldableRegions = folder.detectFoldableRegions(in: text)
        }
        
        private func getCurrentDocument() -> Document? {
            // Try to get the current document from AppState
            if let _ = NSApp.delegate as? AppDelegate,
               let mainWindow = NSApp.mainWindow,
               let contentView = mainWindow.contentView,
               let _ = contentView.subviews.first(where: { $0 is NSHostingView<AnyView> }) as? NSHostingView<AnyView> {
                // This is a simplified approach - in practice, you might need a different way to access AppState
                // For now, we'll work with the text binding directly
                return nil
            }
            return nil
        }
        
        func toggleFold(for region: FoldableRegion) {
            parent.document.toggleFold(for: region)
            
            // Update the ruler view
            if let textView = NSApp.keyWindow?.firstResponder as? NSTextView,
               let scrollView = textView.enclosingScrollView,
               let rulerView = scrollView.verticalRulerView as? CodeFoldingRulerView {
                rulerView.needsDisplay = true
            }
        }
        
        func isFolded(_ region: FoldableRegion) -> Bool {
            return parent.document.isFolded(region)
        }
        
        // MARK: - Bracket Matching
        
        private func updateBracketHighlighting(in textView: NSTextView) {
            // Get the current theme for bracket highlighting
            let syntaxTheme = parent.appTheme.syntaxTheme()
            
            // Apply bracket highlighting
            BracketMatcher.highlightBrackets(in: textView, theme: syntaxTheme)
        }

        // MARK: - Auto-Completion Methods

        func triggerAutoCompletion(for textView: NSTextView, textContent: String) {
            guard let textStorage = textView.textStorage else { return }
            let cursorPosition = textView.selectedRange().location
            self.lastCursorPositionForCompletion = cursorPosition

            // Basic current word extraction (can be improved)
            let textUpToCursor = (textContent as NSString).substring(to: cursorPosition)
            let currentWord = textUpToCursor.components(separatedBy: .whitespacesAndNewlines).last ?? ""

            // Placeholder for language identifier - should come from document or app state
            let languageIdentifier = parent.language.rawValue.lowercased() // e.g., "swift"

            let context = CompletionContext(
                currentText: textContent,
                cursorPosition: cursorPosition,
                languageIdentifier: languageIdentifier,
                currentWord: currentWord
            )

            let newSuggestions = autoCompletionManager.fetchSuggestions(context: context)

            if !newSuggestions.isEmpty {
                completionSuggestions = newSuggestions
                selectedSuggestionId = newSuggestions.first?.id
                showCompletionView(at: textView)
            } else {
                hideCompletionView()
            }
        }

        func showCompletionView(at textView: NSTextView) {
            guard !completionSuggestions.isEmpty else {
                hideCompletionView()
                return
            }

            if completionViewHostingController == nil {
                let completionListView = CompletionListView(
                    suggestions: completionSuggestions,
                    selectedSuggestionId: Binding(
                        get: { self.selectedSuggestionId },
                        set: { self.selectedSuggestionId = $0 }
                    ),
                    onSuggestionTap: { suggestion in
                        self.insertSuggestion(suggestion, in: textView)
                        self.hideCompletionView()
                    }
                )
                completionViewHostingController = NSHostingController(rootView: completionListView)
            } else {
                // Update suggestions if view already exists
                completionViewHostingController?.rootView.suggestions = completionSuggestions
                completionViewHostingController?.rootView.selectedSuggestionId = completionSuggestions.first?.id
            }

            guard let controller = completionViewHostingController else { return }

            // Positioning logic (basic version)
            let cursorRect: NSRect
            if let layoutManager = textView.layoutManager, let textContainer = textView.textContainer {
                 let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: lastCursorPositionForCompletion, length: 0), actualCharacterRange: nil)
                 cursorRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            } else {
                cursorRect = NSRect(x: 50, y: 50, width: 1, height: 1) // Fallback
            }

            // Convert cursorRect origin from textContainer coordinates to textView (view) coordinates.
            let viewCursorOrigin = textView.convert(cursorRect.origin, from: nil) // from: nil assumes textContainer origin is (0,0) relative to textView
                                                                                // More correctly: textView.convert(cursorRect.origin, from: textView.textContainer) if textContainer had its own origin.
                                                                                // However, for NSTextView, textContainer is usually at (0,0) of its bounds.

            let viewFrame = CGRect(
                x: viewCursorOrigin.x + textView.textContainerOrigin.x, // Add textContainerOrigin for correct placement
                y: viewCursorOrigin.y + textView.textContainerOrigin.y + 20, // Position below cursor line
                width: 250, // Fixed width for now
                height: 200 // Max height, will be adjusted by ScrollView
            )
            controller.view.frame = viewFrame

            if controller.view.superview == nil {
                textView.addSubview(controller.view)
            }
            isCompletionViewPresented = true
        }

        func hideCompletionView() {
            completionViewHostingController?.view.removeFromSuperview()
            completionViewHostingController = nil // Release controller
            isCompletionViewPresented = false
            completionSuggestions = []
            selectedSuggestionId = nil
        }

        func insertSuggestion(_ suggestion: CompletionSuggestion, in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }

            let currentWordStart = (textView.string as NSString).range(
                of: "\\S+$",
                options: .regularExpression,
                range: NSRange(location: 0, length: lastCursorPositionForCompletion)
            ).location

            let rangeToReplace: NSRange
            if currentWordStart != NSNotFound && currentWordStart < lastCursorPositionForCompletion {
                 rangeToReplace = NSRange(location: currentWordStart, length: lastCursorPositionForCompletion - currentWordStart)
            } else {
                // If no current word (e.g. after a space), insert at cursor
                rangeToReplace = NSRange(location: lastCursorPositionForCompletion, length: 0)
            }


            if textView.shouldChangeText(in: rangeToReplace, replacementString: suggestion.insertionText) {
                textStorage.replaceCharacters(in: rangeToReplace, with: suggestion.insertionText)
                textView.didChangeText() // Manually call if not automatically triggered by replaceCharacters

                // Update cursor position after insertion
                let newCursorPosition = rangeToReplace.location + (suggestion.insertionText as NSString).length
                textView.setSelectedRange(NSRange(location: newCursorPosition, length: 0))
            }
        }

        func navigateCompletionList(direction: Int) { // 1 for down, -1 for up
            guard !completionSuggestions.isEmpty, let currentIndex = completionSuggestions.firstIndex(where: { $0.id == selectedSuggestionId }) else {
                selectedSuggestionId = completionSuggestions.first?.id
                return
            }
            var newIndex = currentIndex + direction
            if newIndex < 0 { newIndex = completionSuggestions.count - 1 }
            if newIndex >= completionSuggestions.count { newIndex = 0 }
            selectedSuggestionId = completionSuggestions[newIndex].id

            // Ensure the hosting controller's view gets updated with the new selection
            completionViewHostingController?.rootView.selectedSuggestionId = selectedSuggestionId
        }

        func confirmCurrentSuggestion(in textView: NSTextView) {
            if let selectedId = selectedSuggestionId, let suggestion = completionSuggestions.first(where: { $0.id == selectedId }) {
                insertSuggestion(suggestion, in: textView)
            }
            hideCompletionView()
        }


        // MARK: - Scroll Handling and Minimap Navigation

        func setupBoundsObserver(for clipView: NSClipView) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleBoundsChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: clipView // Observe the specific clipView
            )
        }

        @objc func handleBoundsChange(_ notification: Notification) {
            guard let clipView = notification.object as? NSClipView,
                  let textView = clipView.documentView as? NSTextView else {
                return
            }
            // Ensure it's for the correct text view instance this coordinator manages
            guard textView === self.textView else { return }

            postVisibleRectUpdate(for: textView)
        }

        @objc func handleMinimapNavigation(_ notification: Notification) {
            guard let clickYRatio = notification.object as? CGFloat,
                  let textView = self.textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                print("TYPING_DEBUG: MINIMAP_NAV - Guard failed. clickYRatio: \(String(describing: notification.object)), textView: \(String(describing: self.textView))")
                return
            }

            // Document ID check: Ensure this navigation is for the document this coordinator is managing.
            // This check is important if notifications are not instance-specific.
            // Here, we assume that if this coordinator's textView is active, it's the target.
            // A more robust way would be to pass document ID in the notification and check it here.
            // For now, direct handling is okay as CustomTextView instances are distinct.

            let totalContentHeight = layoutManager.usedRect(for: textContainer).height
            guard totalContentHeight > 0 else {
                print("TYPING_DEBUG: MINIMAP_NAV - Total content height is 0.")
                return
            }

            let targetY = totalContentHeight * clickYRatio
            // Ensure targetY is within bounds [0, totalContentHeight - visibleRect.height (or 1 if too small)]
            // For simplicity, we scroll to a point, ensuring it's not beyond the very end.
            let clampedTargetY = min(targetY, max(0, totalContentHeight - textView.visibleRect.height > 0 ? totalContentHeight - textView.visibleRect.height : 1))
            let targetRect = CGRect(x: 0, y: clampedTargetY, width: 1, height: 1)

            print("TYPING_DEBUG: MINIMAP_NAV - Navigating to ratio: \(clickYRatio), targetY: \(targetY), clampedTargetY: \(clampedTargetY), totalHeight: \(totalContentHeight)")
            textView.scrollToVisible(targetRect)

            // Manually trigger visible rect update after scrolling, as bounds change might be async
            DispatchQueue.main.async {
                 self.postVisibleRectUpdate(for: textView)
            }
        }

        func postVisibleRectUpdate(for textView: NSTextView) {
            let visibleRect = textView.visibleRect
            // Ensure document ID is available and correct
            // parent.document.id should be accessible here
            NotificationCenter.default.post(
                name: .customTextViewDidScroll,
                object: nil, // Or pass `textView` if specific sender is needed by observers
                userInfo: ["visibleRect": visibleRect, "documentId": parent.document.id]
            )
            print("TYPING_DEBUG: SCROLL_UPDATE - Posted .customTextViewDidScroll with rect: \(visibleRect), docID: \(parent.document.id)")
=======
        // MARK: - Context Menu Customization
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // It's usually better to augment the default menu rather than creating a new one from scratch.
            // However, the exact method to get the "super" menu in this delegate context can be tricky.
            // For this implementation, we'll add to the provided menu or create a new one if nil.
            // A more robust approach might involve `textView.menu` directly if appropriate.

            let augmentedMenu = menu // Use the menu passed by the system.
            var currentInsertIndex = 0

            // "Explain This Code" menu item
            let explainMenuItem = NSMenuItem(
                title: "Explain This Code",
                action: #selector(explainSelectedCodeAction(_:)),
                keyEquivalent: ""
            )
            explainMenuItem.target = self
            explainMenuItem.representedObject = textView
            explainMenuItem.isEnabled = textView.selectedRange().length > 0

            augmentedMenu.insertItem(explainMenuItem, at: currentInsertIndex)
            currentInsertIndex += 1

            // "Generate Docstring" menu item
            let docstringMenuItem = NSMenuItem(
                title: "Generate Docstring",
                action: #selector(generateDocstringAction(_:)),
                keyEquivalent: ""
            )
            docstringMenuItem.target = self
            docstringMenuItem.representedObject = textView
            docstringMenuItem.isEnabled = textView.selectedRange().length > 0

            augmentedMenu.insertItem(docstringMenuItem, at: currentInsertIndex)
            currentInsertIndex += 1

            // Add a separator before these custom items if menu is not empty,
            // or ensure it's at a logical place if augmenting a standard menu.
            if currentInsertIndex > 0 && !augmentedMenu.items.isEmpty && augmentedMenu.items.first?.isSeparatorItem == false {
                 // Check if the very first item (after our insertions) is not a separator.
                 // This logic might need adjustment based on where system items are.
                 // A simpler approach: always add separator at index 0 IF we added items.
            }
             augmentedMenu.insertItem(NSMenuItem.separator(), at: 0)


            return augmentedMenu
        }

        @objc func explainSelectedCodeAction(_ sender: Any?) {
            guard let textView = self.textView, textView.selectedRange().length > 0 else {
                print("Explain Code: No text selected or textView not available.")
                return
            }

            let selectedText = (textView.string as NSString).substring(with: textView.selectedRange())
            let prompt = "Explain the following code snippet:\n\n\(selectedText)"

            let previewLength = 50 // Show a short preview of the code being explained
            let codePreview = String(selectedText.prefix(previewLength)) + (selectedText.count > previewLength ? "..." : "")
            let contextMsg = "Explaining code snippet: \n`\(codePreview)`"

            print("Explain Code: Submitting prompt for selected text (length: \(selectedText.count))")
            self.appState.aiManager.submitPrompt(prompt: prompt, contextMessage: contextMsg) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let explanation):
                    print("Explain Code: Successfully received explanation (length: \(explanation.count)).")
                case .failure(let error):
                    print("Explain Code: Error receiving explanation: \(error.localizedDescription)")
                }
                // Ensure panel is shown if not already, AIManager handles content.
                DispatchQueue.main.async {
                    self.appState.showAIAssistantPanel = true
                }
            }
            // Show panel immediately after starting the request.
            self.appState.showAIAssistantPanel = true
            print("Explain Code: Requested to show AI Assistant Panel.")
        }

        @objc func generateDocstringAction(_ sender: Any?) {
            guard let textView = self.textView, textView.selectedRange().length > 0 else {
                print("Generate Docstring: No text selected or textView not available.")
                return
            }

            let selectedText = (textView.string as NSString).substring(with: textView.selectedRange())
            let languageName = parent.language.rawValue // Assuming language has a rawValue string like "Swift", "Python"
            let prompt = "Generate a well-formatted docstring for the following \(languageName) code snippet. Ensure the docstring is suitable for direct insertion above the code in a source file. For Swift, use '///' comments. For Python, use triple quotes. For other languages like JavaScript, C++, Java, use JSDoc/Doxygen/Javadoc style comments respectively. If language is 'none' or unknown, use a generic block comment (e.g., /* ... */).\n\nCode:\n\(selectedText)"

            print("Generate Docstring: Submitting prompt for selected text (length: \(selectedText.count))")
            self.appState.aiManager.submitPrompt(prompt: prompt, contextMessage: nil) { [weak self] result in
                guard let self = self, let textView = self.textView else { return }

                switch result {
                case .success(let aiResponse):
                    print("Generate Docstring: Successfully received AI response.")
                    let generatedDocstring = aiResponse.content

                    let selectedRange = textView.selectedRange()
                    let (currentLineRange, currentLineIndentation) = self.getLineInfo(for: selectedRange.location, in: textView)
                    let indentedDocstring = self.indentDocstring(generatedDocstring, with: currentLineIndentation)
                    let finalDocstring = indentedDocstring + "\n"

                    // Perform Text Insertion
                    if textView.shouldChangeText(in: NSRange(location: currentLineRange.location, length: 0), replacementString: finalDocstring) {
                        textView.textStorage?.insert(NSAttributedString(string: finalDocstring, attributes: self.defaultAttributes()), at: currentLineRange.location)
                        textView.didChangeText() // Notifies delegate about the change
                        print("Generate Docstring: Inserted docstring at location \(currentLineRange.location).")
                    } else {
                        print("Generate Docstring: Failed to insert docstring - shouldChangeTextIn returned false.")
                        self.appState.aiManager.latestResponseContent = "Error: Could not insert generated docstring."
                        self.appState.showAIAssistantPanel = true
                    }

                case .failure(let error):
                    print("Generate Docstring: Error receiving explanation: \(error.localizedDescription)")
                    self.appState.aiManager.latestResponseContent = "Error generating docstring: \(error.localizedDescription)"
                    self.appState.showAIAssistantPanel = true
                }
            }
        }

        // Helper methods for docstring generation
        private func getLineInfo(for characterIndex: Int, in textView: NSTextView) -> (lineRange: NSRange, indentation: String) {
            let fullText = textView.string as NSString
            let lineRange = fullText.lineRange(for: NSRange(location: characterIndex, length: 0))
            let lineText = fullText.substring(with: lineRange)

            var indentation = ""
            for char in lineText {
                if char.isWhitespace && char != "\n" && char != "\r" { // Check for actual whitespace characters
                    indentation.append(char)
                } else {
                    break
                }
            }
            return (lineRange, indentation)
        }

        private func indentDocstring(_ docstring: String, with indentation: String) -> String {
            // If the docstring already seems to have its own consistent indentation (common for LLM outputs for block comments),
            // and our target indentation is empty, we might not want to add extra spaces to every line.
            // However, for typical cases where we want to align it with the code block, prepending is correct.

            let lines = docstring.components(separatedBy: "\n")
            // Only add indentation if it's not empty. Avoids adding empty strings to lines if original indent is empty.
            if indentation.isEmpty {
                return docstring
            }
            return lines.map { indentation + $0 }.joined(separator: "\n")
>>>>>>> feature/terminal-enhancements
        }
    }
}

// Preview for Xcode development
#Preview {
    struct PreviewWrapper: View {
        @StateObject var appState = AppState() // Use @StateObject for AppState in Preview
        @State private var text = "Sample text for preview"
        @State private var attributedText = NSAttributedString(string: "Sample text for preview", attributes: [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor
        ])
        
        var body: some View {
            let document = Document()
            document.language = .swift
            // Ensure AppState is also passed to CustomTextView in the preview
            return CustomTextView(
                text: $text, 
                attributedText: $attributedText, 
                appTheme: .system, 
                showLineNumbers: true, 
                language: .swift,
                document: document,
                appState: appState // Pass the appState instance
            )
            .environmentObject(appState) // Also provide it in environment if needed by sub-views not directly passed.
            .frame(width: 400, height: 300)
        }
    }
    
    return PreviewWrapper()
}

// Code Folding Ruler View for displaying line numbers and fold controls
class CodeFoldingRulerView: NSRulerView {
    var font: NSFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    var textColor: NSColor = NSColor.secondaryLabelColor
    var backgroundColor: NSColor = NSColor.controlBackgroundColor
    var language: SyntaxHighlighter.Language = .none
    weak var coordinator: CustomTextView.Coordinator?
    
    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation: orientation)
        self.clientView = scrollView?.documentView
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        // Fill background
        backgroundColor.set()
        rect.fill()
        
        guard let textView = self.clientView as? NSTextView,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let coordinator = coordinator else { return }
        
        let contentRect = convert(textView.visibleRect, from: textView)
        let textVisibleRect = textView.visibleRect
        
        // Find the character range for the visible text
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Get the text
        let text = textView.string as NSString
        
        // Set up line number attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        // Calculate line numbers
        var lineNumber = 0
        
        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        // Create a dictionary to quickly lookup foldable regions by start line
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        // Draw line numbers and fold controls for visible range
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, _ in
            lineNumber += 1
            
            // Get the line rect
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            
            // Calculate y position
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
            
            // Draw line number
            let lineNumberString = "\(lineNumber)"
            let size = lineNumberString.size(withAttributes: attributes)
            let lineNumberPoint = NSPoint(x: self.ruleThickness - size.width - 5, y: y)
            
            lineNumberString.draw(at: lineNumberPoint, withAttributes: attributes)
            
            // Draw fold control if this line starts a foldable region
            if let region = regionsByStartLine[lineNumber] {
                self.drawFoldControl(for: region, at: NSPoint(x: 5, y: y), coordinator: coordinator)
            }
        }
    }
    
    private func drawFoldControl(for region: FoldableRegion, at point: NSPoint, coordinator: CustomTextView.Coordinator) {
        let isFolded = coordinator.isFolded(region)
        let controlSize: CGFloat = 12
        let controlRect = NSRect(x: point.x, y: point.y + 2, width: controlSize, height: controlSize)
        
        // Draw background
        NSColor.controlBackgroundColor.set()
        controlRect.fill()
        
        // Draw border
        textColor.withAlphaComponent(0.3).set()
        controlRect.frame()
        
        // Draw plus or minus sign
        let signColor = textColor.withAlphaComponent(0.7)
        let lineWidth: CGFloat = 1.5
        
        // Horizontal line (always present for minus sign, or part of plus)
        let horizontalPath = NSBezierPath()
        horizontalPath.lineWidth = lineWidth
        let centerY = controlRect.midY
        let leftX = controlRect.minX + 3
        let rightX = controlRect.maxX - 3
        
        horizontalPath.move(to: NSPoint(x: leftX, y: centerY))
        horizontalPath.line(to: NSPoint(x: rightX, y: centerY))
        signColor.set()
        horizontalPath.stroke()
        
        // Vertical line (only for folded regions - plus sign)
        if isFolded {
            let verticalPath = NSBezierPath()
            verticalPath.lineWidth = lineWidth
            let centerX = controlRect.midX
            let topY = controlRect.maxY - 3
            let bottomY = controlRect.minY + 3
            
            verticalPath.move(to: NSPoint(x: centerX, y: bottomY))
            verticalPath.line(to: NSPoint(x: centerX, y: topY))
            verticalPath.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        guard let coordinator = coordinator else {
            super.mouseDown(with: event)
            return
        }
        
        // Check if click is on a fold control
        if let region = foldableRegionAt(point: point) {
            coordinator.toggleFold(for: region)
            needsDisplay = true
        } else {
            super.mouseDown(with: event)
        }
    }
    
    private func foldableRegionAt(point: NSPoint) -> FoldableRegion? {
        guard let textView = self.clientView as? NSTextView,
              let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let coordinator = coordinator else { return nil }
        
        let contentRect = convert(textView.visibleRect, from: textView)
        let textVisibleRect = textView.visibleRect
        
        // Find the character range for the visible text
        let glyphRange = layoutManager.glyphRange(forBoundingRect: textVisibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Get the text
        let text = textView.string as NSString
        
        // Calculate line numbers
        var lineNumber = 0
        
        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location),
                                options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }
        
        // Create a dictionary to quickly lookup foldable regions by start line
        var regionsByStartLine: [Int: FoldableRegion] = [:]
        for region in coordinator.foldableRegions {
            regionsByStartLine[region.startLine] = region
        }
        
        // Check each visible line to see if click is on a fold control
        var foundRegion: FoldableRegion?
        text.enumerateSubstrings(in: characterRange,
                                options: [.byLines, .substringNotRequired]) { _, lineRange, _, stop in
            lineNumber += 1
            
            // Get the line rect
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            
            // Calculate y position
            let y = lineRect.minY - textVisibleRect.minY + contentRect.minY
            
            // Check if this line has a foldable region and if click is within the control area
            if let region = regionsByStartLine[lineNumber] {
                let controlSize: CGFloat = 12
                let controlRect = NSRect(x: 5, y: y + 2, width: controlSize, height: controlSize)
                
                if controlRect.contains(point) {
                    foundRegion = region
                    stop.pointee = true
                }
            }
        }
        
        return foundRegion
    }
    
    override var requiredThickness: CGFloat {
        return 60.0  // Wider to accommodate fold controls
    }
}

// Extension to compare NSColor objects
// Placed here to be self-contained within the file for this exercise.
// In a larger project, this might go into a dedicated utility file.
extension NSColor {
    func isApproximatelyEqual(to color: NSColor, tolerance: CGFloat = 0.05) -> Bool {
        guard let srgbColorSpace = NSColorSpace.sRGB else {
            print("TYPING_DEBUG: NSColor.isApproximatelyEqual - Failed to get sRGB color space. Falling back to direct comparison.")
            // Fallback to direct comparison if sRGB space is unavailable
            return self == color 
        }

        // Attempt to convert both colors to the sRGB color space
        guard let c1 = self.usingColorSpace(srgbColorSpace), 
              let c2 = color.usingColorSpace(srgbColorSpace) else {
            print("TYPING_DEBUG: NSColor.isApproximatelyEqual - Failed to convert one or both colors to sRGB. Falling back to direct comparison.")
            // Fallback if conversion fails
            return self == color 
        }

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        // Get RGBA components
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        // Optional: Log the component values for debugging color comparison issues
        // print("TYPING_DEBUG: ColorComp C1: R\(String(format: "%.2f", r1)) G\(String(format: "%.2f", g1)) B\(String(format: "%.2f", b1)) | C2: R\(String(format: "%.2f", r2)) G\(String(format: "%.2f", g2)) B\(String(format: "%.2f", b2))")

        // Compare RGB components within the given tolerance
        // Alpha is not compared here as background is usually opaque and text visibility depends on RGB contrast.
        return abs(r1 - r2) < tolerance &&
               abs(g1 - g2) < tolerance &&
               abs(b1 - b2) < tolerance
    }
}
