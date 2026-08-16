// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../data/reading_position.dart';
import '../settings/settings_controller.dart';
import 'settings_screen.dart';
import 'surah_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({
    super.key,
    required this.repository,
    required this.positions,
  });

  final QuranRepository repository;
  final ReadingPositionStore positions;

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _filter = '';

  List<Surah> get _visible {
    if (_filter.isEmpty) return widget.repository.surahs;
    final needle = _filter.toLowerCase();
    return widget.repository.surahs.where((s) {
      return s.nameEnglish.toLowerCase().contains(needle) ||
          s.nameArabic.contains(_filter) ||
          '${s.number}' == needle;
    }).toList(growable: false);
  }

  void _open(Surah surah, {int? atAyah}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SurahScreen(
          repository: widget.repository,
          surah: surah,
          positions: widget.positions,
          startAtAyah: atAyah,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(repository: widget.repository),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SearchBar(
              hintText: 'Search surah',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _filter = value.trim()),
            ),
          ),
        ),
      ),
      // Rebuilds as the stored position changes, so the marker follows the
      // reader without the list having to be reopened.
      body: ListenableBuilder(
        listenable: widget.positions,
        builder: (context, _) {
          final last = widget.positions.position;
          final surahs = _visible;

          return Column(
            children: [
              if (last != null && _filter.isEmpty)
                _ResumeBanner(
                  surah: widget.repository.surahs[last.surah - 1],
                  ayah: last.ayah,
                  onTap: () => _open(
                    widget.repository.surahs[last.surah - 1],
                    atAyah: last.ayah,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, index) {
                    final surah = surahs[index];
                    final isLast = surah.number == last?.surah;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${surah.number}')),
                      title: Row(
                        children: [
                          Flexible(child: Text(surah.nameEnglish)),
                          if (isLast) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.bookmark,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        isLast
                            ? 'Last read · ayah ${last!.ayah}'
                            : '${_titleCase(surah.revelationType)} · '
                                '${surah.ayahCount} ayah'
                                '${surah.ayahCount == 1 ? '' : 's'}',
                      ),
                      trailing: Text(
                        surah.nameArabic,
                        style: settings
                            .arabicTextStyle(context)
                            .copyWith(fontSize: 22),
                      ),
                      // Tapping the marked surah resumes; tapping any other
                      // starts it from the beginning.
                      onTap: () => _open(
                        surah,
                        atAyah: isLast ? last!.ayah : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// The "carry on from where you left off" strip above the list.
class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.surah,
    required this.ayah,
    required this.onTap,
  });

  final Surah surah;
  final int ayah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue reading',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    Text(
                      '${surah.nameEnglish} · ayah $ayah',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
