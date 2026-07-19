import SwiftUI
import LutFxKit

struct LutItem: Identifiable {
    enum State {
        case pending
        case ready
        case invalid(String)
        case installing
        case installed(String)
        case failed(String)
    }

    let url: URL
    var state: State = .pending
    var preview: CGImage?
    var sizeLabel: String = ""

    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }

    var isInstallable: Bool {
        switch state {
        case .ready, .failed: return true
        default: return false
        }
    }
}

/// CGImage is immutable; box it so it can hop across task boundaries without
/// sendability warnings.
struct ImageBox: @unchecked Sendable {
    let image: CGImage
}

@MainActor
final class AppModel: ObservableObject {
    // Install tab
    @Published var items: [LutItem] = []
    @Published var category = "LUTs"
    @Published var overwrite = false
    @Published var isInstalling = false
    @Published var finishedInstall = false
    /// User-chosen screenshot the previews/thumbnails are rendered on
    /// (nil = the synthetic gradient).
    @Published var previewSource: CGImage?

    // Manage tab
    @Published var installed: [EffectLibrary.Effect] = []

    var installableCount: Int { items.filter(\.isInstallable).count }

    // MARK: - Adding LUTs

    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "tiff", "tif", "webp", "bmp"]

    func addURLs(_ urls: [URL]) {
        finishedInstall = false
        var cubeFiles: [URL] = []
        let fm = FileManager.default
        for url in urls {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if !isDir.boolValue, Self.imageExtensions.contains(url.pathExtension.lowercased()) {
                setPreviewImage(from: url)
                continue
            }
            if isDir.boolValue {
                if category == "LUTs" || category.isEmpty {
                    category = url.lastPathComponent
                }
                if let e = fm.enumerator(at: url, includingPropertiesForKeys: nil) {
                    for case let f as URL in e where f.pathExtension.lowercased() == "cube" {
                        cubeFiles.append(f)
                    }
                }
            } else if url.pathExtension.lowercased() == "cube" {
                cubeFiles.append(url)
            }
        }
        let existing = Set(items.map(\.url))
        let fresh = cubeFiles
            .filter { !existing.contains($0) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        items.append(contentsOf: fresh.map { LutItem(url: $0) })
        for url in fresh {
            Task { await self.prepare(url) }
        }
    }

    /// Parse the cube and render its preview off the main thread.
    private func prepare(_ url: URL) async {
        struct Prepared {
            var preview: ImageBox?
            var sizeLabel: String
            var error: String?
        }
        let source = previewSource.map(ImageBox.init)
        let result: Prepared = await Task.detached(priority: .userInitiated) {
            do {
                let lut = try CubeLUT.parse(try Data(contentsOf: url))
                let label = lut.size3D.map { "\($0)\u{00B3}" } ?? lut.size1D.map { "1D \($0)" } ?? ""
                let preview = lut.size3D != nil
                    ? Thumbnail.previewImage(lut: lut, source: source?.image, width: 192, height: 108)
                    : nil
                return Prepared(preview: preview.map(ImageBox.init), sizeLabel: label, error: nil)
            } catch {
                return Prepared(preview: nil, sizeLabel: "", error: "\(error)")
            }
        }.value
        guard let index = items.firstIndex(where: { $0.url == url }) else { return }
        items[index].preview = result.preview?.image
        items[index].sizeLabel = result.sizeLabel
        items[index].state = result.error.map { .invalid($0) } ?? .ready
    }

    func clear() {
        items.removeAll()
        finishedInstall = false
    }

    // MARK: - Preview source image

    func setPreviewImage(from url: URL) {
        Task {
            let loaded = await Task.detached(priority: .userInitiated) {
                Thumbnail.loadImage(url: url, width: 640, height: 360).map(ImageBox.init)
            }.value
            guard let loaded else { return }
            previewSource = loaded.image
            reRenderPreviews()
        }
    }

    func clearPreviewImage() {
        previewSource = nil
        reRenderPreviews()
    }

    private func reRenderPreviews() {
        for index in items.indices {
            if case .invalid = items[index].state { continue }
            items[index].state = .pending
            items[index].preview = nil
        }
        for item in items {
            Task { await self.prepare(item.url) }
        }
    }

    // MARK: - Installing

    func installAll() async {
        guard !isInstalling else { return }
        isInstalling = true
        finishedInstall = false
        let installer = Installer(category: sanitizedCategory, force: overwrite,
                                  dryRun: false, makeThumbnails: true,
                                  thumbnailSource: previewSource)
        for index in items.indices where items[index].isInstallable {
            items[index].state = .installing
            let url = items[index].url
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try installer.install(cubeFile: url)
                }.value
                items[index].state = .installed(result.status)
            } catch {
                items[index].state = .failed("\(error)")
            }
        }
        isInstalling = false
        finishedInstall = true
        refreshInstalled()
    }

    var sanitizedCategory: String {
        let trimmed = category.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "LUTs" : trimmed
    }

    // MARK: - Manage tab

    var effectsRoot: URL {
        Installer(category: "", force: false, dryRun: true, makeThumbnails: false).effectsRoot
    }

    func refreshInstalled() {
        let root = effectsRoot
        Task {
            let effects = await Task.detached {
                EffectLibrary.installedEffects(effectsRoot: root)
            }.value
            self.installed = effects
        }
    }

    func uninstall(_ effect: EffectLibrary.Effect) {
        do {
            try EffectLibrary.uninstall(effect)
            installed.removeAll { $0.id == effect.id }
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
