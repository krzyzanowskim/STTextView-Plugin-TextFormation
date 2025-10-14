import AppKit

import STTextView
import TextFormation
import TextFormationPlugin

final class EditorViewController: NSViewController {
    private var textView: STTextView!

    override func loadView() {
        let scrollView = STTextView.scrollableTextView()
        textView = scrollView.documentView as? STTextView
        view = scrollView

        // a delegate must be set for plug ins to work
        textView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame.size = CGSize(width: 500, height: 500)

        let filters: [Filter] = [
            StandardOpenPairFilter(open: "{", close: "}"),
            StandardOpenPairFilter(open: "(", close: ")"),
            StandardOpenPairFilter(open: "[", close: "]"),
            StandardOpenPairFilter(open: "<", close: ">"),
            StandardOpenPairFilter(open: "\"", close: "\""),
            StandardOpenPairFilter(open: "`", close: "`"),
            NewlineProcessingFilter(),
            DeleteCloseFilter(open: "{", close: "}"),
            DeleteCloseFilter(open: "(", close: ")"),
            DeleteCloseFilter(open: "[", close: "]"),
            DeleteCloseFilter(open: "<", close: ">"),
        ]

        let indenter = TextualIndenter(patterns: TextualIndenter.basicPatterns)

        let providers = WhitespaceProviders(
            leadingWhitespace: indenter.substitionProvider(indentationUnit: "    ", width: 4),
            trailingWhitespace: WhitespaceProviders.removeAllProvider
        )

        textView.addPlugin(
            TextFormationPlugin(filters: filters, whitespaceProviders: providers)
        )

        textView.backgroundColor = .controlBackgroundColor
        textView.font = .monospacedSystemFont(ofSize: 0, weight: .regular)

        textView.string = """
        import Foundation

        func hello() {
         print("Hello World!")
        }
        """
    }
}

extension EditorViewController: STTextViewDelegate {}
