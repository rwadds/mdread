import Foundation

/// Best-effort conversion of raw HTML to plain text — strips tags, decodes
/// common HTML entities, and turns `<br>` into a line break. Used to render
/// HTML passthrough as quiet, readable text rather than angle-bracket soup.
enum HTMLText {
    /// Strips tags and decodes entities from a fragment of raw HTML.
    static func plainText(from html: String) -> String {
        var text = html
        if text.contains("<") {
            text = replace(lineBreakRegex, in: text, with: "\n")
            text = replace(commentRegex, in: text, with: "")
            text = replace(tagRegex, in: text, with: "")
        }
        return decodeEntities(text)
    }

    /// Applies `transform` to the spans of `source` that lie outside inline
    /// code (backtick) spans, copying code spans through verbatim. This keeps
    /// HTML shown inside `` `code` `` literal.
    static func outsideCodeSpans(_ source: String, _ transform: (String) -> String) -> String {
        guard source.contains("`") else { return transform(source) }

        var result = ""
        var index = source.startIndex
        var plainStart = source.startIndex

        while index < source.endIndex {
            guard source[index] == "`" else {
                index = source.index(after: index)
                continue
            }
            var runEnd = index
            while runEnd < source.endIndex, source[runEnd] == "`" {
                runEnd = source.index(after: runEnd)
            }
            let runLength = source.distance(from: index, to: runEnd)
            if let close = closingBacktickRun(length: runLength, in: source, from: runEnd) {
                result += transform(String(source[plainStart..<index]))
                result += String(source[index..<close])
                index = close
                plainStart = close
            } else {
                index = runEnd
            }
        }
        result += transform(String(source[plainStart...]))
        return result
    }

    // MARK: - Tags

    private static let lineBreakRegex = regex(#"<br\s*/?>"#, caseInsensitive: true)
    private static let commentRegex = regex(#"<!--[\s\S]*?-->"#)
    private static let tagRegex = regex(#"</?[A-Za-z][A-Za-z0-9-]*(?:\s+[^<>]*?)?/?>"#)

    private static func regex(_ pattern: String, caseInsensitive: Bool = false) -> NSRegularExpression {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        return try! NSRegularExpression(pattern: pattern, options: options)
    }

    private static func replace(
        _ regex: NSRegularExpression,
        in text: String,
        with template: String
    ) -> String {
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }

    // MARK: - Entities

    private static func decodeEntities(_ source: String) -> String {
        guard source.contains("&") else { return source }
        var result = ""
        result.reserveCapacity(source.count)
        var index = source.startIndex
        while index < source.endIndex {
            guard source[index] == "&" else {
                result.append(source[index])
                index = source.index(after: index)
                continue
            }
            let afterAmp = source.index(after: index)
            if let semicolon = source[afterAmp...].firstIndex(of: ";"),
               source.distance(from: afterAmp, to: semicolon) <= 32,
               let decoded = decodeEntity(String(source[afterAmp..<semicolon])) {
                result.append(decoded)
                index = source.index(after: semicolon)
            } else {
                result.append("&")
                index = afterAmp
            }
        }
        return result
    }

    private static func decodeEntity(_ body: String) -> Character? {
        guard !body.isEmpty else { return nil }
        if body.hasPrefix("#") {
            let digits = body.dropFirst()
            let value: Int?
            if digits.first == "x" || digits.first == "X" {
                value = Int(digits.dropFirst(), radix: 16)
            } else {
                value = Int(digits)
            }
            guard let value, let scalar = Unicode.Scalar(value) else { return nil }
            return Character(scalar)
        }
        return namedEntities[body]
    }

    private static let namedEntities: [String: Character] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "copy": "\u{00A9}", "reg": "\u{00AE}", "trade": "\u{2122}",
        "mdash": "\u{2014}", "ndash": "\u{2013}", "hellip": "\u{2026}",
        "lsquo": "\u{2018}", "rsquo": "\u{2019}", "ldquo": "\u{201C}", "rdquo": "\u{201D}",
        "laquo": "\u{00AB}", "raquo": "\u{00BB}", "deg": "\u{00B0}", "middot": "\u{00B7}",
        "bull": "\u{2022}", "times": "\u{00D7}", "divide": "\u{00F7}", "plusmn": "\u{00B1}",
        "micro": "\u{00B5}", "sect": "\u{00A7}", "para": "\u{00B6}", "dagger": "\u{2020}",
        "cent": "\u{00A2}", "pound": "\u{00A3}", "euro": "\u{20AC}", "yen": "\u{00A5}",
        "frac12": "\u{00BD}", "frac14": "\u{00BC}", "frac34": "\u{00BE}",
    ]

    // MARK: - Code spans

    private static func closingBacktickRun(
        length: Int,
        in source: String,
        from start: String.Index
    ) -> String.Index? {
        var index = start
        while index < source.endIndex {
            guard source[index] == "`" else {
                index = source.index(after: index)
                continue
            }
            var runEnd = index
            while runEnd < source.endIndex, source[runEnd] == "`" {
                runEnd = source.index(after: runEnd)
            }
            if source.distance(from: index, to: runEnd) == length {
                return runEnd
            }
            index = runEnd
        }
        return nil
    }
}
