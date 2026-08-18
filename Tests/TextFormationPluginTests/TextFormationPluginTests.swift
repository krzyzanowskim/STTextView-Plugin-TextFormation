#if os(macOS)
    import STTextView
    import TextFormation
    @testable import TextFormationPlugin
    import XCTest

    private final class CountingDelegate: STTextViewDelegate {
        var shouldChangeCallCount = 0

        func textView(_: STTextView, shouldChangeTextIn _: NSTextRange, replacementString _: String?) -> Bool {
            shouldChangeCallCount += 1
            return true
        }
    }

    @MainActor
    final class TextFormationPluginTests: XCTestCase {
        private func makeCoordinator(for textView: STTextView) -> TextFormationPlugin.Coordinator {
            TextFormationPlugin.Coordinator(
                view: textView,
                filters: [StandardOpenPairFilter(open: "{", close: "}")],
                whitespaceProviders: .none
            )
        }

        func testSurroundSelectionPreservesSelectedContent() throws {
            let textView = STTextView()
            textView.text = "abc"
            textView.textSelection = NSRange(location: 0, length: 3)
            let coordinator = makeCoordinator(for: textView)

            let range = try XCTUnwrap(NSTextRange(NSRange(location: 0, length: 3), in: textView.textContentManager))
            let shouldApplyOriginalMutation = coordinator.shouldChangeText(in: range, replacementString: "{")

            XCTAssertFalse(shouldApplyOriginalMutation)
            XCTAssertEqual(textView.text, "{abc}")
            XCTAssertEqual(textView.textSelection, NSRange(location: 1, length: 3))
        }

        func testSurroundSelectionUndoRestoresSelectedContent() throws {
            let textView = STTextView()
            textView.text = "abc"
            textView.textSelection = NSRange(location: 0, length: 3)
            let coordinator = makeCoordinator(for: textView)

            let range = try XCTUnwrap(NSTextRange(NSRange(location: 0, length: 3), in: textView.textContentManager))
            XCTAssertFalse(coordinator.shouldChangeText(in: range, replacementString: "{"))

            textView.undoManager?.undo()

            XCTAssertEqual(textView.text, "abc")
            XCTAssertEqual(textView.textSelection, NSRange(location: 0, length: 3))
        }

        func testSurroundSelectionRedoRestoresWrappedSelection() throws {
            let textView = STTextView()
            textView.text = "abc"
            textView.textSelection = NSRange(location: 0, length: 3)
            let coordinator = makeCoordinator(for: textView)

            let range = try XCTUnwrap(NSTextRange(NSRange(location: 0, length: 3), in: textView.textContentManager))
            XCTAssertFalse(coordinator.shouldChangeText(in: range, replacementString: "{"))
            textView.undoManager?.undo()

            textView.undoManager?.redo()

            XCTAssertEqual(textView.text, "{abc}")
            XCTAssertEqual(textView.textSelection, NSRange(location: 1, length: 3))
        }

        func testGeneratedCloseDoesNotCallShouldChangeAgain() throws {
            let textView = STTextView()
            textView.text = ""
            textView.textSelection = NSRange(location: 0, length: 0)
            let delegate = CountingDelegate()
            textView.textDelegate = delegate
            let coordinator = makeCoordinator(for: textView)

            var range = try XCTUnwrap(NSTextRange(NSRange(location: 0, length: 0), in: textView.textContentManager))
            XCTAssertTrue(coordinator.shouldChangeText(in: range, replacementString: "{"))
            textView.insertText("{", replacementRange: NSRange(location: 0, length: 0))
            textView.textSelection = NSRange(location: 1, length: 0)
            delegate.shouldChangeCallCount = 0

            range = try XCTUnwrap(NSTextRange(NSRange(location: 1, length: 0), in: textView.textContentManager))
            XCTAssertFalse(coordinator.shouldChangeText(in: range, replacementString: "a"))

            XCTAssertEqual(textView.text, "{a}")
            XCTAssertEqual(delegate.shouldChangeCallCount, 0)
        }
    }
#endif
