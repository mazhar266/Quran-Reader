// The heading shown above a surah.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../settings/settings_controller.dart';

/// The basmalah, in the same Uthmani orthography as the ayah text — this is
/// 1:1 verbatim, so it sets identically to the rest of the page.
const _basmalah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

/// "سورة", the word that precedes the name in a mushaf heading.
const _surahWord = 'سُورَة';

/// The heading above a surah: its name, and the basmalah beneath it.
class SurahHeading extends StatelessWidget {
  const SurahHeading({super.key, required this.surah});

  final Surah surah;

  /// At-Tawbah is the one surah that does not open with the basmalah, and
  /// Al-Fatihah already carries it as ayah 1, so neither repeats it here.
  bool get showsBasmalah => surah.number != 1 && surah.number != 9;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$_surahWord ${surah.nameArabic}',
                style: TextStyle(
                  fontFamily: arabicFontFamily,
                  fontSize: 30,
                  height: 1.6,
                  color: color,
                ),
              ),
            ),
            if (showsBasmalah)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _basmalah,
                  style: TextStyle(
                    fontFamily: arabicFontFamily,
                    fontSize: 24,
                    height: 1.8,
                    color: color,
                  ),
                ),
              ),
            const Divider(height: 18),
          ],
        ),
      ),
    );
  }
}
