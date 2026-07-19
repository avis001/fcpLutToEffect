import Foundation
import CoreImage
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Renders Effects-browser thumbnails (large.png 640x360, small.png 192x108):
/// a colorful reference gradient passed through the LUT via CIColorCube.
public enum Thumbnail {
    /// `source` (if given) replaces the synthetic gradient as the image the
    /// LUT is applied to — e.g. a user-supplied screenshot of their footage.
    public static func write(lut: CubeLUT, largeURL: URL, smallURL: URL, source: CGImage? = nil) -> Bool {
        guard let base = base(source: source, width: 640, height: 360),
              let graded = apply(lut: lut, to: base) else { return false }
        return writePNG(graded, size: CGSize(width: 640, height: 360), to: largeURL)
            && writePNG(graded, size: CGSize(width: 192, height: 108), to: smallURL)
    }

    /// In-memory preview of the LUT applied to `source` (or the reference
    /// gradient when nil), for UI.
    public static func previewImage(lut: CubeLUT, source: CGImage? = nil,
                                    width: Int = 320, height: Int = 180) -> CGImage? {
        guard let base = base(source: source, width: width, height: height),
              let graded = apply(lut: lut, to: base) else { return nil }
        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        return ciContext.createCGImage(graded, from: CGRect(x: 0, y: 0, width: width, height: height))
    }

    /// Loads an image file and normalizes it to an sRGB, aspect-filled bitmap
    /// suitable as a preview/thumbnail source.
    public static func loadImage(url: URL, width: Int = 640, height: Int = 360) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(src, 0, [kCGImageSourceShouldCache: false] as CFDictionary)
        else { return nil }
        return aspectFill(image, width: width, height: height)
    }

    private static func base(source: CGImage?, width: Int, height: Int) -> CGImage? {
        guard let source else { return baseImage(width: width, height: height) }
        if source.width == width && source.height == height { return source }
        return aspectFill(source, width: width, height: height)
    }

    /// Center-crop scale into an sRGB context (also normalizes exotic color
    /// spaces/formats so CIColorCube sees plain sRGB pixels).
    private static func aspectFill(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        let scale = max(CGFloat(width) / CGFloat(image.width), CGFloat(height) / CGFloat(image.height))
        let w = CGFloat(image.width) * scale, h = CGFloat(image.height) * scale
        ctx.draw(image, in: CGRect(x: (CGFloat(width) - w) / 2, y: (CGFloat(height) - h) / 2, width: w, height: h))
        return ctx.makeImage()
    }

    // A hue sweep with a vertical white->black falloff plus a neutral gray ramp
    // along the bottom, so both color shifts and tone curves are visible.
    private static func baseImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let buf = ctx.data else { return nil }
        let px = buf.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let grayBand = height / 5
        for y in 0..<height {
            for x in 0..<width {
                let o = (y * width + x) * 4
                var r: Double, g: Double, b: Double
                if y >= height - grayBand {
                    let v = Double(x) / Double(width - 1)
                    r = v; g = v; b = v
                } else {
                    let hue = Double(x) / Double(width - 1)
                    let tone = Double(y) / Double(height - grayBand - 1) // 0 top .. 1 bottom
                    (r, g, b) = hsv(h: hue, s: min(1, tone * 2), v: min(1, (1 - tone) * 2))
                }
                px[o] = UInt8(max(0, min(255, r * 255)))
                px[o + 1] = UInt8(max(0, min(255, g * 255)))
                px[o + 2] = UInt8(max(0, min(255, b * 255)))
                px[o + 3] = 255
            }
        }
        return ctx.makeImage()
    }

    private static func hsv(h: Double, s: Double, v: Double) -> (Double, Double, Double) {
        let i = Int(h * 6) % 6
        let f = h * 6 - Double(Int(h * 6))
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        switch i {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }

    private static func apply(lut: CubeLUT, to image: CGImage) -> CIImage? {
        let input = CIImage(cgImage: image)
        guard let cubeData = colorCubeData(lut: lut) else { return input }
        let filter = CIFilter(name: "CIColorCube", parameters: [
            "inputCubeDimension": cubeData.dimension,
            "inputCubeData": cubeData.data,
            kCIInputImageKey: input,
        ])
        return filter?.outputImage ?? input
    }

    /// CIColorCube wants RGBA float32, red index fastest — same ordering as the
    /// .cube file. Dimensions above CIColorCube's max (64) are downsampled.
    private static func colorCubeData(lut: CubeLUT) -> (dimension: Int, data: Data)? {
        guard let n = lut.size3D, n >= 2 else { return nil }
        let maxDim = 64
        let outN = min(n, maxDim)
        var floats = [Float]()
        floats.reserveCapacity(outN * outN * outN * 4)
        for b in 0..<outN {
            let sb = b * (n - 1) / max(1, outN - 1)
            for g in 0..<outN {
                let sg = g * (n - 1) / max(1, outN - 1)
                for r in 0..<outN {
                    let sr = r * (n - 1) / max(1, outN - 1)
                    let idx = ((sb * n + sg) * n + sr) * 3
                    floats.append(max(0, min(1, lut.values[idx])))
                    floats.append(max(0, min(1, lut.values[idx + 1])))
                    floats.append(max(0, min(1, lut.values[idx + 2])))
                    floats.append(1)
                }
            }
        }
        return (outN, floats.withUnsafeBufferPointer { Data(buffer: $0) })
    }

    private static func writePNG(_ image: CIImage, size: CGSize, to url: URL) -> Bool {
        let ciContext = CIContext(options: [.useSoftwareRenderer: false])
        let scale = size.width / image.extent.width
        let scaled = scale == 1 ? image
            : image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cg = ciContext.createCGImage(scaled, from: CGRect(origin: .zero, size: size)),
              let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(dest, cg, nil)
        return CGImageDestinationFinalize(dest)
    }
}
