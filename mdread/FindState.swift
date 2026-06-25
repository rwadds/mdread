import Observation
import SwiftUI

/// In-document find. The reader renders each block as its own SwiftUI `Text`,
/// so there is no single `NSTextView` to host the native find bar. Instead we
/// build a flat, ordered index of every text-bearing leaf (each addressed by a
/// stable path through the block tree), search those strings, and hand each
/// leaf view back a highlighted `AttributedString`. The current match drives a
/// scroll to its enclosing top-level block.
@MainActor
@Observable
final class FindState {
    var isPresented = false
    private(set) var query = ""
    private(set) var matches: [FindMatch] = []
    private(set) var currentIndex = 0

    /// Bumped whenever the current match changes; `MarkdownView` observes this
    /// to scroll the match into view.
    private(set) var scrollGeneration = 0
    /// Bumped to ask the find field to (re)take focus, e.g. on a second ⌘F.
    private(set) var focusRequest = 0

    @ObservationIgnored private var leaves: [FindLeaf] = []
    @ObservationIgnored private var indexedDocID: UUID?
    @ObservationIgnored private var indexGeneration = 0

    /// The query used for highlighting — empty (no highlights) while the bar is
    /// hidden, so closing find instantly clears the page.
    var activeQuery: String { isPresented ? query : "" }

    var currentMatch: FindMatch? {
        matches.indices.contains(currentIndex) ? matches[currentIndex] : nil
    }

    var statusText: String {
        if query.isEmpty { return "" }
        if matches.isEmpty { return "No results" }
        return "\(currentIndex + 1) of \(matches.count)"
    }

    // MARK: - Presentation

    func present(for document: MarkdownDocument?) {
        isPresented = true
        focusRequest += 1
        if let document { ensureIndex(for: document) }
    }

    func dismiss() {
        isPresented = false
    }

    func toggle(for document: MarkdownDocument?) {
        if isPresented { dismiss() } else { present(for: document) }
    }

    /// Called when the open document is replaced (new file or reload) so the
    /// index is rebuilt against the new content.
    func documentDidChange(_ document: MarkdownDocument?) {
        leaves = []
        indexedDocID = nil
        matches = []
        currentIndex = 0
        if isPresented, let document { ensureIndex(for: document) }
    }

    // MARK: - Query & navigation

    func setQuery(_ newValue: String) {
        guard newValue != query else { return }
        query = newValue
        recomputeMatches()
    }

    func next() { move(by: 1) }
    func previous() { move(by: -1) }

    private func move(by delta: Int) {
        guard !matches.isEmpty else { return }
        let count = matches.count
        currentIndex = ((currentIndex + delta) % count + count) % count
        scrollGeneration += 1
    }

    // MARK: - Indexing

    private func ensureIndex(for document: MarkdownDocument) {
        guard indexedDocID != document.id else { return }
        indexedDocID = document.id
        indexGeneration += 1
        let generation = indexGeneration
        let blocks = document.blocks
        Task.detached(priority: .userInitiated) {
            let collected = FindIndexer.collect(blocks: blocks)
            await MainActor.run {
                guard generation == self.indexGeneration else { return }
                self.leaves = collected
                self.recomputeMatches()
            }
        }
    }

    private func recomputeMatches() {
        let q = query
        guard !q.isEmpty else {
            matches = []
            currentIndex = 0
            scrollGeneration += 1
            return
        }
        var result: [FindMatch] = []
        for leaf in leaves {
            let count = TextMatcher.count(of: q, in: leaf.text)
            for occurrence in 0..<count {
                result.append(FindMatch(path: leaf.path, occurrence: occurrence))
            }
        }
        matches = result
        if currentIndex >= result.count { currentIndex = 0 }
        scrollGeneration += 1
    }

    // MARK: - Highlighting

    /// Inline-markdown text with match highlighting applied for the leaf at `path`.
    func highlighted(_ source: String, path: [Int]) -> AttributedString {
        var attr = InlineMarkdown.attributed(source)
        highlight(&attr, path: path)
        return attr
    }

    /// Plain (non-markdown) text — e.g. code blocks — with highlighting applied.
    func highlightedPlain(_ source: String, path: [Int]) -> AttributedString {
        var attr = AttributedString(source)
        highlight(&attr, path: path)
        return attr
    }

    /// Applies match highlighting to `attr` for the leaf at `path`. No-op when
    /// the query is empty, so non-find renders are unaffected.
    func highlight(_ attr: inout AttributedString, path: [Int]) {
        let q = activeQuery
        guard !q.isEmpty else { return }
        let plain = String(attr.characters)
        let ranges = TextMatcher.ranges(of: q, in: plain)
        guard !ranges.isEmpty else { return }

        let currentOccurrence = (currentMatch?.path == path) ? currentMatch?.occurrence : nil
        for (occurrence, range) in ranges.enumerated() {
            let lower = plain.distance(from: plain.startIndex, to: range.lowerBound)
            let length = plain.distance(from: range.lowerBound, to: range.upperBound)
            let chars = attr.characters
            let start = chars.index(chars.startIndex, offsetBy: lower)
            let end = chars.index(start, offsetBy: length)
            let isCurrent = occurrence == currentOccurrence
            attr[start..<end].backgroundColor = isCurrent ? FindStyle.current : FindStyle.match
            attr[start..<end].foregroundColor = FindStyle.text
        }
    }
}

/// A single match: which leaf (by tree path) and which occurrence within it.
nonisolated struct FindMatch: Hashable {
    let path: [Int]
    let occurrence: Int
    /// The enclosing top-level block index — the scroll target.
    var topBlock: Int { path.first ?? 0 }
}

/// A text-bearing leaf of the block tree, keyed by a stable path.
nonisolated struct FindLeaf: Sendable {
    let path: [Int]
    let text: String
}

enum FindStyle {
    static let match = Color(red: 1.0, green: 0.86, blue: 0.18)
    static let current = Color(red: 1.0, green: 0.56, blue: 0.0)
    static let text = Color.black
}

/// Case- and diacritic-insensitive substring search, returning every
/// (non-overlapping) match range. The same function powers both the match
/// index and per-leaf highlighting, so occurrence ordering stays consistent.
nonisolated enum TextMatcher {
    static let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    static func ranges(of query: String, in text: String) -> [Range<String.Index>] {
        guard !query.isEmpty else { return [] }
        var result: [Range<String.Index>] = []
        var start = text.startIndex
        while start < text.endIndex,
              let range = text.range(of: query, options: options, range: start..<text.endIndex) {
            result.append(range)
            start = range.isEmpty ? text.index(after: range.lowerBound) : range.upperBound
        }
        return result
    }

    static func count(of query: String, in text: String) -> Int {
        ranges(of: query, in: text).count
    }
}

/// Walks the block tree producing one `FindLeaf` per searchable run of text.
/// The path scheme here MUST match the `path` threaded through `MarkdownView`'s
/// view tree, so highlights line up with the index.
nonisolated enum FindIndexer {
    static func collect(blocks: [MarkdownBlock]) -> [FindLeaf] {
        var leaves: [FindLeaf] = []
        for (index, block) in blocks.enumerated() {
            visit(block, path: [index], into: &leaves)
        }
        return leaves
    }

    private static func visit(_ block: MarkdownBlock, path: [Int], into leaves: inout [FindLeaf]) {
        switch block {
        case .heading(_, let text):
            append(text, markdown: true, path: path, into: &leaves)
        case .paragraph(let text):
            append(text, markdown: true, path: path, into: &leaves)
        case .codeBlock(_, let code):
            append(code, markdown: false, path: path, into: &leaves)
        case .blockquote(let inner):
            for (childIndex, child) in inner.enumerated() {
                visit(child, path: path + [childIndex], into: &leaves)
            }
        case .list(let list):
            for (itemIndex, item) in list.items.enumerated() {
                let itemPath = path + [itemIndex]
                append(item.text, markdown: true, path: itemPath, into: &leaves)
                for (childIndex, child) in item.children.enumerated() {
                    visit(child, path: itemPath + [childIndex], into: &leaves)
                }
            }
        case .table(let headers, _, let rows):
            for (column, header) in headers.enumerated() {
                append(header, markdown: true, path: path + [-1, column], into: &leaves)
            }
            for (rowIndex, row) in rows.enumerated() {
                for (column, cell) in row.enumerated() {
                    append(cell, markdown: true, path: path + [rowIndex, column], into: &leaves)
                }
            }
        case .image, .divider:
            break
        }
    }

    private static func append(_ source: String, markdown: Bool, path: [Int], into leaves: inout [FindLeaf]) {
        let text = markdown ? InlineMarkdown.plainText(source) : source
        guard !text.isEmpty else { return }
        leaves.append(FindLeaf(path: path, text: text))
    }
}
