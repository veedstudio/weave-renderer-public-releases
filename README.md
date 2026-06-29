# weave-renderer — public release surface

This repo is the public-facing distribution point for `weave-viewer-cli`: a CLI that previews and
records HTML/CSS `.weave` templates to MP4 (macOS, Apple Silicon only). It carries **no engine
code** — that lives in a private upstream monorepo and is published here as binary releases.

```
[ Upstream Monorepo ]       [ This Distribution Repo ]
┌───────────────────┐       ┌──────────────────────────────┐
│ - Engine Source   │──────▶│ - Release tarballs (weave-v*) │
│ - Build System    │ CI    │ - latest.json (current ver)   │
│ - .weave Specs    │ Cuts  │ - Examples & Docs             │
│ - CSS Subsets     │ Tag   │ - sha256 checksums            │
└───────────────────┘       └──────────────────────────────┘
  (Source of Truth)           (Deployment & Usage)
```

## What's in this repo

- **GitHub Releases** (`weave-v*` tags) — the `weave-viewer-cli-macos-arm64.tar.gz` binary tarball plus its `.sha256` checksum, built and published by upstream CI.
- `latest.json` — machine-readable pointer to the current release (tag, version, asset URL, sha256). Auto-updated on each release by `.github/workflows/update-latest.yml`.
- `examples/` — designer-facing curated `.weave` projects. Each subfolder is a self-contained project. Clone the repo, then point `weave-viewer-cli` at a folder.
- `docs/` — CSS/HTML feature-support reference and the weave-extensions spec, refreshed from each release.
- `scripts/update-latest.sh` — local/offline equivalent of the release workflow (refreshes `latest.json` + `docs/`).

## Install (macOS, Apple Silicon only)

Weave is currently experimental and supports **macOS (Apple Silicon / M-series ARM64)** only.
There is no package manager involved — download the tarball from this repo's GitHub Releases,
verify its checksum, and extract it.

```bash
# 1. Pick the version (latest is recorded in latest.json)
TAG=$(curl -fsSL https://raw.githubusercontent.com/veedstudio/weave-renderer-public-releases/main/latest.json | python3 -c 'import json,sys;print(json.load(sys.stdin)["tag"])')
BASE="https://github.com/veedstudio/weave-renderer-public-releases/releases/download/$TAG"

# 2. Download the binary tarball + its checksum
curl -fL -O "$BASE/weave-viewer-cli-macos-arm64.tar.gz"
curl -fL -O "$BASE/weave-viewer-cli-macos-arm64.tar.gz.sha256"

# 3. Verify the checksum (must print "OK")
shasum -a 256 -c weave-viewer-cli-macos-arm64.tar.gz.sha256

# 4. Extract — the tarball is self-contained
tar -xzf weave-viewer-cli-macos-arm64.tar.gz
```

The tarball is **self-contained**: the binary ships alongside its `shaders/`, `data/fonts/`, and
`lib/` directories, which must stay adjacent to the executable. Run it in place (or move the whole
extracted folder), then invoke `./weave-viewer-cli`.

`ffmpeg` is required for `--record` (MP4 encoding). Install it separately, e.g. `brew install ffmpeg`.

### Unsigned binary — Gatekeeper note

The current binary is **not yet code-signed or notarized** (signing is a planned phase). On first
run macOS may quarantine it. Clear the quarantine attribute on the extracted folder:

```bash
xattr -dr com.apple.quarantine ./weave-viewer-cli
```

(Or right-click the binary in Finder → **Open** the first time.)

## Latest release

`latest.json` (repo root) is the machine-readable source of truth for the current release:

```json
{
  "tool": "weave-viewer-cli",
  "tag": "weave-v0.4.0",
  "version": "0.4.0",
  "platform": "macos-arm64",
  "asset": "weave-viewer-cli-macos-arm64.tar.gz",
  "url": "https://github.com/veedstudio/weave-renderer-public-releases/releases/download/weave-v0.4.0/weave-viewer-cli-macos-arm64.tar.gz",
  "sha256": "…",
  "published_at": "…"
}
```

Fetch the download URL and checksum directly for scripted installs/self-update checks:

```bash
curl -fsSL https://raw.githubusercontent.com/veedstudio/weave-renderer-public-releases/main/latest.json
```

You can also browse the GitHub **[Releases](https://github.com/veedstudio/weave-renderer-public-releases/releases/latest)** page.

## First use

```bash
git clone https://github.com/veedstudio/weave-renderer-public-releases
cd weave-renderer-public-releases
weave-viewer-cli examples/subtitles-simple                       # opens preview window
weave-viewer-cli examples/subtitles-simple --record out.mp4      # renders to MP4
```

A project is a **folder**. Inside, `weave-viewer-cli` looks for:

- `template.weave` (required) — HTML+CSS document describing the scene and any animations.
- `overrides.json` (optional) — variable overrides for text, images, colors.
- `manifest.json` (optional) — default render dimensions / duration / fps.
- Assets at any relative subpath, resolved against the project folder.

## CLI surface (v1)

| Invocation | Effect |
|---|---|
| `weave-viewer-cli PATH` | Open a preview **window** that plays the template; animations loop until the user closes it. |
| `weave-viewer-cli PATH --record OUT.mp4 [--width W --height H --duration S --fps N]` | Render to MP4. Defaults come from `manifest.json` if present, else `1280×720 / 5s / 60fps`. |
| `weave-viewer-cli PATH --validate` | Static check (no GPU): parse `template.weave`, parse `overrides.json`, verify template-id references match manifest keys, verify every image path under `overrides.images` resolves on disk. Exit non-zero on errors. |

Video output is **silent** in v1 (audio dropped). Audio mixing is on the roadmap.

## Examples

All examples are self-contained `.weave` projects demonstrating subtitle / caption motion-graphics
techniques. Shared video fixtures live in `assets/videos/` and are referenced by relative path.

| Folder | What it shows |
|---|---|
| `examples/subtitles` | Base subtitles project over a keyed clip. |
| `examples/subtitles-simple` | Word-by-word pop-in/out captions via per-word `animation-delay`/`animation-duration`. |
| `examples/subtitles-advanced` | Richer caption styling. |
| `examples/subtitles-anchored` | Captions anchored to a keyed subject using an alpha `.mov` cut-out. |
| `examples/subtitles-cues` | Cue-grouped caption timing. |
| `examples/subtitles-depth` | Depth stacking — subject composited above text using an alpha cut-out. |
| `examples/subtitles-doodles` | Doodle / sprinkle overlays alongside captions. |
| `examples/subtitles-karaoke` | Karaoke-style per-word highlight. |
| `examples/subtitles-shadowed` | Shadowed / outlined caption text. |
| `examples/subtitles-typewriter` | Typewriter reveal. |
| `examples/cat-doc` | "The Midnight Zoomies" — a ~27.5s nature-doc parody assembled from B-roll, voiceover, and a generated title. See `examples/cat-doc/PROJECT.md` for the build graph; derived renders are rebuilt locally, only non-regenerable inputs are shipped. |

Binary media in `examples/` and `assets/` is tracked with **Git LFS** — make sure `git lfs` is
installed before cloning, or the media will arrive as pointer text.

## How releases work

The upstream private monorepo's CI builds the binary and, on tag push, publishes a `weave-v*`
**Release** here with assets: `weave-viewer-cli-macos-arm64.tar.gz` + its `.sha256`, plus
`feature-support.md` and `weave-extensions.md`. On each published release,
`.github/workflows/update-latest.yml` refreshes `latest.json` (version + sha256 + url +
published_at) and copies the docs into `docs/`. Source code is **not** distributed via this repo.

To refresh manually (e.g. offline): `scripts/update-latest.sh [weave-vX.Y.Z]` (defaults to the
latest release). It downloads the `.sha256`, rebuilds `latest.json`, and refreshes `docs/`. It does
not commit.

## Docs

- [`docs/feature-support.md`](docs/feature-support.md) — generated, fixture-anchored index of supported CSS/HTML features (carries `engine_version`). Use only listed features.
- [`docs/weave-extensions.md`](docs/weave-extensions.md) — hand-authored reference for weave-unique CSS extensions (e.g. the alpha-channel path producer/consumer model).

## Known limitations (v1)

- **No audio** in output. `<video>` content renders visually but its audio track is dropped. Roadmap.
- **macOS only.** Apple Silicon (ARM64) binaries only; Linux/Windows are not in v1.
- **No live reload.** Edit → re-render.
- **No GUI** for filling out variables. The CLI is the authoring surface.

## License

This repository contains two kinds of material under two different licenses:

- **Repository content** — the documentation and example `.weave` projects — is licensed under the **Apache License 2.0**. See [`LICENSE`](LICENSE).
- **The `weave-viewer-cli` binary**, distributed via this repo's GitHub Releases, is **proprietary and closed-source**. Its use is governed by an end-user license agreement bundled inside each release archive. See [`EULA.txt`](EULA.txt) for the current (placeholder) terms.

Bundled third-party assets in `examples/` and fonts fetched at runtime retain their own respective licenses.
