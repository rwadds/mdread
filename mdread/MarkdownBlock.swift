import Foundation

enum MarkdownBlock: Equatable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case blockquote(blocks: [MarkdownBlock])
    case unorderedList(items: [String])
    case orderedList(start: Int, items: [String])
    case divider
}
