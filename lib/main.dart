// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import 'src/data/quran_repository.dart';
import 'src/screens/surah_list_screen.dart';
import 'src/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsController.load();
  runApp(QuranReaderApp(settings: settings));
}

class QuranReaderApp extends StatefulWidget {
  const QuranReaderApp({super.key, required this.settings});

  final SettingsController settings;

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
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: _Loader(repository: _repository),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: brightness,
        ),
      );
}

/// Holds the first frame until the repository is ready, and shows why if it
/// never becomes ready.
class _Loader extends StatelessWidget {
  const _Loader({required this.repository});

  final Future<QuranRepository> repository;

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
        return SurahListScreen(repository: snapshot.data!);
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
