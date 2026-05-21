import SwiftUI

@main
struct mdreadApp: App {
    @State private var reader = ReaderState()

    var body: some Scene {
        Window("mdread", id: "main") {
            ContentView()
                .environment(reader)
                .frame(minWidth: 520, minHeight: 380)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 880, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    reader.presentOpenPanel()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Reload") {
                    reader.reload()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(reader.document == nil)

                Divider()

                Button("Close Document") {
                    reader.close()
                }
                .keyboardShortcut("w", modifiers: [.command])
                .disabled(reader.document == nil)
            }

            CommandGroup(after: .toolbar) {
                Button("Increase Text Size") {
                    reader.zoom(by: 1)
                }
                .keyboardShortcut("=", modifiers: [.command])
                .disabled(reader.document == nil)

                Button("Decrease Text Size") {
                    reader.zoom(by: -1)
                }
                .keyboardShortcut("-", modifiers: [.command])
                .disabled(reader.document == nil)

                Button("Actual Size") {
                    reader.resetZoom()
                }
                .keyboardShortcut("0", modifiers: [.command])
                .disabled(reader.document == nil)
            }
        }
    }
}
