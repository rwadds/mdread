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
- **Find in page** — `⌘F` opens a floating search field; `⌘G` / `⇧⌘G` (or
  `return` / `⇧return`) step through matches and `esc` closes. Case- and
  diacritic-insensitive, with a live "N of M" count.
- **Copy code blocks** — hover any fenced code block and click **Copy** to put
  its contents on the clipboard. Long lines wrap to the column instead of
  scrolling sideways.
- **Live reload** — re-read the open file at any time with `⌘R`. Edit in your
  favourite editor, read here.
- **Single document, single window** — open a new file and it replaces what's
  on screen; no tab clutter.
- **Light and dark mode** — adapts to the system appearance automatically.
- **Open timing** — a slim status bar reports how long the file took to read.

### What it renders

- ATX and Setext headings (`#` through `######`, or `===` / `---` underlines)
- Paragraphs with inline `**bold**`, `*italic*`, `` `code` ``, `~~strike~~`,
  `[links](https://...)` and autolinks
- Fenced code blocks (` ``` ` and `~~~`), with an optional language label, a
  hover **Copy** button, and soft-wrapped long lines
- Block quotes (`>` prefix)
- Unordered, ordered, and nested lists, plus `[ ]` / `[x]` task lists
- Tables, with per-column alignment
- Inline images and image blocks — local files and remote URLs
- Horizontal rules (`---`, `***`, `___`)
- Raw HTML, passed through as plain text with tags stripped

That covers CommonMark plus the common GitHub-Flavored extensions.

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

## Sample & test documents

Drag any of these (all at the repo root) onto the window to exercise the
renderer:

| File | Exercises |
|------|-----------|
| `sample.md`      | Typography showcase — a good first drag |
| `test-500kb.md`  | Large-document scrolling and parse performance |
| `test-html.md`   | Raw-HTML passthrough |
| `test-images.md` | Inline and block images (local + remote) |
| `test-lists.md`  | Ordered, unordered, nested, and task lists |
| `test-setext.md` | Setext (`===` / `---`) headings |
| `test-tables.md` | Tables with per-column alignment |

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
    ├── HTMLText.swift         Raw-HTML passthrough (tags stripped to text)
    ├── MarkdownView.swift     SwiftUI renderer + typography + code copy
    ├── FindState.swift        Find model — match indexing + highlighting
    ├── FindBar.swift          Floating ⌘F search field
    ├── StatusBarView.swift    Open-timing status bar
    └── EmptyStateView.swift   No-document state + drop overlay
```

No third-party dependencies — everything runs on Foundation + SwiftUI +
AppKit.

## License

MIT — see [`LICENSE.md`](LICENSE.md).
