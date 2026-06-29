#!/usr/bin/env bash
# Refresh latest.json (version + sha256 + url + published_at) and docs/
# (feature-support.md, weave-extensions.md) from a published weave-v* release.
# Local/offline equivalent of .github/workflows/update-latest.yml. Does NOT commit.
#
# Usage:  scripts/update-latest.sh [weave-vX.Y.Z]   # default: latest release
set -euo pipefail

REPO_SLUG="veedstudio/weave-renderer-public-releases"
ASSET="weave-viewer-cli-macos-arm64.tar.gz"
PLATFORM="macos-arm64"
TOOL="weave-viewer-cli"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-}"
if [ -z "$TAG" ]; then
  # Newest *weave-v* release, not merely the newest release by date.
  TAG="$(gh release list --repo "$REPO_SLUG" --limit 30 --json tagName \
    --jq 'map(.tagName) | map(select(startswith("weave-v"))) | .[0] // empty')"
  [ -n "$TAG" ] || { echo "No weave-v* release found on $REPO_SLUG." >&2; exit 1; }
fi
case "$TAG" in
  weave-v*) ;;
  *) echo "Tag '$TAG' is not a weave-v* release tag." >&2; exit 1 ;;
esac
VERSION="${TAG#weave-v}"
echo "Syncing latest.json to $TAG (version $VERSION)"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
gh release download "$TAG" --repo "$REPO_SLUG" \
  --pattern "$ASSET.sha256" \
  --pattern 'feature-support.md' \
  --pattern 'weave-extensions.md' \
  --dir "$TMP" --clobber
# Pull the 64-hex digest regardless of layout: GNU/`shasum` "<hash>  <file>"
# or BSD/openssl tagged "SHA256 (<file>) = <hash>".
SHA="$(grep -oiE '[0-9a-f]{64}' "$TMP/$ASSET.sha256" | head -n1 | tr 'A-F' 'a-f')"
[ -n "$SHA" ] || { echo "ERROR: no sha256 digest found in release asset" >&2; exit 1; }

PUBLISHED_AT="$(gh release view "$TAG" --repo "$REPO_SLUG" --json publishedAt --jq '.publishedAt')"
URL="https://github.com/$REPO_SLUG/releases/download/$TAG/$ASSET"

jq -n \
  --arg tool "$TOOL" --arg tag "$TAG" --arg version "$VERSION" \
  --arg platform "$PLATFORM" --arg asset "$ASSET" --arg url "$URL" \
  --arg sha256 "$SHA" --arg published_at "$PUBLISHED_AT" \
  '{tool: $tool, tag: $tag, version: $version, platform: $platform,
    asset: $asset, url: $url, sha256: $sha256, published_at: $published_at}' \
  > latest.json

# Refresh shipped docs from the release (tolerate releases cut before they existed).
mkdir -p docs
[ -f "$TMP/feature-support.md" ]  && cp "$TMP/feature-support.md"  docs/feature-support.md  || true
[ -f "$TMP/weave-extensions.md" ] && cp "$TMP/weave-extensions.md" docs/weave-extensions.md || true

echo "Updated:"
echo "  latest.json  -> version $VERSION, sha256 $SHA"
echo "  docs/*.md    <- $TAG assets (if present)"
echo "Review with 'git diff', then commit."
