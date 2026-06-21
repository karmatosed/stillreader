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
xcodebuild -scheme Stillreader -destination 'platform=macOS' build
xcodebuild test -scheme Stillreader -destination 'platform=macOS'
```

## Requirements

- Xcode 15+
- iOS 17 / macOS 14 deployment targets
