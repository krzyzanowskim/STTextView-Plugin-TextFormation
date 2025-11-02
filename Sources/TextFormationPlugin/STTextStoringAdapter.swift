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
private final class STTextStoringAdapter: @preconcurrency TextStoring {
    private weak var textView: STTextView?

    var length: Int {
        (textView?.contentStorage as? NSTextContentManager)?.length ?? 0
    }

    init(textView: STTextView) {
        self.textView = textView
    }

    func substring(from range: NSRange) -> String? {
        textView?.contentStorage?.substring(from: range)
    }

    func applyMutation(_ mutation: TextStory.TextMutation) {
        guard let textView, let contentStorage = textView.contentStorage else {
            return
        }

        textView.insertText(mutation.string, replacementRange: mutation.range)
        textView.breakUndoCoalescing()

        if let undoManager = textView.undoManager, undoManager.isUndoRegistrationEnabled, !undoManager.isUndoing, !undoManager.isRedoing {
            let inverse = contentStorage.inverseMutation(for: mutation)

            undoManager.registerUndo(withTarget: textView) { textView in
                textView.replaceCharacters(in: inverse.postApplyRange, with: inverse.string)
            }
        }
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
