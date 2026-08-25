# Quran Reader

A Flutter app for reading the Quran, built on [QQ-Lang](https://github.com/mazhar266/QQ-Lang).
Every ayah on screen comes from a QQL query (`Q:<surah>`) resolved by a native
Rust library over FFI — the app holds no scripture of its own. Licensed
GPL-3.0-or-later; application ID `fi.mazhar.quran.reader`.

The README.md is unusually detailed and explains *why* things are the way they
are. Read it before changing anything it covers.

## Technology stack

- **Flutter / Dart** — SDK `^3.12.2`, developed against Flutter 3.44.x stable.
  Targets Linux, Android, iOS (macOS/Windows/web scaffolding exists but is not
  a shipping target).
- **QQL native library (Rust)** — the query engine, built from a separate
  QQ-Lang checkout; only binaries are vendored here, not source. Talked to via
  `dart:ffi` (`package:ffi`).
- Key pub dependencies: `shared_preferences` (settings + reading position),
  `path_provider` (app support dir for unpacked data),
  `scrollable_positioned_list` (scroll-to-index in Normal mode).

## Repository layout

- `lib/main.dart` — app entry point; opens the repository once, wires the theme.
- `lib/src/qql/qql.dart` — Dart FFI binding to libqql. **Vendored from QQ-Lang's
  `bindings/dart/qql.dart`;** the only local change is per-platform library
  loading. Keep the C signatures in sync with QQ-Lang's `include/qql.h`.
- `lib/src/data/` — `QuranRepository` (unpacks bundled data, opens the native
  context, runs `Q:<surah>` queries), plain `Surah`/`Ayah` models, and
  `ReadingPositionStore` (single "continue reading" position, persisted).
- `lib/src/tajwid/` — `tajwid.dart` is the tajwid rule engine as **pure Dart**
  (no Flutter imports, so it tests without a binding); `tajwid_style.dart`
  turns matches into coloured `TextSpan`s with separate light/dark palettes.
- `lib/src/mushaf/` — the paper-mushaf look: `mushaf_theme.dart` (cream/sepia/
  gold palette + the three `ThemeData`s — light, night-paper dark, true-black
  OLED; widgets read the `ColorScheme` roles, so themes live only in this
  file) and `mushaf_frame.dart` (the painted double-rule page border with
  diamond corners, fixed to the viewport — it never scrolls with the text).
- `lib/src/settings/settings_controller.dart` — `SettingsController`
  (ChangeNotifier over shared_preferences) + `SettingsScope` InheritedNotifier.
  Holds theme (`AppTheme` — system/light/dark/OLED, mapped to `ThemeMode` by
  `materialThemeMode`), reading mode, Arabic font, Arabic font size.
- `lib/src/screens/` — `surah_list_screen.dart` (home), `surah_screen.dart`
  (reader, both modes), `surah_title.dart` (surah heading + basmalah),
  `settings_screen.dart`, `about_screen.dart`.
- `assets/qqldata/` — Tanzil Quran Text (Uthmani v1.1, CC BY 3.0) as
  `quran/chapters/{n}.json` (114 files), mirroring QQ-Lang's `sources/` layout
  byte for byte, plus `TANZIL-LICENSE.txt`. `assets/surah_index.json` is a
  derived 114-surah index (the dataset itself has no index).
- `assets/fonts/` — eight bundled Quranic typefaces, declared in pubspec.
- `scripts/build-native.sh` — builds libqql from the QQ-Lang checkout for
  Linux + Android (+ iOS on macOS). Set `QQL_DIR` if the checkout is not at
  `~/Projects/QQ Lang`.
- `scripts/sync-data.sh` — refreshes `assets/qqldata/` from the QQ-Lang
  checkout and regenerates `assets/surah_index.json`.
- `test/` — five test files; see Testing below.

## Build and test commands

```sh
flutter pub get
flutter analyze          # must stay clean (flutter_lints 6.x)
flutter test             # full suite, ~40 tests, no native library needed
flutter run              # needs the native artifact for your platform first

scripts/build-native.sh  # build libqql from the QQ-Lang checkout
scripts/sync-data.sh     # refresh bundled Quran JSON; then bump _dataVersion
```

Releasing is CI-driven: pushing a `v*` tag runs `.github/workflows/release.yml`
(runs the tests, builds with the vendored prebuilt libqql binaries — no Rust in
CI — and attaches APKs + a Linux tarball to a GitHub Release).

Native artifacts the Flutter build expects:

| Platform | Path |
| --- | --- |
| Linux | `linux/lib/libqql.so` (installed into the bundle's `lib/`, found via rpath) |
| Android | `android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/libqql.so` |
| iOS | `ios/Frameworks/libqql.a`, statically linked with `-force_load` (not built here — needs macOS/Xcode; the binding uses `DynamicLibrary.process()`) |

Launcher icons: `dart run flutter_launcher_icons` after changing
`assets/icon/` (config in pubspec.yaml; the Android adaptive background must
stay transparent — see README for why).

## Architecture notes that are easy to get wrong

- **Two reading modes.** *Reading* = Arabic only as one continuous paragraph
  (deliberately not a lazy list — line breaks depend on all previous ayahs),
  with khata-style ruled hairlines under every line; the rule positions are
  measured from a mirrored `TextPainter` layout since medallion lines can set
  taller. *Normal* = Arabic + English per ayah in a
  `ScrollablePositionedList`. Mode affects how the current ayah is located for
  resume: paragraph position mapping vs. item index.
- **Data unpacking.** QQL needs real filesystem paths, so `QuranRepository`
  unpacks `assets/qqldata/` into the app support directory on first launch and
  opens one native context for the app's lifetime. **Bump `_dataVersion` in
  `lib/src/data/quran_repository.dart` whenever the bundled data changes**, or
  existing installs keep their stale copy.
- **Ayah medallions are pinned to `medallionFontFamily` (`UthmanicHafs`)**,
  never the selected font: several bundled faces map U+0660–0669 (Arabic-Indic
  digits) to blank glyphs and the ayah numbers would vanish. `ayahMarkerText`
  is just the digits — do not add U+06DD, which draws an extra empty circle.
- **Tajwid engine is character-driven by the bundled Tanzil text**, not the
  textbook inventory: sukun U+0652 (legacy U+06E1 also accepted), U+06DF marks
  unpronounced letters, "sakin" can mean *no vowel at all*, iqlab is explicit
  (U+06E2/U+06ED), madd is always combining U+0653. Idgham must only fire
  across a word boundary (noon + yeh/waw inside one word is izhar mutlaq) —
  `test/tajwid_test.dart` pins this. Undecidable cases stay uncoloured.
- **Native memory is manual**: `Qql` holds a Rust context — call `dispose()`;
  string results are copied to Dart then released with `qql_free_string`.

## Testing instructions

`flutter test` runs everything. Tests are grouped by concern:

- `test/tajwid_test.dart` — pure-Dart rule tests against real Tanzil
  orthography (the boundary-blind idgham case is explicitly pinned).
- `test/settings_test.dart` — persistence via
  `SharedPreferences.setMockInitialValues`.
- `test/reading_position_test.dart` — the position store, same mocking.
- `test/surah_heading_test.dart` — widget test; the basmalah string must match
  1:1 of the bundled text exactly.
- `test/about_screen_test.dart` — asserts the Tanzil attribution is present;
  **this is a licence obligation (CC BY 3.0), not decoration** — do not remove
  the credits.

Tests deliberately avoid the native library: anything needing QQL is not
unit-tested. When testing widgets that read settings, pump them inside a
`SettingsScope` with a `SettingsController` loaded from mocked preferences.

## Code style guidelines

- Stock `flutter_lints` (`analysis_options.yaml`), no custom rules; keep
  `flutter analyze` clean.
- Every source file starts with `// SPDX-License-Identifier: GPL-3.0-or-later`.
- Comments explain *why*, not what — many document non-obvious constraints
  (font glyph gaps, Tanzil character inventory, FFI ownership). Match that
  density and keep them accurate when behaviour changes.
- Simple state management only: `ChangeNotifier` + `InheritedNotifier` +
  `AnimatedBuilder`. Do not add a state-management package.
- Keep the tajwid engine (`lib/src/tajwid/tajwid.dart`) free of Flutter imports.

## Security and legal considerations

- Bundled text is **Tanzil Quran Text (Uthmani, v1.1), CC BY 3.0**: the source
  must be named/linked (About page), the text must ship unmodified, and
  `TANZIL-LICENSE.txt` must travel with it.
- The FFI boundary trusts the native library's JSON contract (`"ok": false`
  errors become `QqlException`, never thrown from `executeJson`). Never free a
  native string except through `qql_free_string`.
- No network access, accounts, or telemetry anywhere in the app.
