// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'src/data/quran_repository.dart';
import 'src/data/reading_position.dart';
import 'src/mushaf/mushaf_theme.dart';
import 'src/screens/surah_list_screen.dart';
import 'src/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  final positions = await ReadingPositionStore.load();
  runApp(QuranReaderApp(settings: settings, positions: positions));
}

class QuranReaderApp extends StatefulWidget {
  const QuranReaderApp({
    super.key,
    required this.settings,
    required this.positions,
  });

  final SettingsController settings;
  final ReadingPositionStore positions;

  @override
  State<QuranReaderApp> createState() => _QuranReaderAppState();
}

class _QuranReaderAppState extends State<QuranReaderApp> {
  // Unpacking the bundled data and opening the native context happens once,
  // for the life of the app.
  late final Future<QuranRepository> _repository = QuranRepository.open();

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      controller: widget.settings,
      child: AnimatedBuilder(
        animation: widget.settings,
        builder: (context, _) => MaterialApp(
          title: 'Quran Reader',
          debugShowCheckedModeBanner: false,
          themeMode: widget.settings.themeMode,
          theme: mushafTheme(Brightness.light),
          darkTheme: mushafTheme(Brightness.dark),
          home: _Loader(repository: _repository, positions: widget.positions),
        ),
      ),
    );
  }
}

/// Holds the first frame until the repository is ready, and shows why if it
/// never becomes ready.
class _Loader extends StatelessWidget {
  const _Loader({required this.repository, required this.positions});

  final Future<QuranRepository> repository;
  final ReadingPositionStore positions;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranRepository>(
      future: repository,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error!);
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return SurahListScreen(
          repository: snapshot.data!,
          positions: positions,
        );
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not open the Quran data.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
