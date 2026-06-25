import SwiftUI

/// The floating ⌘F search field, overlaid at the top-trailing of the reader.
/// Return / Shift-Return step through matches; Escape closes.
struct FindBar: View {
    @Environment(FindState.self) private var find
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Find", text: queryBinding)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 190)
                .focused($fieldFocused)
                .onKeyPress(keys: [.return], phases: .down) { key in
                    if key.modifiers.contains(.shift) {
                        find.previous()
                    } else {
                        find.next()
                    }
                    return .handled
                }

            if !find.query.isEmpty {
                Text(find.statusText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 62, alignment: .trailing)
                    .monospacedDigit()
            }

            Divider().frame(height: 16)

            Button(action: find.previous) {
                Image(systemName: "chevron.up")
            }
            .help("Previous match (⇧Return)")
            .disabled(find.matches.isEmpty)

            Button(action: find.next) {
                Image(systemName: "chevron.down")
            }
            .help("Next match (return)")
            .disabled(find.matches.isEmpty)

            Button(action: find.dismiss) {
                Image(systemName: "xmark")
            }
            .help("Close (esc)")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
        .onAppear { fieldFocused = true }
        .onChange(of: find.focusRequest) { _, _ in fieldFocused = true }
        .onExitCommand { find.dismiss() }
    }

    private var queryBinding: Binding<String> {
        Binding(get: { find.query }, set: { find.setQuery($0) })
    }
}
