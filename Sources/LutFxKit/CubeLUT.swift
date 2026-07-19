import Foundation

/// Minimal .cube parser — enough to validate a file and drive thumbnail
/// rendering. FCP itself re-parses the installed file, so this does not need
/// to cover every vendor quirk; unknown keywords are ignored.
public struct CubeLUT {
    public var size3D: Int?
    public var size1D: Int?
    public var title: String?
    /// RGB triples in file order (red index varies fastest).
    public var values: [Float] = []

    public var isValid: Bool {
        if let n = size3D { return values.count == n * n * n * 3 }
        if let n = size1D { return values.count == n * 3 }
        return false
    }

    public static func parse(_ data: Data) throws -> CubeLUT {
        guard let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1) else {
            throw LutfxError.invalidCube("file is not text")
        }
        var lut = CubeLUT()
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(omittingEmptySubsequences: true, whereSeparator: { $0 == " " || $0 == "\t" })
            guard let first = parts.first else { continue }
            switch first.uppercased() {
            case "LUT_3D_SIZE":
                lut.size3D = parts.count > 1 ? Int(parts[1]) : nil
            case "LUT_1D_SIZE":
                lut.size1D = parts.count > 1 ? Int(parts[1]) : nil
            case "TITLE":
                lut.title = parts.dropFirst().joined(separator: " ")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            case "DOMAIN_MIN", "DOMAIN_MAX", "LUT_IN_VIDEO_RANGE", "LUT_OUT_VIDEO_RANGE":
                continue
            default:
                if let r = Float(parts[0]), parts.count >= 3,
                   let g = Float(parts[1]), let b = Float(parts[2]) {
                    lut.values.append(contentsOf: [r, g, b])
                }
            }
        }
        guard lut.isValid else {
            throw LutfxError.invalidCube("unrecognized structure (size vs. data mismatch)")
        }
        return lut
    }
}

public enum LutfxError: Error, CustomStringConvertible {
    case invalidCube(String)
    case io(String)

    public var description: String {
        switch self {
        case .invalidCube(let why): return "invalid .cube file: \(why)"
        case .io(let why): return why
        }
    }
}
