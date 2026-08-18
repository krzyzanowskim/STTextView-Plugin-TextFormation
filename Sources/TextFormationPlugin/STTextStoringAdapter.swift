#if os(macOS)
    import AppKit
#elseif os(iOS) || targetEnvironment(macCatalyst)
    import UIKit
#endif
import Foundation
import STTextView
import TextFormation
import TextStory

@MainActor
final class STTextStoringAdapter: @preconcurrency TextStoring {
    private weak var textView: STTextView?
    private var didApplyMutation = false
    private var isUndoGrouping = false

    var length: Int {
        (textView?.contentStorage as? NSTextContentManager)?.length ?? 0
    }

    init(textView: STTextView) {
        self.textView = textView
    }

    func substring(from range: NSRange) -> String? {
        textView?.contentStorage?.substring(from: range)
    }

    func startMutationSession() {
        didApplyMutation = false
        isUndoGrouping = false
    }

    func finishMutationSession() {
        guard isUndoGrouping else {
            return
        }

        textView?.undoManager?.endUndoGrouping()
        isUndoGrouping = false
    }

    func applyOriginalMutationIfNeeded(_ mutation: TextStory.TextMutation) -> Bool {
        guard didApplyMutation else {
            return true
        }

        applyMutation(mutation)
        return false
    }

    func applyMutation(_ mutation: TextStory.TextMutation) {
        guard let textView else {
            return
        }

        beginUndoGroupingIfNeeded(on: textView)
        didApplyMutation = true
        applyMutationRegisteringUndo(mutation, to: textView)
    }

    private func beginUndoGroupingIfNeeded(on textView: STTextView) {
        guard !isUndoGrouping else {
            return
        }

        textView.breakUndoCoalescing()
        textView.undoManager?.beginUndoGrouping()
        isUndoGrouping = true
    }

    private func applyMutationRegisteringUndo(_ mutation: TextStory.TextMutation, to textView: STTextView) {
        guard let contentStorage = textView.contentStorage else {
            return
        }

        let selectionBeforeMutation = textView.textSelection
        let inverse = contentStorage.inverseMutation(for: mutation)

        if let undoManager = textView.undoManager, undoManager.isUndoRegistrationEnabled {
            undoManager.registerUndo(withTarget: textView) { textView in
                self.applyMutationRegisteringUndo(inverse, to: textView)
                textView.textSelection = selectionBeforeMutation
            }
        }

        applyMutationWithoutRegisteringUndo(mutation, to: textView)
    }

    private func applyMutationWithoutRegisteringUndo(_ mutation: TextStory.TextMutation, to textView: STTextView) {
        guard let textRange = NSTextRange(mutation.range, in: textView.textContentManager) else {
            return
        }

        let selection = textView.textSelection
        let undoManager = textView.undoManager
        let shouldReenableUndoRegistration = undoManager?.isUndoRegistrationEnabled == true
        undoManager?.disableUndoRegistration()
        defer {
            if shouldReenableUndoRegistration {
                undoManager?.enableUndoRegistration()
            }
        }

        textView.replaceCharacters(in: textRange, with: mutation.string)
        textView.textSelection = selectionAfterApplying(mutation, to: selection, textLength: length)
    }

    private func selectionAfterApplying(_ mutation: TextStory.TextMutation, to selection: NSRange, textLength: Int) -> NSRange {
        guard selection.location != NSNotFound else {
            return selection
        }

        let insertedLength = mutation.string.utf16.count
        let delta = insertedLength - mutation.range.length
        let selectedRange = selection.location ..< selection.upperBound
        let editedRange = mutation.range.location ..< mutation.range.upperBound

        let adjusted: NSRange
        if selection.length == 0 {
            adjusted = insertionPointSelectionAfterApplying(mutation, insertedLength: insertedLength, delta: delta, to: selection)
        } else if mutation.range.length == 0 {
            adjusted = selectedRangeSelectionAfterInserting(at: mutation.range.location, delta: delta, to: selectedRange)
        } else if editedRange.upperBound <= selectedRange.lowerBound {
            adjusted = NSRange(location: selection.location + delta, length: selection.length)
        } else if editedRange.lowerBound >= selectedRange.upperBound {
            adjusted = selection
        } else {
            let lowerBound = min(selectedRange.lowerBound, editedRange.lowerBound)
            let upperBound = max(lowerBound, selectedRange.upperBound + delta)
            adjusted = NSRange(lowerBound ..< upperBound)
        }

        let clampedLocation = min(max(adjusted.location, 0), textLength)
        let clampedUpperBound = min(max(adjusted.upperBound, clampedLocation), textLength)
        return NSRange(clampedLocation ..< clampedUpperBound)
    }

    private func insertionPointSelectionAfterApplying(
        _ mutation: TextStory.TextMutation,
        insertedLength: Int,
        delta: Int,
        to selection: NSRange
    ) -> NSRange {
        if mutation.range.upperBound <= selection.location {
            return NSRange(location: selection.location + delta, length: 0)
        }

        if NSLocationInRange(selection.location, mutation.range) {
            return NSRange(location: mutation.range.location + insertedLength, length: 0)
        }

        return selection
    }

    private func selectedRangeSelectionAfterInserting(at location: Int, delta: Int, to selectedRange: Range<Int>) -> NSRange {
        if location <= selectedRange.lowerBound {
            return NSRange(location: selectedRange.lowerBound + delta, length: selectedRange.count)
        }

        if location < selectedRange.upperBound {
            return NSRange(location: selectedRange.lowerBound, length: selectedRange.count + delta)
        }

        return NSRange(selectedRange)
    }
}

private extension STTextView {
    var contentStorage: NSTextContentStorage? {
        textContentManager as? NSTextContentStorage
    }
}

public extension TextInterfaceAdapter {
    @MainActor
    convenience init(textView: STTextView) {
        self.init(
            getSelection: { textView.textSelection },
            setSelection: { textView.textSelection = $0 },
            storage: STTextStoringAdapter(textView: textView)
        )
    }
}
