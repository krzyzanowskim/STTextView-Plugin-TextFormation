import AppKit
import Foundation

import STTextView
import TextFormation
import TextStory

@MainActor
private final class TextStoringAdapter: @preconcurrency TextStoring {
	weak var textView: STTextView?

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

		textView.textWillChange(textView)
        let changeTextRange = NSTextRange(mutation.range, in: contentStorage)!
        textView.textDelegate?.textView(textView, willChangeTextIn: changeTextRange, replacementString: mutation.string)

		contentStorage.performEditingTransaction {
			contentStorage.applyMutation(mutation)
		}

        textView.textDelegate?.textView(textView, didChangeTextIn: changeTextRange, replacementString: mutation.string)
		textView.didChangeText()

        textView.breakUndoCoalescing()

        if let undoManager = textView.undoManager, undoManager.isUndoRegistrationEnabled, !undoManager.isUndoing, undoManager.isRedoing {
            let inverse = contentStorage.inverseMutation(for: mutation)

            undoManager.registerUndo(withTarget: textView, handler: { textView in
                MainActor.assumeIsolated {
                    textView.replaceCharacters(in: inverse.range, with: inverse.string)
                }
            })
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
			storage: TextStoringAdapter(textView: textView)
		)
	}
}
