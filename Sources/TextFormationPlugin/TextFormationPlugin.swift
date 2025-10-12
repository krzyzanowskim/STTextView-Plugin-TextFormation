// The Swift Programming Language
// https://docs.swift.org/swift-book

import AppKit

import STTextView
import TextFormation
import TextStory

// this was just lifted from TextFormation, but perhaps there's a better way to share all this
extension NSResponder {
	var undoActive: Bool {
		guard let manager = undoManager else { return false }

		return manager.isUndoing || manager.isRedoing
	}
}

public struct TextFormationPlugin: STPlugin {
	private let filters: [Filter]
	private let whitespaceProviders: WhitespaceProviders

	public init(filters: [Filter], whitespaceProviders: WhitespaceProviders) {
		self.filters = filters
		self.whitespaceProviders = whitespaceProviders
	}

	@MainActor
	public func setUp(context: any Context) {
		context.events.shouldChangeText { affectedRange, replacementString in
			context.coordinator.shouldChangeText(in: affectedRange, replacementString: replacementString)
		}
	}

	@MainActor
	public func makeCoordinator(context: CoordinatorContext) -> Coordinator {
		Coordinator(view: context.textView, filters: filters, whitespaceProviders: whitespaceProviders)
	}

	@MainActor
	public class Coordinator {
		private let adapter: TextInterfaceAdapter
		private let textView: STTextView
		let filters: [Filter]
		let whitespaceProviders: WhitespaceProviders

		init(view: STTextView, filters: [Filter], whitespaceProviders: WhitespaceProviders) {
			self.textView = view
			self.filters = filters
			self.whitespaceProviders = whitespaceProviders
			self.adapter = TextInterfaceAdapter(textView: view)
		}

		func shouldChangeText(in affectedRange: NSTextRange, replacementString: String?) -> Bool {
			guard let string = replacementString else { return true }

			if textView.undoActive {
				return true
			}

			let contentManager = textView.textContentManager

			let range = NSRange(affectedRange, in: contentManager)
			let limit = NSRange(contentManager.documentRange, in: contentManager).upperBound

			let mutation = TextMutation(string: string, range: range, limit: limit)

            textView.undoManager?.beginUndoGrouping()
            defer {
                textView.undoManager?.endUndoGrouping()
            }

			for filter in filters {
				switch filter.processMutation(mutation, in: adapter, with: whitespaceProviders) {
				case .none:
					break
				case .stop:
					return true
				case .discard:
					return false
				}
			}

			return true
		}
	}
}
