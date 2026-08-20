import Foundation

struct Preset: Identifiable, Hashable {
    let id: String
    let name: String
    let maxDimension: Int   // longest edge in pixels (0 = no resize)
    let quality: Double     // 0.0–1.0
    let format: OutputFormat

    enum OutputFormat: String, CaseIterable {
        case heic   = "HEIC"
        case avif   = "AVIF"
        case jpeg   = "JPEG"
        case jpeg2k = "JPEG-2000"
        case png    = "PNG"
    }
}

let allPresets: [Preset] = [
    Preset(id: "web",       name: "Web",       maxDimension: 1920, quality: 0.82, format: .avif),
    Preset(id: "thumb",     name: "Thumbnail", maxDimension: 400,  quality: 0.80, format: .avif),
    Preset(id: "highres",   name: "High Res",  maxDimension: 0,    quality: 0.92, format: .heic),
    Preset(id: "social",    name: "Social",    maxDimension: 1080, quality: 0.85, format: .jpeg),
    Preset(id: "lossless",  name: "Lossless",  maxDimension: 0,    quality: 1.0,  format: .png),
]
