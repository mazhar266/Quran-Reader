# Quran Reader

A Quran reader built on [QQ-Lang](https://github.com/mazhar266/QQ-Lang). Every
ayah on screen comes from a QQL query (`Q:<surah>`) resolved by the native
library — the app holds no scripture of its own.

- Application ID / namespace: `quran.mazhar.fi`

## Two reading modes

| Mode | Shows |
| --- | --- |
| **Reading** | Arabic only — an uninterrupted page of scripture |
| **Normal** | Arabic followed by its English translation, ayah by ayah |

The mode is a persisted setting, and also toggles from the reader's app bar.

## Settings

- **Theme** — light, dark, or follow the system.
- **Arabic font** — the system face or one of three bundled Quranic faces
  (Al Majeed, Muhammadi, PDMS Saleem), with a live preview.
- **Arabic size** — 18–56 pt. English is deliberately left alone; it follows
  the platform text scale like the rest of the UI.

## How QQL is wired in

QQL resolves queries against JSON files on a real filesystem path, but on
Android and iOS the bundled data lives inside the app package where no such
path exists. So:

1. The data is bundled under `assets/qqldata/`, mirroring QQ-Lang's `sources/`
   layout byte for byte.
2. On first launch [QuranRepository](lib/src/data/quran_repository.dart)
   unpacks it into the app support directory, preserving that layout.
3. A native context is opened on the unpacked directory and reused for the
   life of the app.

Bump `_dataVersion` in that file whenever the bundled data changes, or existing
installs will keep their old copy.

[lib/src/qql/qql.dart](lib/src/qql/qql.dart) is vendored from QQ-Lang's
`bindings/dart/qql.dart`. The only change is how the library is located per
platform; keep the C signatures in sync with QQ-Lang's `include/qql.h`.

## Building

The Rust library is *not* vendored as source — it is built from a QQ-Lang
checkout and only the binaries land here.

```sh
scripts/build-native.sh    # libqql for Linux + Android (iOS needs macOS)
scripts/sync-data.sh       # refresh the bundled Quran JSON
flutter run
```

Set `QQL_DIR` if your QQ-Lang checkout is not at `~/Projects/QQ Lang`.

### Platform status

| Platform | Native artifact | State |
| --- | --- | --- |
| Linux | `linux/lib/libqql.so`, installed into the bundle's `lib/` | Built and run |
| Android | `android/app/src/main/jniLibs/{abi}/libqql.so` (arm64-v8a, armeabi-v7a, x86_64) | APK builds with all three ABIs; not yet run on a device |
| iOS | `ios/Frameworks/libqql.a`, linked statically | Not built — requires macOS with Xcode |

iOS forbids `dlopen` of a private dylib, so the binding resolves symbols with
`DynamicLibrary.process()` and expects `libqql.a` linked into the Runner target
with `-force_load`. `scripts/build-native.sh` produces that archive when run on
macOS; the Xcode target still has to be wired up by hand once.

## License

Copyright (C) 2026 Mazhar

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: GPL-3.0-or-later
