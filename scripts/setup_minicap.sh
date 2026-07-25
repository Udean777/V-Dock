#!/bin/bash
set -euo pipefail

MINICAP_DIR="$HOME/Library/Application Support/V-Dock/minicap"

echo "Downloading minicap prebuilt binaries to $MINICAP_DIR..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PKG_VERSION=$(curl -sL "https://registry.npmjs.org/@u4/minicap-prebuilt/latest" | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])" 2>/dev/null || echo "1.0.20")
echo "Version: $PKG_VERSION"

curl -sL "https://registry.npmjs.org/@u4/minicap-prebuilt/-/minicap-prebuilt-$PKG_VERSION.tgz" | tar -xz -C "$TMPDIR"

rm -rf "$MINICAP_DIR"
mkdir -p "$MINICAP_DIR"

cd "$TMPDIR/package/prebuilt"

# Copy minicap executables
for arch in arm64-v8a armeabi-v7a x86 x86_64; do
  mkdir -p "$MINICAP_DIR/$arch"
  if [ -f "$arch/bin/minicap" ]; then
    cp "$arch/bin/minicap" "$MINICAP_DIR/$arch/"
  fi
done

# Copy minicap.so libraries for each SDK level
for so_path in */lib/android-*/minicap.so; do
  dir=$(dirname "$so_path")
  sdk_arch=$(dirname "$dir")
  sdk=$(basename "$dir")
  arch=$(dirname "$sdk_arch")
  mkdir -p "$MINICAP_DIR/$sdk/$arch"
  cp "$so_path" "$MINICAP_DIR/$sdk/$arch/"
done

chmod -R +x "$MINICAP_DIR"

echo "Done. Binaries at $MINICAP_DIR"


