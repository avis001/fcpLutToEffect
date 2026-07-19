import Foundation

/// Builds the serialized custom-parameter channel value for PAELUTEffect's
/// LUT reference parameter (parameter id 3).
///
/// Wire format (as produced by OZChannelBlindData::encodeObjectToData and the
/// channel keypoint serializer, then text-encoded with OzBase64):
///   [UInt64 big-endian payload length][0x2a][payload]
/// where payload is a secure NSKeyedArchiver plist with two root keys:
///   "BlindDataObject" -> NSData (see below)
///   "DataIsLegacy"    -> false
/// and BlindDataObject is itself a keyed archive holding the plugin's value
/// object under the key "Custom Data" (unarchived by OZFxPlugParameterHandler
/// with decodeObjectOfClass:[plugin classForCustomParameterID:] — NSString for
/// PAELUTEffect's parameter 3).
enum ReferenceBlob {
    static func encoded(hashHex: String, name: String) -> String {
        let referenceString = "\(hashHex):\(name)"

        let inner = NSKeyedArchiver(requiringSecureCoding: true)
        inner.outputFormat = .binary
        inner.encode(referenceString as NSString, forKey: "Custom Data")
        inner.finishEncoding()

        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.outputFormat = .binary
        // NSData(data:) forces a plain immutable NSData so the archiver stores
        // it as a data primitive, exactly like FCP's own writer.
        archiver.encode(NSData(data: inner.encodedData), forKey: "BlindDataObject")
        archiver.encode(NSNumber(value: false), forKey: "DataIsLegacy")
        archiver.finishEncoding()
        let payload = archiver.encodedData

        var framed = Data()
        var len = UInt64(payload.count).bigEndian
        withUnsafeBytes(of: &len) { framed.append(contentsOf: $0) }
        framed.append(0x2a)
        framed.append(payload)
        return OzBase64.encode(framed)
    }
}
