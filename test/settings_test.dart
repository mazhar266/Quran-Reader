// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/src/data/models.dart';
import 'package:quran_reader/src/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts on the system theme in normal mode', () async {
      final settings = await SettingsController.load();
      expect(settings.themeMode.name, 'system');
      expect(settings.readingMode, ReadingMode.normal);
      expect(settings.arabicFont, ArabicFont.system);
    });

    test('restores what was persisted', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'reading_mode': 'reading',
        'arabic_font': 'Muhammadi',
        'arabic_font_size': 42.0,
      });
      final settings = await SettingsController.load();
      expect(settings.themeMode.name, 'dark');
      expect(settings.readingMode, ReadingMode.reading);
      expect(settings.arabicFont.label, 'Muhammadi Quranic');
      expect(settings.arabicFontSize, 42.0);
    });

    test('clamps the Arabic size to the slider bounds', () async {
      final settings = await SettingsController.load();
      settings.arabicFontSize = 500;
      expect(settings.arabicFontSize, SettingsController.maxArabicFontSize);
      settings.arabicFontSize = 1;
      expect(settings.arabicFontSize, SettingsController.minArabicFontSize);
    });

    test('an unknown persisted font falls back to the system face', () async {
      SharedPreferences.setMockInitialValues({'arabic_font': 'Removed'});
      final settings = await SettingsController.load();
      expect(settings.arabicFont, ArabicFont.system);
    });

    test('notifies only on a real change', () async {
      final settings = await SettingsController.load();
      var notifications = 0;
      settings.addListener(() => notifications++);

      settings.readingMode = ReadingMode.reading;
      settings.readingMode = ReadingMode.reading;
      expect(notifications, 1);
    });
  });

  group('models', () {
    test('Surah reads the upstream index shape', () {
      final surah = Surah.fromJson({
        'id': 2,
        'name': 'البقرة',
        'transliteration': 'Al-Baqarah',
        'type': 'medinan',
        'total_verses': 286,
      });
      expect(surah.number, 2);
      expect(surah.nameEnglish, 'Al-Baqarah');
      expect(surah.ayahCount, 286);
    });

    test('Ayah reads a QQL record', () {
      final ayah = Ayah.fromQql({
        'ar': 'ٱلۡحَمۡدُ لِلَّهِ',
        'en': 'All praise is due to Allah',
        'ayah': 2,
        'surah': 1,
        'source': 'Q',
      });
      expect(ayah.surah, 1);
      expect(ayah.number, 2);
      expect(ayah.english, 'All praise is due to Allah');
    });

    test('Ayah tolerates a record with no translation', () {
      final ayah = Ayah.fromQql({'ar': 'الم', 'ayah': 1, 'surah': 2});
      expect(ayah.english, isEmpty);
    });
  });
}
