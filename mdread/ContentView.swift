import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(ReaderState.self) private var reader
    @Environment(\.colorScheme) private var colorScheme
    @State private var isDropTargeted = false

    var body: some View {
        Group {
            if let document = reader.document {
                MarkdownView(blocks: document.blocks, textScale: reader.textScale)
                    .id(document.id)
                    .navigationTitle(document.title)
                    .toolbar { zoomToolbar }
            } else {
                EmptyStateView(onOpen: reader.presentOpenPanel)
                    .navigationTitle("mdread")
            }
        }
        .overlay {
            if isDropTargeted {
                DropOverlay()
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .onOpenURL { url in
            guard url.isFileURL else { return }
            reader.load(url: url)
        }
        .task {
            reader.registerAsDefaultMarkdownHandlerIfNeeded()
            applyDockIcon(for: colorScheme)
        }
        .onChange(of: colorScheme) { _, newScheme in
            applyDockIcon(for: newScheme)
        }
        .alert(
            "Couldn't open file",
            isPresented: Binding(
                get: { reader.errorMessage != nil },
                set: { if !$0 { reader.errorMessage = nil } }
            ),
            presenting: reader.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { reader.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    @ToolbarContentBuilder
    private var zoomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                reader.zoom(by: -1)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .help("Decrease text size (⌘−)")
            .disabled(reader.textScale <= ReaderState.minScale + 0.001)

            Text(zoomLabel)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44)
                .onTapGesture { reader.resetZoom() }
                .help("Reset text size (⌘0)")

            Button {
                reader.zoom(by: 1)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .help("Increase text size (⌘+)")
            .disabled(reader.textScale >= ReaderState.maxScale - 0.001)
        }
    }

    private var zoomLabel: String {
        "\(Int((reader.textScale * 100).rounded()))%"
    }

    private func applyDockIcon(for scheme: ColorScheme) {
        // The bundle's static icon is the dark variant. Override with the light
        // image only while the system is in Light mode and the app is running.
        if scheme == .light, let light = NSImage(named: "AppIconLight") {
            NSApp.applicationIconImage = light
        } else {
            NSApp.applicationIconImage = nil
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        let typeIdentifier = UTType.fileURL.identifier
        guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { return false }
        provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
            guard
                let data,
                let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true)
            else { return }
            Task { @MainActor in
                reader.load(url: url)
            }
        }
        return true
    }
}

#Preview("Empty") {
    ContentView()
        .environment(ReaderState())
        .frame(width: 720, height: 600)
}
