import Foundation

/// Scans and manages installed LUT effects (the ones wrapping FCP's Custom LUT
/// filter). Effects from other vendors/templates are ignored so a UI built on
/// this can never delete something we didn't create.
public enum EffectLibrary {
    public struct Effect: Identifiable, Hashable {
        public var category: String
        public var name: String
        /// The effect's folder (contains the .moef and thumbnails).
        public var directory: URL
        public var thumbnail: URL?

        public var id: String { directory.path }
    }

    /// Marker that identifies a .moef as a Custom LUT wrapper (ours or any
    /// template built the same way).
    private static let lutFilterMarker = "PAELUTEffect"

    public static func installedEffects(effectsRoot: URL) -> [Effect] {
        let fm = FileManager.default
        var effects: [Effect] = []
        let categories = (try? fm.contentsOfDirectory(at: effectsRoot, includingPropertiesForKeys: [.isDirectoryKey]))
            ?? []
        for categoryDir in categories where categoryDir.hasDirectoryPath {
            let entries = (try? fm.contentsOfDirectory(at: categoryDir, includingPropertiesForKeys: [.isDirectoryKey]))
                ?? []
            for effectDir in entries where effectDir.hasDirectoryPath {
                let name = effectDir.lastPathComponent
                let moef = effectDir.appendingPathComponent("\(name).moef")
                guard fm.fileExists(atPath: moef.path),
                      let xml = try? String(contentsOf: moef, encoding: .utf8),
                      xml.contains(lutFilterMarker) else { continue }
                let thumb = effectDir.appendingPathComponent("large.png")
                effects.append(Effect(category: categoryDir.lastPathComponent,
                                      name: name,
                                      directory: effectDir,
                                      thumbnail: fm.fileExists(atPath: thumb.path) ? thumb : nil))
            }
        }
        return effects.sorted {
            ($0.category.localizedLowercase, $0.name.localizedLowercase)
                < ($1.category.localizedLowercase, $1.name.localizedLowercase)
        }
    }

    /// Removes the effect's folder (and its now-empty category folder). The
    /// .cube in the Custom LUTs repository is intentionally left alone —
    /// existing projects may still reference it.
    public static func uninstall(_ effect: Effect) throws {
        let fm = FileManager.default
        try fm.removeItem(at: effect.directory)
        let categoryDir = effect.directory.deletingLastPathComponent()
        if let remaining = try? fm.contentsOfDirectory(atPath: categoryDir.path),
           remaining.filter({ $0 != ".DS_Store" }).isEmpty {
            try? fm.removeItem(at: categoryDir)
        }
    }
}
