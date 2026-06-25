import SwiftUI

enum InlineMarkdown {
    nonisolated private static let parsingOptions = AttributedString.MarkdownParsingOptions(
        allowsExtendedAttributes: false,
        interpretedSyntax: .inlineOnlyPreservingWhitespace,
        failurePolicy: .returnPartiallyParsedIfPossible,
        languageCode: nil
    )

    /// The rendered plain text for `source`, matching the characters of
    /// `attributed(_:)` exactly. `nonisolated` so the find index can be built
    /// off the main actor.
    nonisolated static func plainText(_ source: String) -> String {
        let cleaned = HTMLText.outsideCodeSpans(source) { HTMLText.plainText(from: $0) }
        let attr = (try? AttributedString(markdown: cleaned, options: parsingOptions))
            ?? AttributedString(cleaned)
        return String(attr.characters)
    }

    static func attributed(_ source: String) -> AttributedString {
        let cleaned = HTMLText.outsideCodeSpans(source) { HTMLText.plainText(from: $0) }
        var attr = (try? AttributedString(markdown: cleaned, options: parsingOptions)) ?? AttributedString(cleaned)

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
