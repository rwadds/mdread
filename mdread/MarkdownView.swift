import AppKit
import SwiftUI

struct MarkdownView: View {
    let blocks: [MarkdownBlock]
    let textScale: Double
    var baseURL: URL?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(FindState.self) private var find

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { offset, block in
                        BlockView(block: block, textScale: textScale, baseURL: baseURL, path: [offset])
                            .padding(.top, topSpacing(for: block, isFirst: offset == 0))
                            .id(offset)
                    }
                }
                .frame(maxWidth: ReaderMetrics.columnMaxWidth, alignment: .leading)
                .padding(.horizontal, ReaderMetrics.horizontalPadding)
                .padding(.vertical, ReaderMetrics.verticalPadding)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(ReaderTheme.background(for: colorScheme))
            .onChange(of: find.scrollGeneration) { _, _ in
                guard let target = find.currentMatch?.topBlock else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(target, anchor: .center)
                }
            }
        }
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
    let path: [Int]

    var body: some View {
        switch block {
        case .heading(let level, let text):
            HeadingView(level: level, text: text, textScale: textScale, path: path)
        case .paragraph(let text):
            ParagraphView(text: text, textScale: textScale, path: path)
        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code, textScale: textScale, path: path)
        case .blockquote(let inner):
            BlockquoteView(blocks: inner, textScale: textScale, baseURL: baseURL, path: path)
        case .list(let list):
            ListView(list: list, baseURL: baseURL, textScale: textScale, path: path)
        case .image(let url, let alt, let title):
            ImageBlockView(url: url, alt: alt, title: title, baseURL: baseURL, textScale: textScale)
        case .table(let headers, let alignments, let rows):
            TableView(headers: headers, alignments: alignments, rows: rows, textScale: textScale, path: path)
        case .divider:
            DividerLine()
        }
    }
}

private struct ParagraphView: View {
    let text: String
    let textScale: Double
    let path: [Int]
    @Environment(FindState.self) private var find

    var body: some View {
        Text(find.highlighted(text, path: path))
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
    let path: [Int]
    @Environment(FindState.self) private var find

    var body: some View {
        Text(find.highlighted(text, path: path))
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
    let path: [Int]
    @Environment(FindState.self) private var find
    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }
            Text(find.highlightedPlain(code, path: path))
                .font(.system(size: ReaderMetrics.baseCodeSize * textScale, design: .monospaced))
                .lineSpacing(3 * textScale)
                .foregroundStyle(.primary.opacity(0.9))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.codeBorder, lineWidth: 0.5)
        )
        .overlay(alignment: .topTrailing) {
            copyButton
                .padding(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onHover { isHovering = $0 }
    }

    private var copyButton: some View {
        Button(action: copy) {
            Label(didCopy ? "Copied" : "Copy",
                  systemImage: didCopy ? "checkmark" : "doc.on.doc")
                .labelStyle(.iconOnly)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(didCopy ? Color.green : Color.secondary)
                .frame(width: 26, height: 22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(didCopy ? "Copied to clipboard" : "Copy code")
        .opacity(isHovering || didCopy ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .animation(.easeInOut(duration: 0.15), value: didCopy)
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        didCopy = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            didCopy = false
        }
    }
}

private struct BlockquoteView: View {
    let blocks: [MarkdownBlock]
    let textScale: Double
    let baseURL: URL?
    let path: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { offset, block in
                BlockView(block: block, textScale: textScale, baseURL: baseURL, path: path + [offset])
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
    let list: MarkdownList
    let baseURL: URL?
    let textScale: Double
    let path: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * textScale) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { index, item in
                ListItemView(
                    item: item,
                    marker: marker(for: index),
                    baseURL: baseURL,
                    textScale: textScale,
                    path: path + [index]
                )
            }
        }
    }

    private func marker(for index: Int) -> String {
        list.ordered ? "\(list.start + index)." : "•"
    }
}

private struct ListItemView: View {
    let item: ListItem
    let marker: String
    let baseURL: URL?
    let textScale: Double
    let path: [Int]
    @Environment(FindState.self) private var find

    var body: some View {
        VStack(alignment: .leading, spacing: 8 * textScale) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                markerView
                Text(find.highlighted(item.text, path: path))
                    .font(.system(size: ReaderMetrics.baseBodySize * textScale, design: .serif))
                    .lineSpacing(ReaderMetrics.baseLineSpacing * textScale)
                    .foregroundStyle(item.task == .done ? .secondary : .primary)
                    .strikethrough(item.task == .done, color: .secondary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !item.children.isEmpty {
                VStack(alignment: .leading, spacing: 8 * textScale) {
                    ForEach(Array(item.children.enumerated()), id: \.offset) { offset, child in
                        BlockView(block: child, textScale: textScale, baseURL: baseURL, path: path + [offset])
                    }
                }
                .padding(.leading, 28)
            }
        }
    }

    @ViewBuilder
    private var markerView: some View {
        switch item.task {
        case .open:
            Image(systemName: "square")
                .font(.system(size: ReaderMetrics.baseBodySize * textScale * 0.95))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        case .done:
            Image(systemName: "checkmark.square.fill")
                .font(.system(size: ReaderMetrics.baseBodySize * textScale * 0.95))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, alignment: .trailing)
        case .none:
            Text(marker)
                .font(.system(size: ReaderMetrics.baseBodySize * textScale, design: .serif))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
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
    let path: [Int]
    @Environment(FindState.self) private var find

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(headers.enumerated()), id: \.offset) { index, value in
                        cell(value, column: index, isHeader: true, cellPath: path + [-1, index])
                            .gridColumnAlignment(columnAlignment(index))
                    }
                }
                Divider()
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { index, value in
                            cell(value, column: index, isHeader: false, cellPath: path + [rowIndex, index])
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

    private func cell(_ text: String, column: Int, isHeader: Bool, cellPath: [Int]) -> some View {
        let alignment = column < alignments.count ? alignments[column] : ColumnAlignment.leading
        return Text(find.highlighted(text, path: cellPath))
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
