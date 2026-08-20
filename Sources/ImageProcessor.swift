import AppKit
import ImageIO
import UniformTypeIdentifiers

struct ProcessResult {
    let sourceURL: URL
    let outputURL: URL
    let originalBytes: Int
    let compressedBytes: Int
    var savings: Int { originalBytes - compressedBytes }
    var savingsPct: Double { originalBytes > 0 ? Double(savings) / Double(originalBytes) * 100 : 0 }
}

enum ProcessError: LocalizedError {
    case unreadable, noImage, encodingFailed, writeFailed(Error)
    var errorDescription: String? {
        switch self {
        case .unreadable:        return "Cannot read file"
        case .noImage:           return "Not a valid image"
        case .encodingFailed:    return "Encoding failed"
        case .writeFailed(let e): return "Write failed: \(e.localizedDescription)"
        }
    }
}

struct ImageProcessor {

    static func process(url: URL, preset: Preset, outputDir: URL) throws -> ProcessResult {
        let sourceData = try Data(contentsOf: url)
        guard let image = NSImage(data: sourceData) else { throw ProcessError.noImage }

        let resized = resizeIfNeeded(image, maxDimension: preset.maxDimension,
                                     preserveAlpha: preset.format == .png)

        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ProcessError.encodingFailed
        }

        let outData: Data?
        let ext: String

        switch preset.format {
        case .jpeg:
            outData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: preset.quality])
            ext = "jpg"
        case .png:
            outData = bitmap.representation(using: .png, properties: [:])
            ext = "png"
        }

        guard let data = outData else { throw ProcessError.encodingFailed }

        let stem = url.deletingPathExtension().lastPathComponent
        let outName = "\(stem)_\(preset.id).\(ext)"
        let outURL  = outputDir.appendingPathComponent(outName)

        do {
            try data.write(to: outURL, options: .atomic)
        } catch {
            throw ProcessError.writeFailed(error)
        }

        return ProcessResult(
            sourceURL: url,
            outputURL: outURL,
            originalBytes: sourceData.count,
            compressedBytes: data.count
        )
    }

    // MARK: - Helpers

    private static func resizeIfNeeded(_ image: NSImage, maxDimension: Int, preserveAlpha: Bool = false) -> NSImage {
        guard maxDimension > 0 else { return image }
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > CGFloat(maxDimension) else { return image }

        let scale   = CGFloat(maxDimension) / longest
        let newSize = NSSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())

        // Use CGContext with alpha when preserving transparency (PNG)
        if preserveAlpha {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let ctx = CGContext(
                data: nil,
                width: Int(newSize.width),
                height: Int(newSize.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return image }
            ctx.interpolationQuality = .high
            // Draw transparent background first
            ctx.clear(CGRect(origin: .zero, size: newSize))
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                ctx.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
            }
            if let cgResult = ctx.makeImage() {
                return NSImage(cgImage: cgResult, size: newSize)
            }
            return image
        }

        // For non-alpha formats, lockFocus is fine (white background)
        let result = NSImage(size: newSize)
        result.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
    }

    private static func encodeWithImageIO(bitmap: NSBitmapImageRep, uti: String, quality: Double) -> Data? {
        guard let cgImage = bitmap.cgImage else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, uti as CFString, 1, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(dest, cgImage, opts as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }
}

// MARK: - Formatter helpers
extension Int {
    var fileSizeString: String {
        let kb = Double(self) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        return String(format: "%.2f MB", kb / 1024)
    }
}
