// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../settings/settings_controller.dart';
import 'settings_screen.dart';
import 'surah_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key, required this.repository});

  final QuranRepository repository;

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

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final surahs = _visible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SettingsScreen(repository: widget.repository),
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
      body: ListView.builder(
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          final surah = surahs[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${surah.number}')),
            title: Text(surah.nameEnglish),
            subtitle: Text(
              '${_titleCase(surah.revelationType)} · '
              '${surah.ayahCount} ayah${surah.ayahCount == 1 ? '' : 's'}',
            ),
            trailing: Text(
              surah.nameArabic,
              style: settings.arabicTextStyle(context).copyWith(fontSize: 22),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SurahScreen(
                  repository: widget.repository,
                  surah: surah,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _titleCase(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
