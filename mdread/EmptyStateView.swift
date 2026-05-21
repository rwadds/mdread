import SwiftUI

struct EmptyStateView: View {
    let onOpen: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private static let versionLabel: String = {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "v\(version) (\(build))"
    }()

    private static let buildDateLabel: String = {
        let date = Bundle.main.executableURL
            .flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path) }
            .flatMap { $0[.modificationDate] as? Date }
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "built \(formatter.string(from: date))"
    }()

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text("mdread")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(.primary)
                Text("A quiet place to read Markdown.")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.secondary)
                Text(Self.versionLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
                    .textSelection(.enabled)
                if !Self.buildDateLabel.isEmpty {
                    Text(Self.buildDateLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .textSelection(.enabled)
                }
            }

            VStack(spacing: 10) {
                Button(action: onOpen) {
                    Text("Open Markdown File…")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("o", modifiers: [.command])

                Text("or drag a .md file onto this window")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ReaderTheme.background(for: colorScheme))
    }
}

struct DropOverlay: View {
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.08)
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.tint)
                Text("Drop to read")
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundStyle(.tint)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
        )
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}
