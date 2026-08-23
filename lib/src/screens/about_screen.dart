// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.engineVersion});

  /// Version of the native QQL library resolving the text.
  final String engineVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Column(
              children: [
                Text(
                  'Quran Reader',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'An open source Quran app',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const _Section('Initiated by'),
          const _Line('Mazhar Ahmed', emphasis: true),
          const _Line('BA in Islamic Studies from IOU'),
          const _Line('Dawra-e-hadith from Qawmi Madrasa, Bangladesh'),
          const Divider(height: 32),

          const _Section('Quran text'),
          _Line('Resolved by QQL $engineVersion, a query language '
              'for Islamic texts. The app holds no scripture of its own — '
              'every ayah on screen comes from a Q:<surah> query.'),
          const _Line('github.com/mazhar266/QQ-Lang'),
          const SizedBox(height: 10),
          // Tanzil's terms require the source to be named and linked, so this
          // is an obligation rather than a courtesy.
          const _Line(
            'Quran text: Tanzil Quran Text (Uthmani, version 1.1), '
            'Copyright (C) 2007-2026 Tanzil Project, used under Creative '
            'Commons Attribution 3.0. The text is included verbatim and '
            'unmodified.',
          ),
          const _Line('tanzil.net'),
          const Divider(height: 32),

          const _Section('Typefaces'),
          const _Line(
            'Uthmanic Hafs and QPC Hafs from the King Fahd Glorious Quran '
            'Printing Complex; Amiri Quran; Al Majeed, Al Mushaf, AlQuran '
            'IndoPak, Muhammadi and PDMS Saleem. Choose one under Settings, '
            'Arabic text.',
          ),
          const Divider(height: 32),

          const _Section('Licence'),
          const _Line(
            'Quran Reader is free software under the GNU General Public '
            'Licence, version 3 or later. You may redistribute and modify it '
            'under those terms.',
          ),
          const _Line('gnu.org/licenses/gpl-3.0.html'),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Distributed in the hope that it will be useful, but WITHOUT ANY '
              'WARRANTY; without even the implied warranty of MERCHANTABILITY '
              'or FITNESS FOR A PARTICULAR PURPOSE.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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

class _Line extends StatelessWidget {
  const _Line(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 2),
      child: SelectableText(
        text,
        style: emphasis
            ? theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    );
  }
}
