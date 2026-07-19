import Foundation
import CoreGraphics

/// Copies the .cube into FCP's Custom LUTs repository and writes the effect
/// template into the user's Motion Templates folder.
public struct Installer: @unchecked Sendable {
    public let category: String
    public let force: Bool
    public let dryRun: Bool
    public let makeThumbnails: Bool
    /// Optional user image the effect thumbnails are rendered from (instead
    /// of the synthetic gradient).
    public let thumbnailSource: CGImage?

    private let fm = FileManager.default

    public init(category: String, force: Bool, dryRun: Bool, makeThumbnails: Bool,
                thumbnailSource: CGImage? = nil) {
        self.category = category
        self.force = force
        self.dryRun = dryRun
        self.makeThumbnails = makeThumbnails
        self.thumbnailSource = thumbnailSource
    }

    public var lutRepositoryRoot: URL {
        fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/ProApps/Custom LUTs", isDirectory: true)
    }

    /// Prefer the folder variants that already exist (FCP creates the
    /// ".localized" flavor); fall back to creating the plain names.
    public var effectsRoot: URL {
        let movies = fm.homeDirectoryForCurrentUser.appendingPathComponent("Movies", isDirectory: true)
        let templates = ["Motion Templates.localized", "Motion Templates"]
            .map { movies.appendingPathComponent($0, isDirectory: true) }
        let templatesDir = templates.first { fm.fileExists(atPath: $0.path) } ?? templates[0]
        let effects = ["Effects.localized", "Effects"]
            .map { templatesDir.appendingPathComponent($0, isDirectory: true) }
        return effects.first { fm.fileExists(atPath: $0.path) } ?? effects[0]
    }

    public struct Result {
        public var effectName: String
        public var status: String
    }

    public func install(cubeFile: URL) throws -> Result {
        let effectName = sanitize(cubeFile.deletingPathExtension().lastPathComponent)
        let effectDir = effectsRoot
            .appendingPathComponent(category, isDirectory: true)
            .appendingPathComponent(effectName, isDirectory: true)
        let moefURL = effectDir.appendingPathComponent("\(effectName).moef")

        if fm.fileExists(atPath: moefURL.path) && !force {
            return Result(effectName: effectName, status: "skipped (already installed; use --force to overwrite)")
        }

        let cubeData = try Data(contentsOf: cubeFile)
        let lut = try CubeLUT.parse(cubeData)

        // 1. Install the .cube into the repository (dedupe by content).
        let repoDir = lutRepositoryRoot.appendingPathComponent(category, isDirectory: true)
        let (repoFile, cubeStatus) = try repositoryDestination(for: cubeFile, data: cubeData, in: repoDir)
        if !dryRun {
            try fm.createDirectory(at: repoDir, withIntermediateDirectories: true)
            if cubeStatus == .copied {
                try? fm.removeItem(at: repoFile)
                try cubeData.write(to: repoFile)
            }
        }

        // 2. The LUT reference FCP resolves: hash of the repo-relative path.
        let relPath = "\(category)/\(repoFile.lastPathComponent)"
        let hash = PCMD5.hashHex(ofString: relPath)
        let blob = ReferenceBlob.encoded(hashHex: hash, name: repoFile.deletingPathExtension().lastPathComponent)

        // 3. Write the effect template.
        if !dryRun {
            try fm.createDirectory(at: effectDir, withIntermediateDirectories: true)
            try MoefTemplate.render(lutBlob: blob).write(to: moefURL, atomically: true, encoding: .utf8)
            if makeThumbnails, lut.size3D != nil {
                _ = Thumbnail.write(lut: lut,
                                    largeURL: effectDir.appendingPathComponent("large.png"),
                                    smallURL: effectDir.appendingPathComponent("small.png"),
                                    source: thumbnailSource)
            }
        }

        let verb = dryRun ? "would install" : "installed"
        return Result(effectName: effectName,
                      status: "\(verb) (LUT \(cubeStatus == .reused ? "reused" : "copied") as \"\(relPath)\")")
    }

    enum CubeStatus { case copied, reused }

    /// Same file name + same bytes -> reuse. Same name, different bytes ->
    /// pick a numbered variant so we never silently change an existing LUT
    /// that other effects/projects may reference.
    private func repositoryDestination(for cubeFile: URL, data: Data, in repoDir: URL) throws -> (URL, CubeStatus) {
        let base = sanitize(cubeFile.deletingPathExtension().lastPathComponent)
        var candidate = repoDir.appendingPathComponent("\(base).cube")
        var suffix = 2
        while fm.fileExists(atPath: candidate.path) {
            if let existing = try? Data(contentsOf: candidate), existing == data {
                return (candidate, .reused)
            }
            candidate = repoDir.appendingPathComponent("\(base)-\(suffix).cube")
            suffix += 1
        }
        return (candidate, .copied)
    }

    private func sanitize(_ name: String) -> String {
        name.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespaces)
    }
}
