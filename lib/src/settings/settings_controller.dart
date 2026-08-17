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

/// The one bundled Arabic face, as declared in pubspec.yaml.
const arabicFontFamily = 'UthmanicHafs';

class SettingsController extends ChangeNotifier {
  SettingsController._(this._prefs)
      : _themeMode = ThemeMode.values.byName(
          _prefs.getString(_kThemeMode) ?? ThemeMode.system.name,
        ),
        _readingMode = ReadingMode.values.byName(
          _prefs.getString(_kReadingMode) ?? ReadingMode.normal.name,
        ),
        _arabicFontSize = _prefs.getDouble(_kArabicFontSize) ?? 28;

  static const _kThemeMode = 'theme_mode';
  static const _kReadingMode = 'reading_mode';
  static const _kArabicFontSize = 'arabic_font_size';

  /// Bounds for the Arabic size slider. English text is left alone — it
  /// follows the platform text scale like the rest of the UI.
  static const minArabicFontSize = 18.0;
  static const maxArabicFontSize = 56.0;

  static Future<SettingsController> load() async =>
      SettingsController._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  ThemeMode _themeMode;
  ReadingMode _readingMode;
  double _arabicFontSize;

  ThemeMode get themeMode => _themeMode;
  ReadingMode get readingMode => _readingMode;
  double get arabicFontSize => _arabicFontSize;

  set themeMode(ThemeMode value) {
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

  set arabicFontSize(double value) {
    final clamped = value.clamp(minArabicFontSize, maxArabicFontSize);
    if (clamped == _arabicFontSize) return;
    _arabicFontSize = clamped;
    _prefs.setDouble(_kArabicFontSize, clamped);
    notifyListeners();
  }

  /// The text style every Arabic ayah is rendered with.
  TextStyle arabicTextStyle(BuildContext context) => TextStyle(
        fontFamily: arabicFontFamily,
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
