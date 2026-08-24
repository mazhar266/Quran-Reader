// The paper-mushaf palette and the themes built from it.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

/// The colours of a printed mushaf: cream paper, sepia ink, antique gold
/// tooling. Two sets — daylight paper, and a warm "night paper" for dark mode
/// that keeps the same hues rather than going blue-grey.
///
/// The painters in mushaf_frame.dart and the screens draw from these directly
/// where a ColorScheme role would be a lie (gold rules are not "primary"),
/// and the [ThemeData] roles are derived from them for everything else.
abstract final class MushafColors {
  // Light — daylight paper.
  static const paperLight = Color(0xFFF5EEDC);
  static const pageLight = Color(0xFFFCF7E8);
  static const inkLight = Color(0xFF3B2F1E);
  static const goldLight = Color(0xFF8A6D1F);

  // Dark — night paper: lamplight on old stock, not slate.
  static const paperDark = Color(0xFF1E1A14);
  static const pageDark = Color(0xFF292219);
  static const inkDark = Color(0xFFE9DFC4);
  static const goldDark = Color(0xFFC8A94B);

  static Color paper(Brightness b) =>
      b == Brightness.dark ? paperDark : paperLight;
  static Color page(Brightness b) => b == Brightness.dark ? pageDark : pageLight;
  static Color ink(Brightness b) => b == Brightness.dark ? inkDark : inkLight;
  static Color gold(Brightness b) => b == Brightness.dark ? goldDark : goldLight;

  /// The hairline the rules and separators are drawn with. Translucent so it
  /// softens onto the paper instead of sitting on it as a hard edge.
  static Color rule(Brightness b) =>
      ink(b).withValues(alpha: b == Brightness.dark ? 0.35 : 0.28);
}

/// The app theme. One builder for both brightnesses keeps the two schemes in
/// the same shape — only the palette flips.
ThemeData mushafTheme(Brightness brightness) {
  final paper = MushafColors.paper(brightness);
  final page = MushafColors.page(brightness);
  final ink = MushafColors.ink(brightness);
  final gold = MushafColors.gold(brightness);
  final rule = MushafColors.rule(brightness);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: gold,
    onPrimary: paper,
    // The gilt strip (resume banner) and selected chips.
    primaryContainer: gold.withValues(alpha: 0.14),
    onPrimaryContainer: ink,
    secondary: gold,
    onSecondary: paper,
    secondaryContainer: gold.withValues(alpha: 0.14),
    onSecondaryContainer: ink,
    tertiary: gold,
    onTertiary: paper,
    error: brightness == Brightness.dark
        ? const Color(0xFFE08A7A)
        : const Color(0xFF9C3B2E),
    onError: paper,
    surface: paper,
    onSurface: ink,
    onSurfaceVariant: ink.withValues(alpha: 0.72),
    surfaceContainerHighest: page,
    outline: rule,
    outlineVariant: rule.withValues(alpha: 0.5),
    shadow: Colors.black,
    inverseSurface: ink,
    onInverseSurface: paper,
    inversePrimary: gold,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    dividerColor: rule,
    // A mushaf page casts no shadow; the frame is the elevation.
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: page,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(page),
      hintStyle: WidgetStatePropertyAll(
        TextStyle(color: ink.withValues(alpha: 0.55)),
      ),
    ),
    iconTheme: IconThemeData(color: ink),
    sliderTheme: SliderThemeData(
      activeTrackColor: gold,
      thumbColor: gold,
      inactiveTrackColor: rule,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: gold),
  );
}
