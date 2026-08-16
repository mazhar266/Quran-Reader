#!/usr/bin/env bash
# Build the QQL native library for every platform this app ships to, and drop
# the artifacts where the Flutter build expects them.
#
# The library is not vendored as source — it is built from the QQ-Lang checkout
# and only the resulting binaries land here.
#
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QQL_DIR="${QQL_DIR:-$HOME/Projects/QQ Lang}"

if [[ ! -f "$QQL_DIR/Cargo.toml" ]]; then
  echo "QQ-Lang not found at '$QQL_DIR'. Set QQL_DIR to its checkout." >&2
  exit 1
fi

cd "$QQL_DIR"

echo "==> Linux (x86_64)"
cargo build --release
install -Dm644 target/release/libqql.so "$APP_DIR/linux/lib/libqql.so"

echo "==> Android (arm64-v8a, armeabi-v7a, x86_64)"
if command -v cargo-ndk >/dev/null; then
  : "${ANDROID_NDK_HOME:=$(ls -d "$HOME"/Android/Sdk/ndk/* 2>/dev/null | sort -V | tail -1)}"
  export ANDROID_NDK_HOME
  cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 \
    -o "$APP_DIR/android/app/src/main/jniLibs" build --release
else
  echo "    skipped: cargo-ndk not installed (cargo install cargo-ndk)" >&2
fi

echo "==> iOS (device + simulator)"
if [[ "$(uname)" == "Darwin" ]]; then
  # iOS forbids dlopen of a private dylib, so qql is linked statically and the
  # Dart binding resolves symbols with DynamicLibrary.process().
  for target in aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios; do
    rustup target add "$target"
    cargo build --release --target "$target"
  done
  mkdir -p "$APP_DIR/ios/Frameworks"
  lipo -create \
    target/aarch64-apple-ios-sim/release/libqql.a \
    target/x86_64-apple-ios/release/libqql.a \
    -output "$APP_DIR/ios/Frameworks/libqql-sim.a"
  cp target/aarch64-apple-ios/release/libqql.a "$APP_DIR/ios/Frameworks/libqql.a"
  echo "    Add ios/Frameworks/libqql.a to the Runner target in Xcode, and set"
  echo "    'Other Linker Flags' to -force_load so the C ABI symbols survive."
else
  echo "    skipped: iOS builds require macOS with Xcode" >&2
fi

echo
echo "Done. Refresh the bundled data with: scripts/sync-data.sh"
