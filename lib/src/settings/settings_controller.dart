// User preferences, persisted with shared_preferences.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How much of an ayah to show.
enum ReadingMode {
  /// Arabic only, running on as one continuous page.
  reading('Reading', 'Arabic only, flowing like a book'),

  /// Arabic followed by its English translation, ayah by ayah.
  normal('Normal', 'Arabic with English');

  const ReadingMode(this.label, this.description);

  final String label;
  final String description;
}

/// The app's theme choices.
///
/// Flutter's own [ThemeMode] has no fourth value, and OLED needs one: it is a
/// dark theme driven to true black, which saves power on OLED screens because
/// black pixels are simply off. Persisted values from before OLED existed
/// ('system', 'light', 'dark') still map by name.
enum AppTheme {
  system('System', 'Follow the system setting'),
  light('Light', 'Always daylight paper'),
  dark('Dark', 'Always night paper'),
  oled('OLED', 'True black, saves power on OLED screens');

  const AppTheme(this.label, this.description);

  final String label;
  final String description;
}

/// A bundled Quranic typeface the reader can be set to.
///
/// Every one of these covers the bundled text, but they differ elsewhere: some
/// map U+0660-0669 to blank glyphs, which is why the ayah medallions are always
/// drawn in [medallionFontFamily] rather than in the selected face.
enum ArabicFont {
  uthmanicHafs('UthmanicHafs', 'Uthmanic Hafs (KFGQPC)'),
  qpcHafs('QpcHafs', 'QPC Hafs'),
  alMajeed('AlMajeed', 'Al Majeed'),
  alMushaf('AlMushaf', 'Al Mushaf'),
  indoPak('IndoPak', 'AlQuran IndoPak'),
  amiri('AmiriQuran', 'Amiri Quran'),
  muhammadi('Muhammadi', 'Muhammadi'),
  pdmsSaleem('PDMSSaleem', 'PDMS Saleem');

  const ArabicFont(this.family, this.label);

  /// Family name as declared in pubspec.yaml.
  final String family;
  final String label;

  static const fallback = ArabicFont.uthmanicHafs;

  static ArabicFont byFamily(String? family) => values.firstWhere(
        (f) => f.family == family,
        orElse: () => fallback,
      );
}

/// The face the ayah numbers are set in, whatever the reader has chosen for
/// the text. It draws U+0660-0669 as the ornamented mushaf medallions.
const medallionFontFamily = 'UthmanicHafs';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs)
      : _themeMode = AppTheme.values.byName(
          _prefs.getString(_kThemeMode) ?? AppTheme.system.name,
        ),
        _readingMode = ReadingMode.values.byName(
          _prefs.getString(_kReadingMode) ?? ReadingMode.normal.name,
        ),
        _arabicFont = ArabicFont.byFamily(_prefs.getString(_kArabicFont)),
        _arabicFontSize = _prefs.getDouble(_kArabicFontSize) ?? 28;

  static const _kThemeMode = 'theme_mode';
  static const _kReadingMode = 'reading_mode';
  static const _kArabicFont = 'arabic_font';
  static const _kArabicFontSize = 'arabic_font_size';

  /// Bounds for the Arabic size slider. English text is left alone — it
  /// follows the platform text scale like the rest of the UI.
  static const minArabicFontSize = 18.0;
  static const maxArabicFontSize = 56.0;

  static Future<SettingsController> load() async =>
      SettingsController._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  AppTheme _themeMode;
  ReadingMode _readingMode;
  ArabicFont _arabicFont;
  double _arabicFontSize;

  AppTheme get themeMode => _themeMode;

  /// What [AppTheme] means for `MaterialApp.themeMode`. OLED has no
  /// [ThemeMode] of its own; it is a dark theme driven to true black.
  ThemeMode get materialThemeMode => switch (_themeMode) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark || AppTheme.oled => ThemeMode.dark,
      };

  ReadingMode get readingMode => _readingMode;
  ArabicFont get arabicFont => _arabicFont;
  double get arabicFontSize => _arabicFontSize;

  set themeMode(AppTheme value) {
    if (value == _themeMode) return;
    _themeMode = value;
    _prefs.setString(_kThemeMode, value.name);
    notifyListeners();
  }

  set readingMode(ReadingMode value) {
    if (value == _readingMode) return;
    _readingMode = value;
    _prefs.setString(_kReadingMode, value.name);
    notifyListeners();
  }

  set arabicFont(ArabicFont value) {
    if (value == _arabicFont) return;
    _arabicFont = value;
    _prefs.setString(_kArabicFont, value.family);
    notifyListeners();
  }

  set arabicFontSize(double value) {
    final clamped = value.clamp(minArabicFontSize, maxArabicFontSize);
    if (clamped == _arabicFontSize) return;
    _arabicFontSize = clamped;
    _prefs.setDouble(_kArabicFontSize, clamped);
    notifyListeners();
  }

  /// The text style every Arabic ayah is rendered with.
  TextStyle arabicTextStyle(BuildContext context) => TextStyle(
        fontFamily: _arabicFont.family,
        fontSize: _arabicFontSize,
        // Quranic faces carry tall vowel marks; the default line height
        // clips them.
        height: 1.9,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

/// Puts the [SettingsController] in scope and rebuilds dependents on change.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SettingsScope>()!
      .notifier!;
}
