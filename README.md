# lutfx — .cube LUTs → Final Cut Pro effects

A Swift CLI that batch-converts `.cube` LUT files into individual Final Cut Pro
effects. Each LUT becomes its own effect in the Effects browser — drag it onto a
clip and it's applied, no Custom LUT popup navigation needed.

No Motion, no FxPlug plugin, no code signing: each effect is a generated Motion
template (`.moef`) that wraps FCP's own built-in **Custom LUT** filter
(`PAELUTEffect`) with the LUT pre-selected.

## Install

Via Homebrew (universal binary, macOS 13+):

```sh
brew install avis001/tap/lutfx
```

Or build from source:

```sh
swift build -c release
```

## The app

A SwiftUI companion app wraps the same engine: drag `.cube` files or folders
into the window, see a live preview of every LUT before installing, and manage
(or uninstall) previously installed effects from the Manage tab. Drop in a
screenshot of your own footage (JPEG/PNG/HEIC) and every preview — and the
installed effect thumbnails — render on your image instead of the reference
gradient.

```sh
Scripts/make-app.sh          # builds dist/LutFx.app (ad-hoc signed)
open dist/LutFx.app
```

The app bundle is currently ad-hoc signed — fine for building on your own
machine; public distribution needs a Developer ID + notarization (see the
roadmap in AGENTS.md).

The binary is self-contained at `.build/release/lutfx`. Optionally put it on
your PATH so you can run `lutfx` from anywhere:

```sh
sudo cp .build/release/lutfx /usr/local/bin/
```

## Usage

```sh
lutfx <path-to-.cube-or-folder> [options]
```

Point it at a folder and every `.cube` inside (including subfolders) becomes
one effect; a single `.cube` file works too.

```
OPTIONS:
  --category <name>   Effects-browser category / LUT folder name
                      (default: the input folder's name, or "LUTs" for a single file)
  --force             Overwrite effects that already exist
  --dry-run           Show what would happen without writing anything
  --no-thumbnails     Skip generating effect thumbnails
  --thumbnail-image <path>
                      Render effect thumbnails from this image (e.g. a still
                      from your footage) instead of the built-in gradient
  --list-installed    List installed LUT effects and exit
```

Example:

```sh
lutfx ~/Downloads/MyFilmLooks --category "Film Looks"
```

Then restart Final Cut Pro and look in **Effects browser → Film Looks**. Each
effect publishes the LUT selector, Input/Output Color Space, and Mix in the
inspector.

## What it writes

Per run, two locations (both are the standard FCP user locations):

1. `~/Library/Application Support/ProApps/Custom LUTs/<category>/<name>.cube` —
   FCP's Custom LUT repository. FCP discovers files here automatically; this is
   the same place the "Choose Custom LUT…" open panel installs to.
2. `~/Movies/Motion Templates(.localized)/Effects(.localized)/<category>/<name>/` —
   the effect template: `<name>.moef`, `large.png`, `small.png`.

Re-running skips effects that already exist (use `--force` to regenerate). If a
`.cube` with the same name but different content is already in the repository,
the new file is installed under a numbered name instead of overwriting, so
existing projects keep rendering identically.

## Uninstalling an effect

Delete the effect's folder from
`~/Movies/Motion Templates.localized/Effects.localized/<category>/<name>/`
(and optionally the `.cube` from
`~/Library/Application Support/ProApps/Custom LUTs/<category>/` — keep it if
any project still uses the effect), then restart Final Cut Pro.

## Releasing a new version

Homebrew serves a prebuilt universal binary from the GitHub release, so a
release is three steps (replace `X.Y.Z`):

```sh
# 1. Build the universal binary and package it
swift build -c release --arch arm64 --arch x86_64
tar -czf lutfx-X.Y.Z-macos-universal.tar.gz -C .build/out/Products/Release lutfx

# 2. Tag and create the GitHub release with the tarball attached
git tag vX.Y.Z && git push --tags
gh release create vX.Y.Z lutfx-X.Y.Z-macos-universal.tar.gz --title "vX.Y.Z"

# 3. Point the Homebrew formula at it
shasum -a 256 lutfx-X.Y.Z-macos-universal.tar.gz
# then update `url` and `sha256` in Formula/lutfx.rb of
# https://github.com/avis001/homebrew-tap and push
```

Verify with `brew update && brew upgrade lutfx` (or a fresh
`brew install avis001/tap/lutfx`).

## How it works (reverse-engineered formats)

Verified against Final Cut Pro 11.x on macOS:

- FCP's Custom LUT effect is the internal FxPlug filter `PAELUTEffect`
  (UUID `14B39AEF-607D-42DF-98DD-DB3DD345E925`, version 2, registered in
  `InternalFiltersXPC.pluginkit`). A `.moef` can instantiate it via the
  "ProPlugin Filter" factory, exactly like Apple's built-in color presets do.
- The selected LUT lives in custom parameter id 3 as the string
  `"<hash>:<display name>"`.
- `<hash>` is `PCMD5HashWithCFString(relativePath)`: the MD5 of the UTF-16LE
  bytes of the cube's path relative to the Custom LUTs folder (e.g.
  `"Film Looks/Kodak 2383.cube"`), hex-printed with each 32-bit word
  byte-swapped. FCP resolves the reference by scanning the repository and
  matching this hash — the effect keeps working as long as the file stays at
  that relative path.
- The parameter value is serialized as
  `[UInt64 big-endian length][0x2a][NSKeyedArchiver plist]`. The outer archive
  holds `DataIsLegacy` (false) and `BlindDataObject` — an NSData containing a
  second keyed archive with the reference string under the key `"Custom Data"`
  (that's the layer `OZFxPlugParameterHandler` unarchives with the plugin's
  `classForCustomParameterID:`, NSString here). The whole frame is text-encoded
  into the `.moef` XML using Motion's base64 variant with alphabet
  `*-0123456789A…Za…z`.

## Limitations

- Restart FCP after installing (templates and the LUT repository are scanned at
  launch).
- Moving/renaming the `.cube` inside the Custom LUTs folder breaks the hash
  reference; the effect then shows "Missing Custom LUT". Re-run lutfx to fix.
- 1D LUTs install but get no thumbnail (thumbnails are rendered via
  CIColorCube, which is 3D-only).
