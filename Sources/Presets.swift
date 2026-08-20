import Foundation

struct Preset: Identifiable, Hashable {
    let id: String
    let name: String
    let maxDimension: Int   // longest edge in pixels (0 = no resize)
    let quality: Double     // 0.0–1.0 (ignored for PNG)
    let format: OutputFormat

    enum OutputFormat: String, CaseIterable {
        case jpeg = "JPEG"
        case png  = "PNG"
    }
}

let allPresets: [Preset] = [
    // JPEG tiers — convert anything to JPEG at various quality levels
    Preset(id: "high",     name: "High",     maxDimension: 0,    quality: 0.90, format: .jpeg),
    Preset(id: "balanced", name: "Balanced", maxDimension: 2560, quality: 0.75, format: .jpeg),
    Preset(id: "small",    name: "Small",    maxDimension: 1920, quality: 0.55, format: .jpeg),
    Preset(id: "tiny",     name: "Tiny",     maxDimension: 1280, quality: 0.35, format: .jpeg),
    // PNG — keeps transparency, shrinks by resizing dimensions only
    Preset(id: "png2560",  name: "PNG 2560", maxDimension: 2560, quality: 1.0,  format: .png),
    Preset(id: "png1920",  name: "PNG 1920", maxDimension: 1920, quality: 1.0,  format: .png),
]
