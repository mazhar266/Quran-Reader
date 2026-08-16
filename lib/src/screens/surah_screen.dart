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
    _load();
  }

  @override
  void didUpdateWidget(SurahScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Navigating pushes a fresh route, so in practice this only fires if the
    // same screen is rebuilt pointing at another surah. Without it the text
    // would stay on the old surah while the title changed.
    if (widget.surah.number != oldWidget.surah.number) {
      _load();
    }
  }

  void _load() {
    try {
      _ayahs = widget.repository.surah(widget.surah.number);
      _error = null;
    } on QqlException catch (e) {
      _ayahs = null;
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
    final arabicStyle = settings.arabicTextStyle(context);

    if (settings.readingMode == ReadingMode.reading) {
      return _ContinuousPage(ayahs: ayahs, arabicStyle: arabicStyle);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: ayahs.length,
      separatorBuilder: (_, _) => const Divider(height: 28),
      itemBuilder: (context, index) => _AyahTile(
        ayah: ayahs[index],
        arabicStyle: arabicStyle,
      ),
    );
  }
}

/// Reading mode: the whole surah set as one running page.
///
/// Ayahs are not laid out one per line — each continues from where the last
/// ended, separated only by its marker, so the text wraps like a mushaf rather
/// than a list. That means one paragraph for the entire surah, which is also
/// why this cannot be a lazy ListView: the line breaks depend on every ayah
/// before it.
class _ContinuousPage extends StatelessWidget {
  const _ContinuousPage({required this.ayahs, required this.arabicStyle});

  final List<Ayah> ayahs;
  final TextStyle arabicStyle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(
            children: [
              for (final ayah in ayahs) ...[
                TextSpan(text: ayah.arabic),
                _ayahMarker(context, ayah.number),
              ],
            ],
          ),
          style: arabicStyle,
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}

/// Normal mode: one ayah, then its translation.
class _AyahTile extends StatelessWidget {
  const _AyahTile({required this.ayah, required this.arabicStyle});

  final Ayah ayah;
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
                _ayahMarker(context, ayah.number),
              ],
            ),
            style: arabicStyle,
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${ayah.number}. ${ayah.english}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

}

/// The end-of-ayah marker, as a span rather than a widget.
///
/// Two constraints shape this. U+06DD (ARABIC END OF AYAH) is the correct
/// character, but the bundled faces draw it as an empty ring and do not
/// compose the following digits inside it, so the number vanishes. And a
/// WidgetSpan cannot stand in for it either: reading mode puts every ayah of
/// the surah in one RTL paragraph, and Flutter matches multiple placeholders
/// to their boxes in visual rather than logical order there, which numbers the
/// ayahs backwards. Ornate parentheses around the number are plain text, so
/// they order correctly and every bundled face draws them.
///
/// The digits are Western rather than Arabic-Indic on purpose: Al Majeed and
/// PDMS Saleem both list U+0660-0669 in their cmap but map them to blank
/// glyphs, so the number disappears. All three faces draw 0-9.
TextSpan _ayahMarker(BuildContext context, int number) => TextSpan(
      text: ' \uFD3E$number\uFD3F ',
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    );
