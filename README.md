# XcodeGen

Generate the Xcode project after cloning:

```bash
brew install xcodegen   # once
xcodegen generate
open Stillreader.xcodeproj
```

Or create the project in Xcode (File → New → Multiplatform → App) and add the `Stillreader/` sources.

## Build

```bash
xcodegen generate
xcodebuild -scheme Stillreader -destination 'platform=macOS' build
xcodebuild test -scheme Stillreader -destination 'platform=macOS'
```

Open `Stillreader.xcodeproj` in Xcode to run on iOS simulator or device. Set your development team for Release builds and iCloud.

## Architecture

- **Markdown files** in iCloud (or local fallback) — subscriptions, links, read state
- **SQLite cache** — ephemeral RSS articles + FTS search
- **On-demand refresh** — client-side RSS fetch, no backend

## File layout

```
feeds/{shard}/{slug}.md
state/{shard}/{slug}.md
links/{yyyy}/{mm}/{date}-{slug}.md
.stillreader/meta.yaml
```
