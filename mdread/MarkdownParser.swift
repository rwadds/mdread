import Foundation

struct MarkdownParser {
    private let lines: [String]
    private var idx: Int = 0

    private init(_ source: String) {
        self.lines = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    static func parse(_ source: String) -> [MarkdownBlock] {
        var parser = MarkdownParser(source)
        return parser.parseBlocks()
    }

    private mutating func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        while idx < lines.count {
            let line = lines[idx]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                idx += 1
                continue
            }
            if isHorizontalRule(trimmed) {
                blocks.append(.divider)
                idx += 1
                continue
            }
            if let heading = matchHeading(trimmed) {
                blocks.append(heading)
                idx += 1
                continue
            }
            if let code = consumeFencedCodeBlock() {
                blocks.append(code)
                continue
            }
            if let quote = consumeBlockquote() {
                blocks.append(quote)
                continue
            }
            if let list = consumeUnorderedList() {
                blocks.append(list)
                continue
            }
            if let list = consumeOrderedList() {
                blocks.append(list)
                continue
            }
            blocks.append(consumeParagraph())
        }
        return blocks
    }

    // MARK: - Block matchers

    private func isHorizontalRule(_ trimmed: String) -> Bool {
        guard trimmed.count >= 3 else { return false }
        for marker: Character in ["-", "*", "_"] {
            let stripped = trimmed.filter { !$0.isWhitespace }
            if stripped.count >= 3, stripped.allSatisfy({ $0 == marker }) {
                return true
            }
        }
        return false
    }

    private func matchHeading(_ trimmed: String) -> MarkdownBlock? {
        var level = 0
        var iterator = trimmed.makeIterator()
        while let ch = iterator.next(), ch == "#", level < 6 {
            level += 1
        }
        guard level > 0 else { return nil }
        let afterHashes = trimmed.index(trimmed.startIndex, offsetBy: level)
        guard afterHashes < trimmed.endIndex else { return nil }
        let firstAfter = trimmed[afterHashes]
        guard firstAfter == " " || firstAfter == "\t" else { return nil }
        var content = String(trimmed[trimmed.index(after: afterHashes)...])
        // Strip trailing closing #'s (e.g. "## foo ##")
        content = content.trimmingCharacters(in: .whitespaces)
        while content.hasSuffix("#") {
            content.removeLast()
        }
        content = content.trimmingCharacters(in: .whitespaces)
        return .heading(level: level, text: content)
    }

    private mutating func consumeFencedCodeBlock() -> MarkdownBlock? {
        let line = lines[idx]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let fence: String
        if trimmed.hasPrefix("```") {
            fence = "```"
        } else if trimmed.hasPrefix("~~~") {
            fence = "~~~"
        } else {
            return nil
        }
        let langStart = trimmed.index(trimmed.startIndex, offsetBy: fence.count)
        let language = String(trimmed[langStart...]).trimmingCharacters(in: .whitespaces)
        let normalizedLanguage = language.isEmpty ? nil : language

        idx += 1
        var codeLines: [String] = []
        while idx < lines.count {
            let current = lines[idx]
            if current.trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                idx += 1
                break
            }
            codeLines.append(current)
            idx += 1
        }
        return .codeBlock(language: normalizedLanguage, code: codeLines.joined(separator: "\n"))
    }

    private mutating func consumeBlockquote() -> MarkdownBlock? {
        let line = lines[idx]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix(">") else { return nil }

        var quoted: [String] = []
        while idx < lines.count {
            let current = lines[idx]
            let currentTrimmed = current.trimmingCharacters(in: .whitespaces)
            if currentTrimmed.hasPrefix(">") {
                var stripped = currentTrimmed
                stripped.removeFirst()
                if stripped.hasPrefix(" ") { stripped.removeFirst() }
                quoted.append(stripped)
                idx += 1
            } else if currentTrimmed.isEmpty {
                break
            } else {
                // Lazy continuation: a non-empty, non-quote line inside a blockquote
                quoted.append(currentTrimmed)
                idx += 1
            }
        }

        let nestedSource = quoted.joined(separator: "\n")
        let nestedBlocks = MarkdownParser.parse(nestedSource)
        return .blockquote(blocks: nestedBlocks)
    }

    private mutating func consumeUnorderedList() -> MarkdownBlock? {
        guard unorderedMarker(in: lines[idx]) != nil else { return nil }
        var items: [String] = []
        while idx < lines.count {
            let current = lines[idx]
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }
            guard let markerEnd = unorderedMarker(in: current) else {
                // Continuation of previous item if indented; otherwise list ends.
                if current.first == " " || current.first == "\t", var last = items.popLast() {
                    last.append(" ")
                    last.append(trimmed)
                    items.append(last)
                    idx += 1
                    continue
                } else {
                    break
                }
            }
            let content = String(current[markerEnd...]).trimmingCharacters(in: .whitespaces)
            items.append(content)
            idx += 1
        }
        guard !items.isEmpty else { return nil }
        return .unorderedList(items: items)
    }

    private mutating func consumeOrderedList() -> MarkdownBlock? {
        guard let firstMatch = orderedMarker(in: lines[idx]) else { return nil }
        var items: [String] = []
        items.append(firstMatch.content)
        let start = firstMatch.number
        idx += 1
        while idx < lines.count {
            let current = lines[idx]
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }
            if let match = orderedMarker(in: current) {
                items.append(match.content)
                idx += 1
                continue
            }
            // Continuation
            if (current.first == " " || current.first == "\t"), var last = items.popLast() {
                last.append(" ")
                last.append(trimmed)
                items.append(last)
                idx += 1
                continue
            }
            break
        }
        return .orderedList(start: start, items: items)
    }

    private mutating func consumeParagraph() -> MarkdownBlock {
        var pieces: [String] = []
        while idx < lines.count {
            let current = lines[idx]
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }
            if isHorizontalRule(trimmed) { break }
            if matchHeading(trimmed) != nil { break }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") { break }
            if trimmed.hasPrefix(">") { break }
            if unorderedMarker(in: current) != nil { break }
            if orderedMarker(in: current) != nil { break }
            pieces.append(trimmed)
            idx += 1
        }
        return .paragraph(text: pieces.joined(separator: " "))
    }

    // MARK: - List marker helpers

    private func unorderedMarker(in line: String) -> String.Index? {
        // Allow up to 3 spaces of indent before the marker, then '-', '*', or '+', then a space.
        var i = line.startIndex
        var leadingSpaces = 0
        while i < line.endIndex, line[i] == " ", leadingSpaces < 3 {
            leadingSpaces += 1
            i = line.index(after: i)
        }
        guard i < line.endIndex else { return nil }
        let ch = line[i]
        guard ch == "-" || ch == "*" || ch == "+" else { return nil }
        let next = line.index(after: i)
        guard next < line.endIndex, line[next] == " " || line[next] == "\t" else { return nil }
        return line.index(after: next)
    }

    private struct OrderedMatch {
        let number: Int
        let content: String
    }

    private func orderedMarker(in line: String) -> OrderedMatch? {
        var i = line.startIndex
        var leadingSpaces = 0
        while i < line.endIndex, line[i] == " ", leadingSpaces < 3 {
            leadingSpaces += 1
            i = line.index(after: i)
        }
        var digits = ""
        while i < line.endIndex, line[i].isASCII, line[i].isNumber, digits.count < 9 {
            digits.append(line[i])
            i = line.index(after: i)
        }
        guard !digits.isEmpty, i < line.endIndex else { return nil }
        let punct = line[i]
        guard punct == "." || punct == ")" else { return nil }
        let afterPunct = line.index(after: i)
        guard afterPunct < line.endIndex, line[afterPunct] == " " || line[afterPunct] == "\t" else {
            return nil
        }
        let contentStart = line.index(after: afterPunct)
        let content = String(line[contentStart...]).trimmingCharacters(in: .whitespaces)
        return OrderedMatch(number: Int(digits) ?? 1, content: content)
    }
}
