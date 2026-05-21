# mdread

A minimalist macOS Markdown reader. Open a `.md` file and read it in a clean,
serif typeface designed for long-form reading — no editor chrome, no rendered
HTML soup, just text laid out the way a book would lay it out.

## Features

- **Open** a Markdown file with **`⌘O`** or by **dragging it onto the window**.
- **Beautiful typography** — New York serif body, hierarchical headings, a
  reading column that doesn't stretch past about 70 characters per line.
- **Adjustable text size** — `⌘+` / `⌘−` to step the font up or down, `⌘0` to
  reset. Also available as `−` / `%` / `+` controls in the window toolbar.
- **Live reload** — re-read the open file at any time with `⌘R`. Edit in your
  favourite editor, read here.
- **Single document, single window** — open a new file and it replaces what's
  on screen; no tab clutter.
- **Light and dark mode** — adapts to the system appearance automatically.

### What it renders

- ATX headings (`#` through `######`)
- Paragraphs with inline `**bold**`, `*italic*`, `` `code` ``, `~~strike~~`,
  `[links](https://...)` and autolinks
- Fenced code blocks (` ``` ` and `~~~`), with an optional language label
- Block quotes (`>` prefix)
- Unordered (`-`, `*`, `+`) and ordered (`1.`, `2.`, …) lists
- Horizontal rules (`---`, `***`, `___`)

### What it doesn't (yet)

- Inline images and image blocks
- Tables
- Nested lists and task-list checkboxes
- Setext headings (`===` / `---` underlines)
- HTML passthrough

These are on the list, not in the box.

## Requirements

- macOS 26.5 (Tahoe) or later, Apple Silicon
- Xcode 26.5+ to build from source

## Build & run

```sh
# Build (Debug)
xcodebuild -project mdread.xcodeproj -scheme mdread -configuration Debug build

# Launch the built app
open "$(xcodebuild -project mdread.xcodeproj -scheme mdread -configuration Debug -showBuildSettings | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{print $2}')/mdread.app"

# Clean
xcodebuild -project mdread.xcodeproj -scheme mdread clean
```

Or just open `mdread.xcodeproj` in Xcode and hit Run.

A small `sample.md` lives at the repo root — drag it onto the window to take
the typography for a spin.

## Project layout

```
mdread/
├── mdread.xcodeproj/          Xcode project
└── mdread/                    Swift sources (auto-picked up; no pbxproj edits)
    ├── mdreadApp.swift        App scene + menu commands
    ├── ContentView.swift      Document view + drag-and-drop + toolbar
    ├── ReaderState.swift      Observable app state + file loading
    ├── MarkdownDocument.swift Loaded document model
    ├── MarkdownBlock.swift    Block-level AST
    ├── MarkdownParser.swift   Block-level parser
    ├── InlineMarkdown.swift   Inline parser (AttributedString) + styling
    ├── MarkdownView.swift     SwiftUI renderer + typography
    └── EmptyStateView.swift   No-document state + drop overlay
```

No third-party dependencies — everything runs on Foundation + SwiftUI +
AppKit.

## License

MIT (or whatever you'd prefer — add a `LICENSE` file before sharing).
