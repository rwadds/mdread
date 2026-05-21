import SwiftUI

/// A slim bar pinned below the window toolbar, reporting how long the open
/// document took to read and parse.
struct StatusBarView: View {
    let document: MarkdownDocument

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "stopwatch")
                .font(.system(size: 10, weight: .medium))
            Text(timingText)
            Spacer(minLength: 0)
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var timingText: String {
        let seconds = document.openDuration
        if seconds < 1 {
            let milliseconds = seconds * 1000
            let formatted = milliseconds < 10
                ? String(format: "%.1f", milliseconds)
                : String(format: "%.0f", milliseconds)
            return "Opened in \(formatted) ms"
        }
        return "Opened in \(String(format: "%.2f", seconds)) s"
    }
}
