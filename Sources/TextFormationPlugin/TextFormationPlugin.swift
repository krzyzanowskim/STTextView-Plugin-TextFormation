#if os(macOS)
    import AppKit
#elseif os(iOS) || targetEnvironment(macCatalyst)
    import UIKit
#endif

import STTextView
import TextFormation
import TextStory

#if os(macOS)
    // this was just lifted from TextFormation, but perhaps there's a better way to share all this
    extension NSResponder {
        var undoActive: Bool {
            guard let manager = undoManager else { return false }

            return manager.isUndoing || manager.isRedoing
        }
    }
#endif

#if os(iOS) || targetEnvironment(macCatalyst)
    // this was just lifted from TextFormation, but perhaps there's a better way to share all this
    extension UIResponder {
        var undoActive: Bool {
            guard let manager = undoManager else { return false }
            return manager.isUndoing || manager.isRedoing
        }
    }
#endif

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
        private var isProcessing: Bool
        private let filters: [Filter]
        private let whitespaceProviders: WhitespaceProviders

        init(view: STTextView, filters: [Filter], whitespaceProviders: WhitespaceProviders) {
            self.textView = view
            self.filters = filters
            self.whitespaceProviders = whitespaceProviders
            self.adapter = TextInterfaceAdapter(textView: view)
            self.isProcessing = false
        }

        func shouldChangeText(in affectedRange: NSTextRange, replacementString: String?) -> Bool {
            guard !isProcessing, !textView.undoActive, let replacementString else { return true }

            isProcessing = true
            textView.undoManager?.beginUndoGrouping()
            defer {
                textView.undoManager?.endUndoGrouping()
                isProcessing = false
            }

            let contentManager = textView.textContentManager

            let range = NSRange(affectedRange, in: contentManager)
            let limit = NSRange(contentManager.documentRange, in: contentManager).upperBound

            let mutation = TextMutation(string: replacementString, range: range, limit: limit)
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
