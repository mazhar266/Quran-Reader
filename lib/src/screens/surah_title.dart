// The heading shown above a surah.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../mushaf/mushaf_theme.dart';
import '../settings/settings_controller.dart';

/// The basmalah, in the same Uthmani orthography as the ayah text — this is
/// 1:1 verbatim, so it sets identically to the rest of the page.
const _basmalah = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

/// "سورة", the word that precedes the name in a mushaf heading.
const _surahWord = 'سُورَة';

/// The heading above a surah: its name in a cartouche, the basmalah beneath.
class SurahHeading extends StatelessWidget {
  const SurahHeading({super.key, required this.surah});

  final Surah surah;

  /// At-Tawbah is the one surah that does not open with the basmalah, and
  /// Al-Fatihah already carries it as ayah 1, so neither repeats it here.
  bool get showsBasmalah => surah.number != 1 && surah.number != 9;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final ink = MushafColors.ink(brightness);
    final family = SettingsScope.of(context).arabicFont.family;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // The name plate. A mushaf sets the surah name inside a tooled
            // banner; this is the same double rule and corner diamonds as the
            // page frame, in miniature.
            CustomPaint(
              painter: _CartouchePainter(brightness),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 4,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$_surahWord ${surah.nameArabic}',
                    style: TextStyle(
                      fontFamily: family,
                      fontSize: 28,
                      height: 1.6,
                      color: MushafColors.gold(brightness),
                    ),
                  ),
                ),
              ),
            ),
            if (showsBasmalah) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _basmalah,
                  style: TextStyle(
                    fontFamily: family,
                    fontSize: 24,
                    height: 1.8,
                    color: ink,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

/// The double-rule banner around the surah name: a thin outer rule, a heavier
/// inner one, and a diamond-and-dot where they meet at each corner — the page
/// frame's vocabulary at cartouche size.
class _CartouchePainter extends CustomPainter {
  const _CartouchePainter(this.brightness);

  final Brightness brightness;

  static const _outerStroke = 1.0;
  static const _gap = 3.0;
  static const _innerStroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = MushafColors.gold(brightness)
      ..style = PaintingStyle.stroke;

    final outer = Offset.zero & size;
    canvas.drawRect(outer, gold..strokeWidth = _outerStroke);

    final inner = outer.deflate(_outerStroke + _gap + _innerStroke / 2);
    canvas.drawRect(inner, gold..strokeWidth = _innerStroke);

    final diamondSide = _innerStroke * 3.0;
    for (final corner in [inner.topLeft, inner.topRight, inner.bottomRight, inner.bottomLeft]) {
      final diamond = Path()
        ..moveTo(corner.dx, corner.dy - diamondSide)
        ..lineTo(corner.dx + diamondSide, corner.dy)
        ..lineTo(corner.dx, corner.dy + diamondSide)
        ..lineTo(corner.dx - diamondSide, corner.dy)
        ..close();
      canvas.drawPath(diamond, gold..strokeWidth = _outerStroke);
      canvas.drawCircle(corner, _outerStroke, Paint()..color = gold.color);
    }
  }

  @override
  bool shouldRepaint(_CartouchePainter old) => old.brightness != brightness;
}
