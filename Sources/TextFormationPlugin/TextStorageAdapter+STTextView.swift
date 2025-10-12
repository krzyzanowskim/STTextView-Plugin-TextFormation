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
		guard let textView else {
			return
		}

		if let manager = textView.undoManager, let contentStorage = textView.contentStorage {
			let inverse = contentStorage.inverseMutation(for: mutation)

			manager.registerUndo(withTarget: self) { _ in
                textView.replaceCharacters(in: inverse.range, with: inverse.string)
			}
		}

        textView.replaceCharacters(in: mutation.range, with: mutation.string)
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
