// The paper-mushaf palette and the themes built from it.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

/// The colours of a printed mushaf: cream paper, sepia ink, antique gold
/// tooling. Three sets — daylight paper, a warm "night paper" for dark mode,
/// and true black for OLED screens, where every lit pixel costs battery.
///
/// Widgets should not read these constants directly; they read the
/// [ColorScheme] roles the themes below fill (primary = gold, onSurface =
/// ink, surfaceContainerHighest = page, dividerColor = rule), so a new theme
/// only has to exist here to take effect everywhere.
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

  // OLED — true black, so unlit pixels draw no power. The ink is dimmed a
  // notch from night paper: full-strength warm white halates on black.
  static const paperOled = Color(0xFF000000);
  static const pageOled = Color(0xFF000000);
  static const inkOled = Color(0xFFCFC5AE);
  static const goldOled = goldDark;
}

/// The daylight-paper and night-paper themes.
ThemeData mushafTheme(Brightness brightness) => brightness == Brightness.dark
    ? _mushafTheme(
        brightness,
        paper: MushafColors.paperDark,
        page: MushafColors.pageDark,
        ink: MushafColors.inkDark,
        gold: MushafColors.goldDark,
      )
    : _mushafTheme(
        brightness,
        paper: MushafColors.paperLight,
        page: MushafColors.pageLight,
        ink: MushafColors.inkLight,
        gold: MushafColors.goldLight,
      );

/// The OLED theme: night paper with every background driven to true black.
ThemeData mushafOledTheme() => _mushafTheme(
      Brightness.dark,
      paper: MushafColors.paperOled,
      page: MushafColors.pageOled,
      ink: MushafColors.inkOled,
      gold: MushafColors.goldOled,
    );

/// One builder for all three themes keeps the schemes in the same shape —
/// only the palette differs.
ThemeData _mushafTheme(
  Brightness brightness, {
  required Color paper,
  required Color page,
  required Color ink,
  required Color gold,
}) {
  // The hairline the rules and separators are drawn with. Translucent so it
  // softens onto the paper instead of sitting on it as a hard edge.
  final rule = ink.withValues(alpha: brightness == Brightness.dark ? 0.35 : 0.28);

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
