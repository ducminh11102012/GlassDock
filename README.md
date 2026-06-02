# GlassDock

GlassDock is a native macOS AppKit application that replaces the visible system Dock with a floating glassmorphism dock and adds a transparent Menu Bar overlay. It is designed for machines where GPU-accelerated Apple blur components are unreliable, so it intentionally avoids `NSVisualEffectView`, SwiftUI, and third-party dependencies.

## Features

- Floating custom dock with an Apple-like translucent shelf so the wallpaper remains visible behind the icons.
- Fully transparent Menu Bar replacement that draws the wallpaper slice and redraws Apple-like menu/status text over it.
- Automatic sync with the real macOS Dock by watching `~/Library/Preferences/com.apple.dock.plist` via `kqueue`, with Finder always pinned first like Apple's Dock.
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

GlassDock draws a very light, translucent Dock shelf using only `NSView.draw(_:)`, alpha compositing, gradients, and strokes. It intentionally does not use `NSVisualEffectView` or SwiftUI blur, so the Dock should look like Apple's Dock glass while still letting the wallpaper show through clearly behind the icons.

For the Menu Bar, GlassDock places a non-interactive replacement panel above the real system menu bar. The panel draws the exact wallpaper slice for a fully transparent background, then redraws Apple-like left menu labels and right status/time text while passing mouse clicks through to the real menu bar underneath.
