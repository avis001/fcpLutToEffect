import Foundation
import CoreGraphics
import LutFxKit

let usage = """
lutfx — install .cube LUTs as individual Final Cut Pro effects

USAGE:
  lutfx <path-to-.cube-or-folder> [options]

OPTIONS:
  --category <name>   Effects-browser category / LUT folder name
                      (default: the input folder's name, or "LUTs" for a single file)
  --force             Overwrite effects that already exist
  --dry-run           Show what would happen without writing anything
  --no-thumbnails     Skip generating effect thumbnails
  --thumbnail-image <path>
                      Render effect thumbnails from this image (e.g. a
                      screenshot of your footage) instead of the built-in
                      gradient
  --list-installed    List installed LUT effects and exit (no input path needed)
  -h, --help          Show this help

Each .cube file becomes one effect in Final Cut Pro's Effects browser under the
chosen category. The LUT itself is copied into FCP's Custom LUTs repository
(~/Library/Application Support/ProApps/Custom LUTs/<category>/). Restart Final
Cut Pro after installing.
"""

var args = Array(CommandLine.arguments.dropFirst())
var categoryArg: String?
var force = false
var dryRun = false
var thumbnails = true
var thumbnailImagePath: String?
var inputPath: String?

while !args.isEmpty {
    let arg = args.removeFirst()
    switch arg {
    case "--category":
        guard !args.isEmpty else { fail("--category requires a value") }
        categoryArg = args.removeFirst()
    case "--force": force = true
    case "--dry-run": dryRun = true
    case "--no-thumbnails": thumbnails = false
    case "--thumbnail-image":
        guard !args.isEmpty else { fail("--thumbnail-image requires a path") }
        thumbnailImagePath = args.removeFirst()
    case "--list-installed":
        let root = Installer(category: "", force: false, dryRun: true, makeThumbnails: false).effectsRoot
        let effects = EffectLibrary.installedEffects(effectsRoot: root)
        if effects.isEmpty {
            print("No installed LUT effects found in \(root.path)")
        } else {
            var lastCategory = ""
            for effect in effects {
                if effect.category != lastCategory {
                    print("\(effect.category)/")
                    lastCategory = effect.category
                }
                print("  \(effect.name)")
            }
        }
        exit(0)
    case "-h", "--help":
        print(usage)
        exit(0)
    default:
        if arg.hasPrefix("-") { fail("unknown option \(arg)") }
        guard inputPath == nil else { fail("multiple input paths given") }
        inputPath = arg
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("error: \(message)\n\n\(usage)\n".data(using: .utf8)!)
    exit(1)
}

guard let inputPath else { fail("no input path given") }
let input = URL(fileURLWithPath: (inputPath as NSString).expandingTildeInPath).standardizedFileURL
let fm = FileManager.default
var isDir: ObjCBool = false
guard fm.fileExists(atPath: input.path, isDirectory: &isDir) else {
    fail("no such file or directory: \(input.path)")
}

var cubeFiles: [URL] = []
if isDir.boolValue {
    if let e = fm.enumerator(at: input, includingPropertiesForKeys: nil) {
        for case let url as URL in e where url.pathExtension.lowercased() == "cube" {
            cubeFiles.append(url)
        }
    }
    cubeFiles.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
} else {
    guard input.pathExtension.lowercased() == "cube" else { fail("not a .cube file: \(input.path)") }
    cubeFiles = [input]
}

guard !cubeFiles.isEmpty else { fail("no .cube files found in \(input.path)") }

let category = categoryArg ?? (isDir.boolValue ? input.lastPathComponent : "LUTs")
var thumbnailSource: CGImage?
if let thumbnailImagePath {
    let imageURL = URL(fileURLWithPath: (thumbnailImagePath as NSString).expandingTildeInPath)
    thumbnailSource = Thumbnail.loadImage(url: imageURL)
    guard thumbnailSource != nil else { fail("could not read image: \(imageURL.path)") }
}

let installer = Installer(category: category, force: force, dryRun: dryRun,
                          makeThumbnails: thumbnails, thumbnailSource: thumbnailSource)

print("Installing \(cubeFiles.count) LUT\(cubeFiles.count == 1 ? "" : "s") into category \"\(category)\"\(dryRun ? " (dry run)" : "")")
print("  effects:  \(installer.effectsRoot.path)/\(category)/")
print("  luts:     \(installer.lutRepositoryRoot.path)/\(category)/")
print("")

var ok = 0, failed = 0
for cube in cubeFiles {
    do {
        let result = try installer.install(cubeFile: cube)
        print("  ✓ \(result.effectName): \(result.status)")
        ok += 1
    } catch {
        print("  ✗ \(cube.lastPathComponent): \(error)")
        failed += 1
    }
}

print("")
print("Done: \(ok) installed\(failed > 0 ? ", \(failed) failed" : "").")
if !dryRun && ok > 0 {
    print("Restart Final Cut Pro, then look in Effects browser → \(category).")
}
exit(failed > 0 ? 1 : 0)
