// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/quran_repository.dart';
import '../settings/settings_controller.dart';
import '../tajwid/tajwid.dart';
import '../tajwid/tajwid_style.dart';
import 'about_screen.dart';

/// A short, well-known ayah to preview the Arabic font choices against.
const _previewAyah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.repository});

  final QuranRepository repository;

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.themeMode)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) =>
                  settings.themeMode = selection.first,
            ),
          ),
          const Divider(),

          const _SectionHeader('Reading'),
          RadioGroup<ReadingMode>(
            groupValue: settings.readingMode,
            onChanged: (value) => settings.readingMode = value!,
            child: Column(
              children: [
                for (final mode in ReadingMode.values)
                  RadioListTile<ReadingMode>(
                    value: mode,
                    title: Text(mode.label),
                    subtitle: Text(mode.description),
                  ),
              ],
            ),
          ),
          const Divider(),

          const _SectionHeader('Arabic text'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _previewAyah,
                  style: settings.arabicTextStyle(context),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Size'),
            trailing: Text(settings.arabicFontSize.round().toString()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Slider(
              value: settings.arabicFontSize,
              min: SettingsController.minArabicFontSize,
              max: SettingsController.maxArabicFontSize,
              divisions: (SettingsController.maxArabicFontSize -
                      SettingsController.minArabicFontSize)
                  .round(),
              label: settings.arabicFontSize.round().toString(),
              onChanged: (value) => settings.arabicFontSize = value,
            ),
          ),
          const Divider(),

          const _SectionHeader('Tajwid colours'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Arabic is coloured where a rule changes how a letter is '
              'pronounced. Rules that cannot be decided from the written '
              'form are left uncoloured.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (final rule in TajwidRule.values)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: TajwidPalette.of(context).colorOf(rule),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(tajwidRuleLabel(rule)),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Credits, sources and licence'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AboutScreen(engineVersion: repository.engineVersion),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follow the system setting',
        ThemeMode.light => 'Always light',
        ThemeMode.dark => 'Always dark',
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}
