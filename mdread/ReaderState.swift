import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ReaderState {
    var document: MarkdownDocument?
    var errorMessage: String?
    var textScale: Double

    @ObservationIgnored private var loadGeneration = 0

    static let minScale: Double = 0.7
    static let maxScale: Double = 2.0
    private static let textScaleKey = "textScale"
    private static let didRegisterDefaultKey = "didRegisterMarkdownDefault"
    private static let markdownUTI = "net.daringfireball.markdown"

    init() {
        if let saved = UserDefaults.standard.object(forKey: Self.textScaleKey) as? Double {
            self.textScale = saved.clamped(to: Self.minScale...Self.maxScale)
        } else {
            self.textScale = 1.0
        }
    }

    func load(url: URL) {
        loadGeneration += 1
        let generation = loadGeneration
        Task { await performLoad(url: url, generation: generation) }
    }

    /// Applies the result of an off-main load, discarding it if a newer load
    /// has been started in the meantime.
    private func performLoad(url: URL, generation: Int) async {
        let outcome = await readAndParse(url: url)
        guard generation == loadGeneration else { return }
        switch outcome {
        case .loaded(let document):
            self.document = document
            self.errorMessage = nil
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        case .failed(let message):
            self.errorMessage = message
        }
    }

    /// Reads and parses the file off the main actor, so a large document
    /// never blocks the UI.
    private nonisolated func readAndParse(url: URL) async -> LoadOutcome {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let startedAt = Date()
            let source = try readString(at: url)
            let blocks = MarkdownParser.parse(source)
            let openDuration = Date().timeIntervalSince(startedAt)
            return .loaded(MarkdownDocument(
                url: url,
                source: source,
                blocks: blocks,
                openDuration: openDuration
            ))
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = Self.openableTypes
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Open Markdown File"
        panel.prompt = "Open"
        if panel.runModal() == .OK, let url = panel.url {
            load(url: url)
        }
    }

    func close() {
        document = nil
        errorMessage = nil
    }

    func reload() {
        guard let url = document?.url else { return }
        load(url: url)
    }

    func registerAsDefaultMarkdownHandlerIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.didRegisterDefaultKey) else { return }
        guard let mdType = UTType(Self.markdownUTI) else { return }
        defaults.set(true, forKey: Self.didRegisterDefaultKey)
        let bundleURL = Bundle.main.bundleURL
        Task.detached {
            try? await NSWorkspace.shared.setDefaultApplication(
                at: bundleURL,
                toOpen: mdType
            )
        }
    }

    func zoom(by step: Int) {
        let delta = 0.1 * Double(step)
        setTextScale((textScale + delta).clamped(to: Self.minScale...Self.maxScale))
    }

    func resetZoom() {
        setTextScale(1.0)
    }

    private func setTextScale(_ value: Double) {
        guard value != textScale else { return }
        textScale = value
        UserDefaults.standard.set(value, forKey: Self.textScaleKey)
    }

    private nonisolated func readString(at url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        let data = try Data(contentsOf: url)
        if let s = String(data: data, encoding: .utf8) { return s }
        if let s = String(data: data, encoding: .isoLatin1) { return s }
        if let s = String(data: data, encoding: .macOSRoman) { return s }
        return String(decoding: data, as: UTF8.self)
    }

    static let openableTypes: [UTType] = {
        let candidates: [UTType?] = [
            UTType(filenameExtension: "md"),
            UTType(filenameExtension: "markdown"),
            UTType(filenameExtension: "mdown"),
            UTType(filenameExtension: "mkdn"),
            UTType(filenameExtension: "mkd"),
            UTType(filenameExtension: "txt"),
            .plainText,
            .text
        ]
        return candidates.compactMap { $0 }
    }()
}

/// Result of an off-main document load, carried back to the main actor.
private nonisolated enum LoadOutcome {
    case loaded(MarkdownDocument)
    case failed(String)
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
