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
            if let table = consumeTable() {
                blocks.append(table)
                continue
            }
            if let list = consumeList() {
                blocks.append(list)
                continue
            }
            blocks.append(contentsOf: consumeParagraph())
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

    // MARK: - Tables

    /// True when the line at `index` is a table header followed by a valid
    /// GFM delimiter row with a matching column count.
    private func isTableStart(at index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        guard lines[index].contains("|") else { return false }
        guard let alignments = parseDelimiterRow(lines[index + 1]) else { return false }
        let headers = splitTableRow(lines[index])
        return !headers.isEmpty && headers.count == alignments.count
    }

    private mutating func consumeTable() -> MarkdownBlock? {
        guard isTableStart(at: idx) else { return nil }
        let headers = splitTableRow(lines[idx])
        guard let alignments = parseDelimiterRow(lines[idx + 1]) else { return nil }
        idx += 2

        var rows: [[String]] = []
        while idx < lines.count {
            let trimmed = lines[idx].trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.contains("|") else { break }
            var cells = splitTableRow(lines[idx])
            if cells.count < headers.count {
                cells += Array(repeating: "", count: headers.count - cells.count)
            } else if cells.count > headers.count {
                cells = Array(cells.prefix(headers.count))
            }
            rows.append(cells)
            idx += 1
        }
        return .table(headers: headers, alignments: alignments, rows: rows)
    }

    /// Splits a table row into trimmed cells, honoring `\|` escapes and the
    /// optional leading/trailing pipes.
    private func splitTableRow(_ line: String) -> [String] {
        var content = line.trimmingCharacters(in: .whitespaces)
        if content.hasPrefix("|") {
            content.removeFirst()
        }
        if content.hasSuffix("|"), !content.hasSuffix("\\|") {
            content.removeLast()
        }

        var cells: [String] = []
        var current = ""
        var escaped = false
        for character in content {
            if escaped {
                if character == "|" {
                    current.append("|")
                } else {
                    current.append("\\")
                    current.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }
        if escaped { current.append("\\") }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    /// Parses a GFM delimiter row (`| :--- | :--: | ---: |`) into per-column
    /// alignments, or `nil` when the line is not a delimiter row.
    private func parseDelimiterRow(_ line: String) -> [ColumnAlignment]? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("-") else { return nil }
        let allowed: Set<Character> = ["|", ":", "-", " ", "\t"]
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }

        let cells = splitTableRow(line)
        guard !cells.isEmpty else { return nil }

        var alignments: [ColumnAlignment] = []
        for cell in cells {
            let spec = cell.trimmingCharacters(in: .whitespaces)
            let left = spec.hasPrefix(":")
            let right = spec.hasSuffix(":")
            let dashes = spec.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            guard !dashes.isEmpty, dashes.allSatisfy({ $0 == "-" }) else { return nil }
            switch (left, right) {
            case (true, true): alignments.append(.center)
            case (false, true): alignments.append(.trailing)
            default: alignments.append(.leading)
            }
        }
        return alignments
    }

    // MARK: - Lists

    private struct ListMarker {
        let markerIndent: Int
        let ordered: Bool
        let number: Int
        let text: String
        let task: TaskState?
    }

    private mutating func consumeList() -> MarkdownBlock? {
        guard let first = listMarker(in: lines[idx]) else { return nil }
        return .list(parseList(at: first.markerIndent))
    }

    /// Parses one list whose item markers sit at `indent` columns, recursing
    /// for any more-indented markers as nested lists. Stops when a line dedents
    /// out of the list or is no longer list content.
    private mutating func parseList(at indent: Int) -> MarkdownList {
        var items: [ListItem] = []
        var ordered = false
        var start = 1
        var sawFirstItem = false

        while idx < lines.count {
            let line = lines[idx]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                // Tolerate a single blank line when the list resumes afterwards.
                if let next = nextNonBlankIndex(after: idx),
                   let nextMarker = listMarker(in: lines[next]),
                   nextMarker.markerIndent >= indent {
                    idx += 1
                    continue
                }
                break
            }

            guard let marker = listMarker(in: line) else {
                // A non-marker line indented under the list continues the item.
                if leadingIndent(of: line) > indent, var last = items.popLast() {
                    last.text += last.text.isEmpty ? trimmed : " " + trimmed
                    items.append(last)
                    idx += 1
                    continue
                }
                break
            }

            if marker.markerIndent < indent {
                break
            }

            if marker.markerIndent > indent {
                // A deeper marker: a nested list belonging to the last item.
                if var last = items.popLast() {
                    last.children.append(.list(parseList(at: marker.markerIndent)))
                    items.append(last)
                    continue
                }
                break
            }

            if !sawFirstItem {
                sawFirstItem = true
                ordered = marker.ordered
                start = marker.number
            }
            items.append(ListItem(text: marker.text, task: marker.task, children: []))
            idx += 1
        }

        return MarkdownList(ordered: ordered, start: start, items: items)
    }

    /// Parses a list-item marker (`-`, `*`, `+`, or `1.` / `1)`) at the start
    /// of `line`, including any `[ ]` / `[x]` task checkbox.
    private func listMarker(in line: String) -> ListMarker? {
        let indent = leadingIndent(of: line)
        var index = line.startIndex
        while index < line.endIndex, line[index] == " " || line[index] == "\t" {
            index = line.index(after: index)
        }
        guard index < line.endIndex else { return nil }

        let ordered: Bool
        let number: Int
        let afterMarker: String.Index

        let first = line[index]
        if first == "-" || first == "*" || first == "+" {
            ordered = false
            number = 1
            afterMarker = line.index(after: index)
        } else if first.isNumber {
            var digits = ""
            var cursor = index
            while cursor < line.endIndex, line[cursor].isNumber, digits.count < 9 {
                digits.append(line[cursor])
                cursor = line.index(after: cursor)
            }
            guard cursor < line.endIndex, line[cursor] == "." || line[cursor] == ")" else {
                return nil
            }
            ordered = true
            number = Int(digits) ?? 1
            afterMarker = line.index(after: cursor)
        } else {
            return nil
        }

        // The marker must be followed by whitespace, unless it is an empty item.
        var contentStart = afterMarker
        if contentStart < line.endIndex {
            guard line[contentStart] == " " || line[contentStart] == "\t" else { return nil }
            while contentStart < line.endIndex,
                  line[contentStart] == " " || line[contentStart] == "\t" {
                contentStart = line.index(after: contentStart)
            }
        }

        var text = String(line[contentStart...]).trimmingCharacters(in: .whitespaces)
        let task = parseTaskPrefix(&text)
        return ListMarker(markerIndent: indent, ordered: ordered,
                          number: number, text: text, task: task)
    }

    /// Detects and strips a leading `[ ]`, `[x]`, or `[X]` task checkbox,
    /// returning its state and removing it from `text`.
    private func parseTaskPrefix(_ text: inout String) -> TaskState? {
        let chars = Array(text)
        guard chars.count >= 3, chars[0] == "[", chars[2] == "]" else { return nil }
        let state: TaskState
        switch chars[1] {
        case " ": state = .open
        case "x", "X": state = .done
        default: return nil
        }
        if chars.count == 3 {
            text = ""
            return state
        }
        guard chars[3] == " " || chars[3] == "\t" else { return nil }
        text = String(chars[4...]).trimmingCharacters(in: .whitespaces)
        return state
    }

    private func leadingIndent(of line: String) -> Int {
        var indent = 0
        for character in line {
            if character == " " {
                indent += 1
            } else if character == "\t" {
                indent += 4
            } else {
                break
            }
        }
        return indent
    }

    private func nextNonBlankIndex(after index: Int) -> Int? {
        var cursor = index + 1
        while cursor < lines.count {
            if !lines[cursor].trimmingCharacters(in: .whitespaces).isEmpty {
                return cursor
            }
            cursor += 1
        }
        return nil
    }

    private mutating func consumeParagraph() -> [MarkdownBlock] {
        var pieces: [String] = []
        while idx < lines.count {
            let current = lines[idx]
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }
            if isHorizontalRule(trimmed) { break }
            if matchHeading(trimmed) != nil { break }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") { break }
            if trimmed.hasPrefix(">") { break }
            if isTableStart(at: idx) { break }
            if listMarker(in: current) != nil { break }
            pieces.append(trimmed)
            idx += 1
        }
        return Self.splitImageBlocks(pieces.joined(separator: " "))
    }

    // MARK: - Inline images

    private static let imageRegex = try! NSRegularExpression(
        pattern: #"!\[([^\]]*)\]\(([^)]*)\)"#
    )

    /// Splits paragraph text into an ordered run of text paragraphs and image
    /// blocks. A paragraph that is solely an image becomes one `.image` block;
    /// an image embedded in prose splits the prose around it.
    private static func splitImageBlocks(_ text: String) -> [MarkdownBlock] {
        let ns = text as NSString
        let matches = imageRegex.matches(
            in: text,
            range: NSRange(location: 0, length: ns.length)
        )
        guard !matches.isEmpty else { return [.paragraph(text: text)] }

        var blocks: [MarkdownBlock] = []
        var cursor = 0
        for match in matches {
            if match.range.location > cursor {
                let gap = NSRange(location: cursor, length: match.range.location - cursor)
                appendParagraph(ns.substring(with: gap), to: &blocks)
            }
            let alt = ns.substring(with: match.range(at: 1))
            let dest = ns.substring(with: match.range(at: 2))
            let (url, title) = parseImageDestination(dest)
            blocks.append(.image(url: url, alt: alt, title: title))
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length {
            appendParagraph(ns.substring(from: cursor), to: &blocks)
        }
        return blocks.isEmpty ? [.paragraph(text: text)] : blocks
    }

    private static func appendParagraph(_ text: String, to blocks: inout [MarkdownBlock]) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        blocks.append(.paragraph(text: trimmed))
    }

    private static func parseImageDestination(_ source: String) -> (url: String, title: String?) {
        let dest = source.trimmingCharacters(in: .whitespaces)
        if let range = dest.range(of: #"\s+["'][^"']*["']$"#, options: .regularExpression) {
            let quoted = dest[range].trimmingCharacters(in: .whitespaces)
            let title = String(quoted.dropFirst().dropLast())
            let url = cleanImageURL(String(dest[dest.startIndex..<range.lowerBound]))
            return (url, title.isEmpty ? nil : title)
        }
        return (cleanImageURL(dest), nil)
    }

    private static func cleanImageURL(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespaces)
        if url.hasPrefix("<"), url.hasSuffix(">"), url.count >= 2 {
            url = String(url.dropFirst().dropLast())
        }
        return url
    }

}
