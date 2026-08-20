# Kompresio

> Instant image converter & compressor for macOS — lives in your menu bar.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6.2-orange?logo=swift)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-ARM64-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## What is Kompresio?

Kompresio is a lightweight macOS menu bar app that lets you compress and convert images in seconds — no Finder fumbling, no web uploads, no bloated editors. Drag images onto the drop zone (or the menu bar icon itself), pick a preset, and get optimized files instantly on your Desktop.

Built with native Apple frameworks — **ImageIO**, **AppKit**, and **SwiftUI** — it runs lean and takes full advantage of Apple Silicon's image processing pipeline for fast WebP and HEIC encoding.

---

## Features

- **Menu bar app** — always one click away, no Dock clutter
- **Drag & drop** — drop images directly onto the popover or the menu bar icon
- **5 built-in presets** — Web, Thumbnail, High Res, Social, Lossless
- **WebP, JPEG, HEIC, PNG output** — native encoding via Apple's ImageIO
- **Auto-resize** — scales down to the preset's max dimension (longest edge)
- **Live results** — shows original size → compressed size and % savings per file
- **Reveal in Finder** — one click to open the output file location
- **Custom output folder** — change destination from the footer
- **Zero dependencies** — pure Swift, no third-party libraries
- **Apple Silicon native** — compiled for `arm64`, fast and efficient

---

## Screenshots

> Coming soon — drop a screenshot of the popover here.

---

## Requirements

| | Minimum |
|---|---|
| macOS | 14.0 Sonoma |
| Architecture | Apple Silicon (arm64) |
| Xcode / Swift | Swift 6.2+ (Xcode 16+) |

---

## Installation

### Option A — Build from source (recommended)

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

### Option B — Drag to Applications after building

After running `build.sh`, drag `.build/Kompresio.app` into your `/Applications` folder.

---

## Usage

1. Click the **↓ circle icon** in the menu bar to open the popover
2. Select a **preset** from the chip row at the top
3. **Drag one or more images** onto the drop zone
4. Watch the results appear — original size, compressed size, and savings %
5. Click the **folder icon** on any result to reveal it in Finder
6. Click the **output folder label** at the bottom to change where files are saved

### Supported input formats

`JPG` · `PNG` · `WebP` · `HEIC` · `HEIF` · `GIF` · `TIFF` · `BMP`

---

## Presets

| Preset | Max dimension | Output format | Quality |
|---|---|---|---|
| **Web** | 1920px | WebP | 82% |
| **Thumbnail** | 400px | WebP | 80% |
| **High Res** | no resize | WebP | 92% |
| **Social** | 1080px | JPEG | 85% |
| **Lossless** | no resize | PNG | 100% |

Output files are named `<original>_<preset>.<ext>` and saved to `~/Desktop/Kompresio Output/` by default.

---

## Project Structure

```
kompresio/
├── Sources/
│   ├── main.swift                  # App entry point
│   ├── AppDelegate.swift           # NSApplicationDelegate
│   ├── StatusBarController.swift   # Menu bar icon + drag-on-icon support
│   ├── Presets.swift               # Preset definitions
│   ├── ImageProcessor.swift        # ImageIO-based resize + encode engine
│   └── ContentView.swift           # SwiftUI popover UI + ViewModel
├── Resources/
│   └── Info.plist                  # Bundle metadata
├── build.sh                        # Build script (swiftc → .app bundle)
└── .gitignore
```

---

## How it Works

1. **Drag & drop** lands in `DragReceivingView` (an `NSView` subclass registered for `.fileURL` drag types) overlaid on the status bar button, or in the SwiftUI `onDrop` modifier on the popover drop zone.
2. Valid image URLs are passed to `ImageProcessor.process(url:preset:outputDir:)` which runs on a detached `Task` (off the main thread).
3. `NSImage` loads the source, `NSBitmapImageRep` is used for JPEG output, and **CoreGraphics `CGImageDestination`** handles WebP and HEIC encoding via ImageIO — the same pipeline used by Photos and Preview.
4. Results (file sizes, savings %) are published back to the `@MainActor` `ContentViewModel` and rendered in a `ScrollView` list.

---

## Why Apple Silicon?

Apple's ImageIO framework uses hardware-accelerated encoders on M-series chips for WebP and HEIC. This means encoding is faster and uses far less CPU/battery than software-based tools (like `libwebp` or `ffmpeg`). Kompresio is compiled natively for `arm64` and targets macOS 14+ to ensure full access to these codecs.

---

## Building & Developing

The build is a single `swiftc` invocation — no SPM, no Xcode project file needed.

```bash
bash build.sh        # compiles + bundles + ad-hoc signs
open .build/Kompresio.app
```

To iterate quickly, just re-run `bash build.sh` — it cleans and rebuilds from scratch each time.

---

## Roadmap

- [ ] Custom preset editor (quality slider, format picker, max dimension)
- [ ] Batch progress indicator
- [ ] Menu bar icon badge showing files processed
- [ ] Launch at Login toggle
- [ ] AVIF output support (macOS 16+)
- [ ] Drag output result back to other apps

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Author

Built by [@kopipes](https://github.com/kopipes)
