# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`mdread` is a SwiftUI **macOS** app (SDK `macosx`, deployment target 26.5, bundle id `app.product.mdread`) written in Swift, targeting Apple Silicon Macs. It is a single-document Markdown reader: the user opens one `.md` file at a time and the app renders it in a beautiful, easy-to-read typeface.

**Intended behavior (to be implemented):**
- Open a `.md` file via **File ▸ Open…** (`⌘O`) **or** by **dragging-and-dropping** the file onto the app window / Dock icon.
- Only one Markdown file is open at a time for now (single-window, single-document — replace the current content when a new file is opened rather than spawning windows or tabs).
- Render the Markdown with a polished, readable font and typographic defaults (good line-height, generous margins, proper heading hierarchy). Aim for "long-form reading" quality, not editor chrome.

At the time of writing the repo is still the Xcode scaffold (`mdreadApp.swift` + `ContentView.swift` showing "Hello, world!") — there is no feature code yet, no tests target, no Swift Package dependencies, and no README/CI config.

The Xcode project lives at `mdread.xcodeproj/`. The git repo root is this same directory (`mdread/`), so when running `git`, `xcodebuild`, etc. the working directory is the one containing both `mdread/` (source folder) and `mdread.xcodeproj/`.

## Build / Run / Test

```sh
# Build (Debug)
xcodebuild -project mdread.xcodeproj -scheme mdread -configuration Debug build

# Run the app from the built product
open "$(xcodebuild -project mdread.xcodeproj -scheme mdread -configuration Debug -showBuildSettings | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{print $2}')/mdread.app"

# Clean
xcodebuild -project mdread.xcodeproj -scheme mdread clean
```

There is no test target yet. Once one is added, run with:
```sh
xcodebuild -project mdread.xcodeproj -scheme mdread -destination 'platform=macOS' test
# Single test: append -only-testing:mdreadTests/SomeTests/testFoo
```

There is no linter configured (no SwiftLint/SwiftFormat); Xcode's built-in Clang/Swift warnings are the only static checks.

## Project configuration — things that are easy to miss

- **Synchronized file group (`PBXFileSystemSynchronizedRootGroup`).** New `.swift` files dropped anywhere inside the `mdread/` source folder are picked up automatically by Xcode — **do not** hand-edit `project.pbxproj` to add files. Conversely, deleting a file from disk removes it from the target.
- **Main-actor-by-default.** Build settings set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Treat everything as `@MainActor` unless explicitly annotated otherwise; mark long-running work `nonisolated` / move it off the main actor deliberately.
- **App Sandbox + Hardened Runtime are on.** `ENABLE_APP_SANDBOX = YES`, `ENABLE_HARDENED_RUNTIME = YES`, `ENABLE_USER_SELECTED_FILES = readonly`. File access is limited to user-picked files in read-only mode by default. If a feature needs network, write access, Bookmarks, etc., the corresponding entitlement must be added (the generated `.entitlements` is managed by `GENERATE_INFOPLIST_FILE = YES` / Xcode capabilities — adjust via the target's Signing & Capabilities pane rather than hand-editing).
- **No `Info.plist` on disk.** `GENERATE_INFOPLIST_FILE = YES` — Info.plist keys are set via `INFOPLIST_KEY_*` build settings in `project.pbxproj`, not a checked-in plist file.
- **Signing.** Automatic signing with team `GBJ45WLDDD`. Builds on a different machine will need either that team or a signing override (`CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` for local-only builds).
