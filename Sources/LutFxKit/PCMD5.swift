import Foundation
import CryptoKit

/// Hashing that matches Final Cut Pro's PCMD5/PAEMD5Value conventions.
///
/// FCP identifies a custom LUT by `PCMD5HashWithCFString(relativePath)`, where
/// `relativePath` is the file's path relative to the Custom LUTs repository
/// (e.g. "My Pack/Look.cube"). The hash is the MD5 of the UTF-16 little-endian
/// bytes of that string, and the hex form prints each 32-bit word byte-swapped
/// (i.e. words are read as little-endian uint32 and printed big-endian).
enum PCMD5 {
    static func hashHex(ofString string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf16.flatMap { [UInt8($0 & 0xff), UInt8($0 >> 8)] }))
        let bytes = Array(digest)
        var out = ""
        for word in 0..<4 {
            for i in stride(from: 3, through: 0, by: -1) {
                out += String(format: "%02x", bytes[word * 4 + i])
            }
        }
        return out
    }
}
