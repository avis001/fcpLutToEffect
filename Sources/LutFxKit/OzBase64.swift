import Foundation

/// Motion/Ozone's text encoding for binary channel data (PCAsciiStream):
/// base64 bit packing with the custom alphabet "*-0…9A…Za…z", no padding.
enum OzBase64 {
    static let alphabet = Array("*-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")

    static func encode(_ data: Data) -> String {
        var out = String()
        out.reserveCapacity((data.count * 4 + 2) / 3)
        var acc = 0, bits = 0
        for byte in data {
            acc = (acc << 8) | Int(byte)
            bits += 8
            while bits >= 6 {
                bits -= 6
                out.append(alphabet[(acc >> bits) & 0x3f])
            }
        }
        if bits > 0 {
            out.append(alphabet[(acc << (6 - bits)) & 0x3f])
        }
        return out
    }
}
