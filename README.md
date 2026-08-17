# Quran Reader

A Quran reader built on [QQ-Lang](https://github.com/mazhar266/QQ-Lang). Every
ayah on screen comes from a QQL query (`Q:<surah>`) resolved by the native
library — the app holds no scripture of its own.

- Application ID / namespace: `quran.mazhar.fi`

## Two reading modes

| Mode | Shows |
| --- | --- |
| **Reading** | Arabic only, set as one continuous page — each ayah carries on from where the last ended and the text wraps like a mushaf, rather than breaking to a new line per ayah |
| **Normal** | Arabic followed by its English translation, one ayah per block |

Reading mode is therefore a single paragraph for the whole surah, which is why
it is not a lazy list — where a line breaks depends on every ayah before it.
Laying out Al-Baqarah's 286 ayahs costs about 120 ms in a debug build, once,
when the surah opens.

The mode is a persisted setting, and also toggles from the reader's app bar.

## Tajwid colouring

Arabic is coloured wherever a rule changes how a letter is pronounced, in both
modes. English is never coloured. [tajwid.dart](lib/src/tajwid/tajwid.dart)
holds the rule engine as pure Dart, and
[tajwid_style.dart](lib/src/tajwid/tajwid_style.dart) turns its matches into
spans; the settings page carries a legend of the colours.

Detected: ghunnah, idgham with and without ghunnah, iqlab, ikhfa, idgham and
ikhfa shafawi, qalqalah, and madd. Anything that cannot be decided from the
written form is left uncoloured rather than guessed at — izhar is simply the
absence of a colour, and the two-, four- and six-count madd lengths are not
separated because the text does not distinguish them.

The engine is driven by the character inventory the bundled text actually uses,
which is not the textbook one:

- Sukun is usually U+06E1, not U+0652.
- A noon before idgham or ikhfa is often written **bare**, with no sukun at
  all, so "sakin" means "carries no vowel" rather than "carries a sukun".
- Iqlab is written explicitly as U+06E2 or U+06ED, so it is read off the text
  instead of inferred from a following beh.
- Madd is always a combining U+0653; the precomposed U+0622 never appears.

Idgham is only applied across a word boundary. A noon followed by yeh or waw
inside one word is izhar mutlaq, and colouring it as idgham is the mistake a
boundary-blind rule makes — `test/tajwid_test.dart` pins that case along with
the rest.

## Resuming

The last ayah in view is recorded as the reader scrolls, and the surah list
shows a "Continue reading" strip plus a bookmark against that surah; tapping
either reopens it at that ayah. Only one position is kept — this is "carry on
where I left off", not a bookmark list.

Finding the ayah in view differs by mode, because the layouts do:

- **Normal** uses `ScrollablePositionedList`, which reports the top item's
  index and can jump to one. A plain lazy `ListView` can do neither, because
  items away from the viewport have no known height.
- **Reading** has no items at all, so it asks the laid-out paragraph which
  character sits at the top of the viewport and maps that back to an ayah.

## The Arabic face

`assets/fonts/UthmanicHafs.ttf` (KFGQPC HAFS Uthmanic Script) is the only
Arabic font in the app, and there is no font picker — the setting and its
`arabic_font` preference are gone. English keeps the platform UI font.

It covers every codepoint the bundled text uses except U+2009 THIN SPACE, which
occurs once in the whole Quran and is a space anyway, and no mapped codepoint
draws a blank glyph.

It also renders U+0660-0669 as the **ornamented ayah medallions** of a mushaf,
with the number already inside them. So `ayahMarkerText` is now just the ayah
number in Arabic-Indic digits — nothing is drawn around it. U+06DD (ARABIC END
OF AYAH) would add a second, empty circle beside the medallion, and the ornate
parentheses U+FD3E/FD3F that an earlier font needed are not in this one at all.

The heading in [surah_title.dart](lib/src/screens/surah_title.dart) is ordinary
Arabic text in the same face — `سُورَة` plus the surah name, with the basmalah
beneath it, taken verbatim from 1:1 so it sets identically to the page.

## Settings

- **Theme** — light, dark, or follow the system.
- **Arabic size** — 18–56 pt, with a live preview. English is deliberately
  left alone; it follows the platform text scale like the rest of the UI.

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

## Launcher icon

`icon.png` at the repo root is the source. It is 1043×1081 with rounded corners
and transparency already baked in, which no platform can consume directly, so
two variants are derived into `assets/icon/`:

| File | Why |
| --- | --- |
| `icon.png` | Squared to 1081×1081 on transparent padding. Scaling to square instead would distort the rehal. |
| `icon_ios.png` | Corners filled and the alpha channel dropped, which iOS requires. The fill replicates each row's edge colour outward so it tracks the icon's vertical gradient; a flat fill bands against it. |

Regenerate the platform icons with `dart run flutter_launcher_icons` after
changing either. The derivation itself is a one-off — re-run the snippet in the
commit that added them if the source art changes shape.

- **Android** — adaptive icon, full-bleed foreground over `#10382C` (sampled
  from the icon's own border). `ic_launcher.xml` insets the foreground by 16%,
  which lands it on the 72dp safe zone; do not pre-inset the source as well.
- **iOS** — alpha-free 1024×1024 and the full density set.
- **Linux** — `flutter_launcher_icons` has no Linux target, so
  [my_application.cc](linux/runner/my_application.cc) sets the GTK window icon
  from the copy CMake installs at `data/icon.png`. For a dock or menu entry,
  install [quran-reader.desktop](linux/packaging/quran-reader.desktop) into
  `~/.local/share/applications/` and the icon into
  `~/.local/share/icons/hicolor/512x512/apps/quran-reader.png`.

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
