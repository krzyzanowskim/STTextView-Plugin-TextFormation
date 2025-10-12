[STTextView](https://github.com/krzyzanowskim/STTextView) typing completions with [TextFormation](https://github.com/ChimeHQ/TextFormation).

## Installation

Add the plugin package as a dependency of your application, then register/add it to the `STTextView` instance:

```swift
import TextFormation
import TextFormationPlugin

let filters = [
    StandardOpenPairFilter(open: "[", close: "]")
]

let providers = WhitespaceProviders(
    leadingWhitespace: WhitespaceProviders.passthroughProvider,
    trailingWhitespace: WhitespaceProviders.removeAllProvider
)

textView.addPlugin(
    TextFormationPlugin(filters: filters, whitespaceProviders: providers)
)
```

Note that both the `Filter` array and `WhitespaceProviders` must be specified statically and cannot be changed for the lifetime of the plugin. If you need to change these, when the document type changes for example, the plugin must be re-created.

## Contributing and Feedback

I'd love to hear from you! Get in touch via an issue or pull request.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).
