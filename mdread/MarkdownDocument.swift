import Foundation

struct MarkdownDocument: Equatable, Identifiable {
    let id = UUID()
    let url: URL
    let source: String
    let blocks: [MarkdownBlock]

    var title: String {
        url.deletingPathExtension().lastPathComponent
    }
}
