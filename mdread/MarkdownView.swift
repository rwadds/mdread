import SwiftUI

struct MarkdownView: View {
    let blocks: [MarkdownBlock]
    let textScale: Double
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { offset, block in
                    BlockView(block: block, textScale: textScale)
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
        case .codeBlock, .blockquote:
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

    var body: some View {
        switch block {
        case .heading(let level, let text):
            HeadingView(level: level, text: text, textScale: textScale)
        case .paragraph(let text):
            ParagraphView(text: text, textScale: textScale)
        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code, textScale: textScale)
        case .blockquote(let inner):
            BlockquoteView(blocks: inner, textScale: textScale)
        case .unorderedList(let items):
            ListView(items: items, ordered: false, start: 1, textScale: textScale)
        case .orderedList(let start, let items):
            ListView(items: items, ordered: true, start: start, textScale: textScale)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                BlockView(block: block, textScale: textScale)
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
