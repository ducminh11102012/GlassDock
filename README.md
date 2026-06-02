# GlassDock

GlassDock is a native macOS AppKit application that replaces the visible system Dock with a floating glassmorphism dock and adds a transparent Menu Bar overlay. It is designed for machines where GPU-accelerated Apple blur components are unreliable, so it intentionally avoids `NSVisualEffectView`, SwiftUI, and third-party dependencies.

## Features

- Floating custom dock with a fully transparent background so only Dock icons, separators, and running indicators are visible.
- Transparent Menu Bar illusion by drawing the matching wallpaper slice behind real menu bar text/icons.
- Automatic sync with the real macOS Dock by watching `~/Library/Preferences/com.apple.dock.plist` via `kqueue`.
- Running app indicators, app activation/launching, Finder reveal, hide, quit, tooltips, and hover magnification.
- No SIP patching and no private frameworks.

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later
- App Sandbox disabled

## Build locally

```bash
xcodebuild \
  -project GlassDock.xcodeproj \
  -scheme GlassDock \
  -configuration Release \
  -destination 'platform=macOS,arch=x86_64' \
  ARCHS=x86_64 \
  build
```

The app hides the system Dock while running and restores it on termination. CI also builds the x86_64 app and uploads `GlassDock.zip` as a workflow artifact.

## Visual behavior

GlassDock intentionally does **not** draw a rounded Dock plate, blur, gloss, border, or shadow. The Dock panel is transparent, matching the Apple Dock icon row behavior while allowing the wallpaper to show through behind the icons.
