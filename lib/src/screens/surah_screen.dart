// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../qql/qql.dart';
import '../settings/settings_controller.dart';

class SurahScreen extends StatefulWidget {
  const SurahScreen({
    super.key,
    required this.repository,
    required this.surah,
  });

  final QuranRepository repository;
  final Surah surah;

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Ayah>? _ayahs;
  Object? _error;

  @override
  void initState() {
    super.initState();
    try {
      _ayahs = widget.repository.surah(widget.surah.number);
    } on QqlException catch (e) {
      _error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.surah.nameEnglish),
            Text(
              '${widget.surah.ayahCount} ayahs',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          // The mode is a global setting, but flipping it is the single most
          // common thing to do while reading, so it also lives up here.
          IconButton(
            icon: Icon(
              settings.readingMode == ReadingMode.reading
                  ? Icons.translate_outlined
                  : Icons.subject_outlined,
            ),
            tooltip: settings.readingMode == ReadingMode.reading
                ? 'Show translation'
                : 'Arabic only',
            onPressed: () => settings.readingMode =
                settings.readingMode == ReadingMode.reading
                    ? ReadingMode.normal
                    : ReadingMode.reading,
          ),
        ],
      ),
      body: _body(settings),
    );
  }

  Widget _body(SettingsController settings) {
    if (_error != null) {
      return Center(child: Text('Could not load this surah.\n$_error'));
    }
    final ayahs = _ayahs!;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: ayahs.length,
      separatorBuilder: (_, _) => const Divider(height: 28),
      itemBuilder: (context, index) => _AyahTile(
        ayah: ayahs[index],
        mode: settings.readingMode,
        arabicStyle: settings.arabicTextStyle(context),
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.mode,
    required this.arabicStyle,
  });

  final Ayah ayah;
  final ReadingMode mode;
  final TextStyle arabicStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The number rides at the end of the Arabic line so it reads as part
        // of the mushaf rather than as a list bullet.
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ayah.arabic),
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _AyahMarker(number: ayah.number),
                ),
              ],
            ),
            style: arabicStyle,
            textAlign: TextAlign.justify,
          ),
        ),
        if (mode == ReadingMode.normal) ...[
          const SizedBox(height: 12),
          Text(
            '${ayah.number}. ${ayah.english}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

}

/// The end-of-ayah marker.
///
/// U+06DD (ARABIC END OF AYAH) is the typographically correct character, but
/// none of the bundled Quranic faces compose digits inside it — the number
/// disappears and an empty circle is left behind. Drawing the ring ourselves
/// and setting the digits in the UI font renders the same idea in any face.
class _AyahMarker extends StatelessWidget {
  const _AyahMarker({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$number',
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 12, height: 1.1, color: color),
      ),
    );
  }
}
