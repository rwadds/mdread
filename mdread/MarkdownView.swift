import AppKit
import SwiftUI

struct MarkdownView: View {
    let blocks: [MarkdownBlock]
    let textScale: Double
    var baseURL: URL?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { offset, block in
                    BlockView(block: block, textScale: textScale, baseURL: baseURL)
                        .padding(.top, topSpacing(for: block, isFirst: offset == 0))
                }
            }
            .frame(maxWidth: ReaderMetrics.columnMaxWidth, alignment: .leading)
            .padding(.horizontal, ReaderMetrics.horizontalPadding)
            .padding(.vertical, ReaderMetrics.verticalPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(ReaderTheme.background(for: colorScheme))
    }

    private func topSpacing(for block: MarkdownBlock, isFirst: Bool) -> CGFloat {
        guard !isFirst else { return 0 }
        switch block {
        case .heading(let level, _):
            switch level {
            case 1: return 40
            case 2: return 32
            case 3: return 26
            default: return 22
            }
        case .codeBlock, .blockquote, .image, .table:
            return 22
        case .divider:
            return 24
        default:
            return 18
        }
    }
}

private enum ReaderMetrics {
    static let columnMaxWidth: CGFloat = 720
    static let horizontalPadding: CGFloat = 56
    static let verticalPadding: CGFloat = 64
    static let baseBodySize: CGFloat = 17
    static let baseCodeSize: CGFloat = 14
    static let baseLineSpacing: CGFloat = 7
}

private struct BlockView: View {
    let block: MarkdownBlock
    let textScale: Double
    let baseURL: URL?

    var body: some View {
        switch block {
        case .heading(let level, let text):
            HeadingView(level: level, text: text, textScale: textScale)
        case .paragraph(let text):
            ParagraphView(text: text, textScale: textScale)
        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code, textScale: textScale)
        case .blockquote(let inner):
            BlockquoteView(blocks: inner, textScale: textScale, baseURL: baseURL)
        case .unorderedList(let items):
            ListView(items: items, ordered: false, start: 1, textScale: textScale)
        case .orderedList(let start, let items):
            ListView(items: items, ordered: true, start: start, textScale: textScale)
        case .image(let url, let alt, let title):
            ImageBlockView(url: url, alt: alt, title: title, baseURL: baseURL, textScale: textScale)
        case .table(let headers, let alignments, let rows):
            TableView(headers: headers, alignments: alignments, rows: rows, textScale: textScale)
        case .divider:
            DividerLine()
        }
    }
}

private struct ParagraphView: View {
    let text: String
    let textScale: Double

    var body: some View {
        Text(InlineMarkdown.attributed(text))
            .font(.system(size: ReaderMetrics.baseBodySize * textScale, design: .serif))
            .lineSpacing(ReaderMetrics.baseLineSpacing * textScale)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HeadingView: View {
    let level: Int
    let text: String
    let textScale: Double

    var body: some View {
        Text(InlineMarkdown.attributed(text))
            .font(.system(size: size, weight: weight, design: .serif))
            .lineSpacing(2 * textScale)
            .tracking(tracking)
            .textCase(textCase)
            .foregroundStyle(foregroundStyle)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, bottomPadding)
    }

    private var size: CGFloat {
        let base: CGFloat
        switch level {
        case 1: base = 36
        case 2: base = 28
        case 3: base = 22
        case 4: base = 19
        case 5: base = 17
        default: base = 14
        }
        return base * textScale
    }

    private var weight: Font.Weight {
        switch level {
        case 1, 2: return .bold
        case 3, 4: return .semibold
        default: return .semibold
        }
    }

    private var tracking: CGFloat {
        level >= 6 ? 1.0 : 0
    }

    private var textCase: Text.Case? {
        level >= 6 ? .uppercase : nil
    }

    private var foregroundStyle: HierarchicalShapeStyle {
        level >= 6 ? .secondary : .primary
    }

    private var bottomPadding: CGFloat {
        switch level {
        case 1: return 8
        case 2: return 6
        default: return 4
        }
    }
}

private struct CodeBlockView: View {
    let language: String?
    let code: String
    let textScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: ReaderMetrics.baseCodeSize * textScale, design: .monospaced))
                    .lineSpacing(3 * textScale)
                    .foregroundStyle(.primary.opacity(0.9))
                    .textSelection(.enabled)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.codeBorder, lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BlockquoteView: View {
    let blocks: [MarkdownBlock]
    let textScale: Double
    let baseURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                BlockView(block: block, textScale: textScale, baseURL: baseURL)
            }
        }
        .padding(.leading, 18)
        .padding(.vertical, 4)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color.accentColor.opacity(0.55))
                .frame(width: 3)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ListView: View {
    let items: [String]
    let ordered: Bool
    let start: Int
    let textScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * textScale) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(marker(for: idx))
                        .font(.system(size: ReaderMetrics.baseBodySize * textScale, design: .serif))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 28, alignment: .trailing)
                    Text(InlineMarkdown.attributed(item))
                        .font(.system(size: ReaderMetrics.baseBodySize * textScale, design: .serif))
                        .lineSpacing(ReaderMetrics.baseLineSpacing * textScale)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func marker(for idx: Int) -> String {
        ordered ? "\(start + idx)." : "•"
    }
}

private struct ImageBlockView: View {
    let url: String
    let alt: String
    let title: String?
    let baseURL: URL?
    let textScale: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            imageContent
            if let caption {
                Text(caption)
                    .font(.system(size: 12.5 * textScale, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var caption: String? {
        if let title, !title.isEmpty { return title }
        return alt.isEmpty ? nil : alt
    }

    @ViewBuilder
    private var imageContent: some View {
        if let resolved = resolvedURL {
            if resolved.isFileURL {
                localImage(resolved)
            } else {
                remoteImage(resolved)
            }
        } else {
            placeholder("Image unavailable")
        }
    }

    @ViewBuilder
    private func remoteImage(_ url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, minHeight: 72)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            case .failure:
                placeholder(alt.isEmpty ? "Couldn't load image" : alt)
            @unknown default:
                placeholder(alt.isEmpty ? "Couldn't load image" : alt)
            }
        }
    }

    @ViewBuilder
    private func localImage(_ url: URL) -> some View {
        if let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: nsImage.size.width)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            placeholder(alt.isEmpty ? "Couldn't load image" : alt)
        }
    }

    private func placeholder(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "photo")
                .font(.system(size: 20))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(size: 13 * textScale, design: .serif))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    /// Resolves the raw Markdown destination to a loadable URL — remote URLs
    /// pass through, local paths resolve against the document's directory.
    private var resolvedURL: URL? {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let parsed = URL(string: trimmed), let scheme = parsed.scheme?.lowercased() {
            if scheme == "http" || scheme == "https" || scheme == "file" {
                return parsed
            }
        }
        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }
        if let baseURL {
            return URL(fileURLWithPath: trimmed, relativeTo: baseURL.deletingLastPathComponent())
        }
        return nil
    }
}

private struct TableView: View {
    let headers: [String]
    let alignments: [ColumnAlignment]
    let rows: [[String]]
    let textScale: Double

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, value in
                        cell(value, column: index, isHeader: true)
                            .gridColumnAlignment(columnAlignment(index))
                    }
                }
                Divider()
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { index, value in
                            cell(value, column: index, isHeader: false)
                        }
                    }
                    if rowIndex < rows.count - 1 {
                        Divider().opacity(0.5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cell(_ text: String, column: Int, isHeader: Bool) -> some View {
        let alignment = column < alignments.count ? alignments[column] : ColumnAlignment.leading
        return Text(InlineMarkdown.attributed(text))
            .font(.system(size: ReaderMetrics.baseBodySize * textScale * 0.95,
                           weight: isHeader ? .semibold : .regular,
                           design: .serif))
            .multilineTextAlignment(textAlignment(alignment))
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .frame(maxWidth: 380)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private func columnAlignment(_ column: Int) -> HorizontalAlignment {
        let alignment = column < alignments.count ? alignments[column] : ColumnAlignment.leading
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    private func textAlignment(_ alignment: ColumnAlignment) -> TextAlignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

private struct DividerLine: View {
    var body: some View {
        HStack {
            Spacer()
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 80, height: 1)
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

private extension Color {
    static let codeBackground = Color.primary.opacity(0.05)
    static let codeBorder = Color.primary.opacity(0.08)
}

enum ReaderTheme {
    static func background(for scheme: ColorScheme) -> Color {
        switch scheme {
        case .dark:
            return Color(red: 0.11, green: 0.105, blue: 0.10)
        default:
            return Color(red: 0.995, green: 0.987, blue: 0.965)
        }
    }
}
