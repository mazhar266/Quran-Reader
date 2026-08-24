// The gilded double-rule border of a mushaf page, drawn around the reader.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'mushaf_theme.dart';

/// The ornamental page border of a printed mushaf.
///
/// Drawn, not an asset: it is two rectangles (a thin outer rule, a heavier
/// inner one) with a diamond-and-dot at each corner, so it costs nothing to
/// ship and scales to any screen. The interior is filled with the slightly
/// lighter [MushafColors.page], which is what separates "page" from "margin"
/// against the scaffold's paper colour.
///
/// The frame hugs the viewport rather than scrolling with the text — a real
/// page border is fixed to the page, and keeping it outside the scroll view
/// also means the reading-mode paragraph measurements never have to know it
/// exists. [contentInset] is how far the text must sit inside it.
class MushafFrame extends StatelessWidget {
  const MushafFrame({super.key});

  // Geometry of the frame, outermost first.
  static const _margin = 10.0;
  static const _outerStroke = 1.2;
  static const _gap = 4.0;
  static const _innerStroke = 2.6;
  static const _innerPadding = 16.0;

  /// The distance from the screen edge at which content is clear of the
  /// frame: margin, both rules and the gap between them, then breathing room.
  static const contentInset =
      _margin + _outerStroke + _gap + _innerStroke + _innerPadding;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return CustomPaint(
      painter: _MushafFramePainter(brightness),
      size: Size.infinite,
    );
  }
}

class _MushafFramePainter extends CustomPainter {
  const _MushafFramePainter(this.brightness);

  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = MushafColors.gold(brightness)
      ..style = PaintingStyle.stroke;

    final outer = Rect.fromLTWH(
      MushafFrame._margin,
      MushafFrame._margin,
      size.width - 2 * MushafFrame._margin,
      size.height - 2 * MushafFrame._margin,
    );
    canvas.drawRect(outer, gold..strokeWidth = MushafFrame._outerStroke);

    final inner = outer.deflate(
      MushafFrame._outerStroke + MushafFrame._gap + MushafFrame._innerStroke / 2,
    );
    canvas.drawRect(inner, gold..strokeWidth = MushafFrame._innerStroke);

    // The page itself.
    canvas.drawRect(
      inner.deflate(MushafFrame._innerStroke / 2),
      Paint()..color = MushafColors.page(brightness),
    );

    // A diamond-and-dot on each corner of the heavier rule, the way a
    // tooled border carries a rosette where its lines meet.
    final diamondSide = MushafFrame._innerStroke * 3.4;
    for (final corner in [inner.topLeft, inner.topRight, inner.bottomRight, inner.bottomLeft]) {
      final diamond = Path()
        ..moveTo(corner.dx, corner.dy - diamondSide)
        ..lineTo(corner.dx + diamondSide, corner.dy)
        ..lineTo(corner.dx, corner.dy + diamondSide)
        ..lineTo(corner.dx - diamondSide, corner.dy)
        ..close();
      canvas.drawPath(diamond, gold..strokeWidth = MushafFrame._outerStroke);
      canvas.drawCircle(
        corner,
        MushafFrame._outerStroke,
        Paint()..color = gold.color,
      );
    }
  }

  @override
  bool shouldRepaint(_MushafFramePainter old) => old.brightness != brightness;
}
