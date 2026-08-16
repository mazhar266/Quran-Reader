// Turning tajwid matches into coloured spans.
//
// Kept apart from the rule engine so that [analyzeTajwid] stays pure Dart and
// can be tested without a Flutter binding.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'tajwid.dart';

/// The colour each rule is drawn in.
///
/// Two sets, because a hue with enough contrast on paper-white is usually
/// washed out on near-black and the other way round.
class TajwidPalette {
  const TajwidPalette._(this._colors);

  final Map<TajwidRule, Color> _colors;

  static const light = TajwidPalette._({
    TajwidRule.ghunnah: Color(0xFF1B7F3B),
    TajwidRule.idghamWithGhunnah: Color(0xFF15776A),
    TajwidRule.idghamWithoutGhunnah: Color(0xFF556B7D),
    TajwidRule.iqlab: Color(0xFF7B3FA0),
    TajwidRule.ikhfa: Color(0xFF1F5FA8),
    TajwidRule.idghamShafawi: Color(0xFF0F766E),
    TajwidRule.ikhfaShafawi: Color(0xFF3F51B5),
    TajwidRule.qalqalah: Color(0xFFA35400),
    TajwidRule.madd: Color(0xFFB3261E),
  });

  static const dark = TajwidPalette._({
    TajwidRule.ghunnah: Color(0xFF6EE7A0),
    TajwidRule.idghamWithGhunnah: Color(0xFF5FD6C4),
    TajwidRule.idghamWithoutGhunnah: Color(0xFFA8BACB),
    TajwidRule.iqlab: Color(0xFFC79BE8),
    TajwidRule.ikhfa: Color(0xFF7FB6F5),
    TajwidRule.idghamShafawi: Color(0xFF5EEAD4),
    TajwidRule.ikhfaShafawi: Color(0xFF9FA8F5),
    TajwidRule.qalqalah: Color(0xFFF5B871),
    TajwidRule.madd: Color(0xFFFF9A90),
  });

  static TajwidPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  Color colorOf(TajwidRule rule) => _colors[rule]!;
}

/// A human-readable name for each rule, for the settings legend.
String tajwidRuleLabel(TajwidRule rule) => switch (rule) {
      TajwidRule.ghunnah => 'Ghunnah',
      TajwidRule.idghamWithGhunnah => 'Idgham with ghunnah',
      TajwidRule.idghamWithoutGhunnah => 'Idgham without ghunnah',
      TajwidRule.iqlab => 'Iqlab',
      TajwidRule.ikhfa => 'Ikhfa',
      TajwidRule.idghamShafawi => 'Idgham shafawi',
      TajwidRule.ikhfaShafawi => 'Ikhfa shafawi',
      TajwidRule.qalqalah => 'Qalqalah',
      TajwidRule.madd => 'Madd',
    };

/// Split [text] into spans, colouring the stretches where a rule applies.
///
/// The spans carry only a colour, so the caller's Arabic style — family, size,
/// line height — still governs the whole run.
List<InlineSpan> tajwidSpans(String text, TajwidPalette palette) {
  final matches = analyzeTajwid(text);
  if (matches.isEmpty) return [TextSpan(text: text)];

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: TextStyle(color: palette.colorOf(match.rule)),
    ));
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}
