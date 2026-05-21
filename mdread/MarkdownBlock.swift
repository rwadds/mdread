import Foundation

// The block model and parser are `nonisolated` so a document can be parsed
// off the main actor without blocking the UI.

nonisolated enum MarkdownBlock: Equatable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case blockquote(blocks: [MarkdownBlock])
    case list(MarkdownList)
    case image(url: String, alt: String, title: String?)
    case table(headers: [String], alignments: [ColumnAlignment], rows: [[String]])
    case divider
}

nonisolated struct MarkdownList: Equatable, Hashable {
    var ordered: Bool
    var start: Int
    var items: [ListItem]
}

nonisolated struct ListItem: Equatable, Hashable {
    var text: String
    var task: TaskState?
    var children: [MarkdownBlock]
}

nonisolated enum TaskState: Equatable, Hashable {
    case open
    case done
}

nonisolated enum ColumnAlignment: Equatable, Hashable {
    case leading
    case center
    case trailing
}
