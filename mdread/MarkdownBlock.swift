import Foundation

enum MarkdownBlock: Equatable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case blockquote(blocks: [MarkdownBlock])
    case unorderedList(items: [String])
    case orderedList(start: Int, items: [String])
    case image(url: String, alt: String, title: String?)
    case table(headers: [String], alignments: [ColumnAlignment], rows: [[String]])
    case divider
}

enum ColumnAlignment: Equatable, Hashable {
    case leading
    case center
    case trailing
}
