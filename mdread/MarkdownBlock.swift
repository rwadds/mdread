import Foundation

enum MarkdownBlock: Equatable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case blockquote(blocks: [MarkdownBlock])
    case list(MarkdownList)
    case image(url: String, alt: String, title: String?)
    case table(headers: [String], alignments: [ColumnAlignment], rows: [[String]])
    case divider
}

struct MarkdownList: Equatable, Hashable {
    var ordered: Bool
    var start: Int
    var items: [ListItem]
}

struct ListItem: Equatable, Hashable {
    var text: String
    var task: TaskState?
    var children: [MarkdownBlock]
}

enum TaskState: Equatable, Hashable {
    case open
    case done
}

enum ColumnAlignment: Equatable, Hashable {
    case leading
    case center
    case trailing
}
