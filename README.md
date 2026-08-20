# Kompresio

> Instant image compressor for macOS — lives in your menu bar.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.2-orange?logo=swift)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-ARM64-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## What is Kompresio?

Kompresio is a lightweight macOS menu bar app that lets you compress and resize images in seconds — no Finder fumbling, no web uploads, no bloated editors. Drag images onto the drop zone (or the menu bar icon itself), pick a preset, and get optimized files instantly.

Built with native Apple frameworks — **ImageIO**, **AppKit**, and **SwiftUI** — it runs lean and takes full advantage of Apple Silicon's image processing pipeline.

---

## Features

- **Menu bar app** — always one click away, no Dock clutter
- **Drag & drop** — drop images directly onto the popover or the menu bar icon
- **5 built-in presets** — Balanced, Small, Tiny, PNG 2560, PNG 1920
- **JPEG + PNG output** — verified native encoding via Apple's ImageIO
- **Auto-resize** — scales down to the preset's max dimension (longest edge)
- **Transparency preserved** — PNG presets keep alpha channel intact
- **Live results** — shows original size → compressed size and % savings per file
- **Reveal in Finder** — one click to open the output file location
- **Custom output folder** — change destination from the footer
- **Right-click to Quit** — right-click the menu bar icon for the context menu
- **Single instance** — launching again replaces the existing instance
- **Zero dependencies** — pure Swift, no third-party libraries
- **Apple Silicon native** — compiled for `arm64`

---

## Screenshots

> Coming soon — drop a screenshot of the popover here.

---

## Requirements

| | Minimum |
|---|---|
| macOS | 14.0 Sonoma |
| Architecture | Apple Silicon (arm64) |
| Swift | 6.2+ (Xcode 16+) |

---

## Installation

### Option A — Download prebuilt app (easiest)

1. Download **Kompresio.zip** from the [latest release](https://github.com/kopipes/kompresio/releases/latest)
2. Unzip and drag **Kompresio.app** to `/Applications`
3. Right-click → **Open** on first launch to bypass Gatekeeper (ad-hoc signed, not notarized)

### Option B — Build from source

```bash
git clone https://github.com/kopipes/kompresio.git
cd kompresio
bash build.sh
open .build/Kompresio.app
```

To install permanently:

```bash
cp -r .build/Kompresio.app /Applications/
```

---

## Usage

1. Click the **↓ circle icon** in the menu bar to open the popover
2. Select a **preset** from the chip row at the top
3. **Drag one or more images** onto the drop zone
4. Watch the results appear — original size, compressed size, and savings %
5. Click the **folder icon** on any result to reveal it in Finder
6. Click the **output folder label** at the bottom to change where files are saved
7. **Right-click** the menu bar icon to quit

### Supported input formats

`JPG` · `PNG` · `WebP` · `HEIC` · `HEIF` · `GIF` · `TIFF` · `BMP`

---

## Presets

| Preset | Output | Max dimension | Quality | Transparency |
|---|---|---|---|---|
| **Balanced** | JPEG | 2560px | 75% | no |
| **Small** | JPEG | 1920px | 55% | no |
| **Tiny** | JPEG | 1280px | 35% | no |
| **PNG 2560** | PNG | 2560px | lossless | **yes** |
| **PNG 1920** | PNG | 1920px | lossless | **yes** |

Output files are named `<original>_<preset>.<ext>` and saved to `~/Desktop/Kompresio Output/` by default.

> **Note:** JPEG does not support transparency. If you convert a transparent PNG using a JPEG preset, transparent areas become white. Use PNG presets to preserve transparency.

---

## Project Structure

```
kompresio/
├── Sources/
│   ├── main.swift                  # App entry point, single-instance enforcement
│   ├── AppDelegate.swift           # NSApplicationDelegate
│   ├── StatusBarController.swift   # Menu bar icon, drag-on-icon, right-click menu
│   ├── Presets.swift               # Preset definitions
│   ├── ImageProcessor.swift        # Resize + encode engine (ImageIO / NSBitmapImageRep)
│   └── ContentView.swift           # SwiftUI popover UI + ViewModel
├── Resources/
│   └── Info.plist                  # Bundle metadata
├── build.sh                        # One-command build script (swiftc → .app bundle)
└── .gitignore
```

---

## How it Works

1. **Drag & drop** lands in `DragReceivingView` (an `NSView` subclass registered for `.fileURL` drag types) overlaid on the status bar button, or in the SwiftUI `onDrop` modifier on the popover drop zone.
2. Valid image URLs are passed to `ImageProcessor.process(url:preset:outputDir:)` which runs on a detached `Task` off the main thread.
3. `NSImage` loads the source. For JPEG, `NSBitmapImageRep` encodes at the preset quality. For PNG, a `CGContext` with `premultipliedLast` alpha preserves transparency through the resize.
4. Results (file sizes, savings %) are published back to the `@MainActor` `ContentViewModel` and rendered in a `ScrollView`.

---

## Why Apple Silicon?

Kompresio is compiled natively for `arm64` and targets macOS 14+. Image decoding and encoding via ImageIO uses Apple's hardware-accelerated media pipeline on M-series chips — faster and more power-efficient than software-based tools like `ffmpeg` or `imagemagick`.

---

## Building & Developing

No Xcode project, no SPM — just a single `swiftc` invocation.

```bash
bash build.sh        # clean + compile + bundle + ad-hoc sign
open .build/Kompresio.app
```

Re-run `bash build.sh` to rebuild from scratch after any change.

---

## Roadmap

- [ ] Custom preset editor (quality slider, max dimension)
- [ ] Batch progress indicator
- [ ] Launch at Login toggle
- [ ] Menu bar icon badge showing files processed
- [ ] Drag output result back to other apps

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Author

Built by [@kopipes](https://github.com/kopipes)
