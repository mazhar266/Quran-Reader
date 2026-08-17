// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/src/data/models.dart';
import 'package:quran_reader/src/screens/surah_title.dart';

/// The basmalah as the heading writes it, matching 1:1 of the bundled text.
const _basmalah = '\u0628\u0650\u0633\u06E1\u0645\u0650\u0020\u0671\u0644\u0644\u0651\u064E\u0647\u0650\u0020\u0671\u0644\u0631\u0651\u064E\u062D\u06E1\u0645\u064E\u0670\u0646\u0650\u0020\u0671\u0644\u0631\u0651\u064E\u062D\u0650\u064A\u0645\u0650';

Surah _surah(int number, String nameArabic) => Surah(
      number: number,
      nameArabic: nameArabic,
      nameEnglish: 'x',
      revelationType: 'meccan',
      ayahCount: 7,
    );

Future<List<String>> textsOf(WidgetTester tester, Surah surah) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SurahHeading(surah: surah))),
  );
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();
}

void main() {
  testWidgets('the name is prefixed with سورة', (tester) async {
    final texts = await textsOf(tester, _surah(2, 'البقرة'));
    expect(texts, contains('سُورَة البقرة'));
  });

  testWidgets('the basmalah is set in the same orthography as the text',
      (tester) async {
    expect(await textsOf(tester, _surah(2, 'البقرة')), contains(_basmalah));
  });

  testWidgets('Al-Fatihah does not repeat the basmalah', (tester) async {
    // It is already ayah 1 of the text.
    expect(
      await textsOf(tester, _surah(1, 'الفاتحة')),
      isNot(contains(_basmalah)),
    );
  });

  testWidgets('At-Tawbah has no basmalah at all', (tester) async {
    expect(
      await textsOf(tester, _surah(9, 'التوبة')),
      isNot(contains(_basmalah)),
    );
  });
}
