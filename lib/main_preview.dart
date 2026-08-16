// Temporary screenshot harness — delete after verifying.
import 'dart:async';

import 'package:flutter/material.dart';

import 'src/data/quran_repository.dart';
import 'src/data/reading_position.dart';
import 'src/screens/settings_screen.dart';
import 'src/screens/surah_list_screen.dart';
import 'src/screens/surah_screen.dart';
import 'src/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  settings.arabicFont = ArabicFont.all[2];
  settings.readingMode = ReadingMode.reading;
  final repo = await QuranRepository.open();
  final positions = await ReadingPositionStore.load();
  positions.record(2, 40);

  // reading -> normal -> the surah list with its resume banner
  final step = ValueNotifier(0);
  Timer(const Duration(seconds: 8), () {
    settings.readingMode = ReadingMode.normal;
    step.value = 1;
  });
  Timer(const Duration(seconds: 16), () => step.value = 3);

  runApp(
    SettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: Listenable.merge([settings, step]),
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00695C),
              brightness: Brightness.dark,
            ),
          ),
          home: step.value == 3
              ? SettingsScreen(repository: repo)
              : SurahScreen(
                  repository: repo,
                  surah: repo.surahs[1],
                  positions: positions,
                  startAtAyah: 40,
                ),
        ),
      ),
    ),
  );
}
