# Stillreader

A calm, monochrome RSS reader for iOS. Subscriptions and read state live in Markdown on iCloud Drive; articles are cached locally with on-demand refresh.

**v1.0** — iPhone + iPad (no Mac app, no GitHub sync yet).

## Setup

```bash
brew install xcodegen   # once
xcodegen generate
open Stillreader.xcodeproj
```

Set your **Development Team** in Xcode for device builds, iCloud, and the share extension.

## Build & test

```bash
xcodegen generate

# Simulator
xcodebuild -scheme Stillreader \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

xcodebuild test -scheme Stillreader \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Release (device)
xcodebuild -scheme Stillreader \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build
```

Archive for TestFlight: **Product → Archive** in Xcode (Release, valid signing).

## v1 features

- RSS inbox with read / read-later / tag swipe actions
- Group inbox by feed; read-later section
- In-app reader (excerpt + full article WebView)
- OPML import (file picker + paste)
- Saved links + share extension
- iCloud Drive storage with local fallback
- iPad three-column layout (sidebar · list · detail)
- Dark-first calm monochrome UI

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
