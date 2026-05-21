import SwiftUI

enum InlineMarkdown {
    static func attributed(_ source: String) -> AttributedString {
        let cleaned = HTMLText.outsideCodeSpans(source) { HTMLText.plainText(from: $0) }
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible,
            languageCode: nil
        )
        var attr = (try? AttributedString(markdown: cleaned, options: options)) ?? AttributedString(cleaned)

        let codeRanges = attr.runs
            .filter { $0.inlinePresentationIntent?.contains(.code) == true }
            .map(\.range)
        for range in codeRanges {
            attr[range].backgroundColor = Color.primary.opacity(0.08)
        }

        let linkRanges = attr.runs
            .filter { $0.link != nil }
            .map(\.range)
        for range in linkRanges {
            attr[range].underlineStyle = .single
            attr[range].foregroundColor = .accentColor
        }

        return attr
    }
}
