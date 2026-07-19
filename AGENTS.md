# Agent notes for fcpLutToEffect (lutfx)

Swift Package that converts `.cube` LUT files into individual Final Cut Pro
effects. Two targets: `LutFxKit` (Sources/LutFxKit — all format/install
logic, public API) and `lutfx` (Sources/lutfx — thin CLI over the kit). A
future macOS app target will also depend on LutFxKit; put new logic in the
kit, not the CLI.

Read README.md first — especially "How it works (reverse-engineered
formats)"; the serialization details there are load-bearing and were verified
against FCP's binaries. Don't change hash computation, blob nesting, or the
`.moef` template structure without re-reading that section.

## Build & test

```sh
swift build                      # debug build → .build/debug/lutfx
swift build -c release           # release → .build/release/lutfx
.build/debug/lutfx <cube-or-dir> --dry-run   # safe functional check
```

There is no test suite; verification is functional. A real install writes into
the user's `~/Movies/Motion Templates…` and
`~/Library/Application Support/ProApps/Custom LUTs/` — prefer `--dry-run`
unless the user wants an actual install. Rendering can only be confirmed
inside Final Cut Pro by the user.

## Releasing

Follow "Releasing a new version" in README.md. The Homebrew formula lives in
the separate repo https://github.com/avis001/homebrew-tap
(`Formula/lutfx.rb`) and must have its `url`/`sha256` bumped for each release.
The universal-build output lands in `.build/out/Products/Release/lutfx`
(note: `out`, not `apple`).

## Repo conventions

- Default branch is `develop`.
- The `.moef` XML template is an inline string in
  `Sources/LutFxKit/MoefTemplate.swift`; object/parameter IDs in it mirror
  Apple's built-in color-preset templates and are referenced by the
  publishSettings targets — keep them consistent if editing.
