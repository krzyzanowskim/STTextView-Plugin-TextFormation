#if os(macOS)
    import STTextView
    import TextFormation
    @testable import TextFormationPlugin
    import XCTest

    @MainActor
    final class TextFormationPluginBehaviorTests: XCTestCase {
        private func makeCoordinator(for textView: STTextView) -> TextFormationPlugin.Coordinator {
            TextFormationPlugin.Coordinator(
                view: textView,
                filters: [StandardOpenPairFilter(open: "{", close: "}")],
                whitespaceProviders: .none
            )
        }

        private func apply(_ string: String, at range: NSRange, in textView: STTextView, coordinator: TextFormationPlugin.Coordinator) throws {
            let textRange = try XCTUnwrap(NSTextRange(range, in: textView.textContentManager))
            if coordinator.shouldChangeText(in: textRange, replacementString: string) {
                textView.insertText(string, replacementRange: range)
            }
        }

        func testOpenThenCharacterCreatesPairAndUndoStepsThroughUserEditsTogether() throws {
            let textView = STTextView()
            textView.text = ""
            textView.textSelection = NSRange(location: 0, length: 0)
            let coordinator = makeCoordinator(for: textView)

            try apply("{", at: NSRange(location: 0, length: 0), in: textView, coordinator: coordinator)
            textView.textSelection = NSRange(location: 1, length: 0)
            try apply("a", at: NSRange(location: 1, length: 0), in: textView, coordinator: coordinator)

            XCTAssertEqual(textView.text, "{a}")
            XCTAssertEqual(textView.textSelection, NSRange(location: 2, length: 0))

            textView.undoManager?.undo()
            XCTAssertEqual(textView.text, "{")
            textView.undoManager?.undo()
            XCTAssertEqual(textView.text, "")
        }

        func testTypingCloseSkipsExistingClose() throws {
            let textView = STTextView()
            textView.text = "{a}"
            textView.textSelection = NSRange(location: 2, length: 0)
            let coordinator = makeCoordinator(for: textView)

            try apply("}", at: NSRange(location: 2, length: 0), in: textView, coordinator: coordinator)

            XCTAssertEqual(textView.text, "{a}")
            XCTAssertEqual(textView.textSelection, NSRange(location: 3, length: 0))
        }

        func testDeletingOpenAlsoDeletesGeneratedClose() throws {
            let textView = STTextView()
            textView.text = "{}"
            textView.textSelection = NSRange(location: 1, length: 0)
            let coordinator = makeCoordinator(for: textView)

            try apply("", at: NSRange(location: 0, length: 1), in: textView, coordinator: coordinator)

            XCTAssertEqual(textView.text, "")
            XCTAssertEqual(textView.textSelection, NSRange(location: 0, length: 0))
        }

        func testNewlineWithinPairCreatesBlankIndentedLine() throws {
            let textView = STTextView()
            textView.text = "{}"
            textView.textSelection = NSRange(location: 1, length: 0)
            let coordinator = makeCoordinator(for: textView)

            try apply("\n", at: NSRange(location: 1, length: 0), in: textView, coordinator: coordinator)

            XCTAssertEqual(textView.text, "{\n\n}")
            XCTAssertEqual(textView.textSelection, NSRange(location: 2, length: 0))
        }
    }
#endif
