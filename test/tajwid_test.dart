// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/src/tajwid/tajwid.dart';

/// The rules found in [text], in order.
List<TajwidRule> rulesIn(String text) =>
    analyzeTajwid(text).map((m) => m.rule).toList();

/// The substrings each rule was matched on, for the given rule.
List<String> matchedText(String text, TajwidRule rule) => analyzeTajwid(text)
    .where((m) => m.rule == rule)
    .map((m) => text.substring(m.start, m.end))
    .toList();

void main() {
  group('ghunnah', () {
    test('noon with shadda', () {
      // إِنَّ — noon mushaddad
      expect(rulesIn('إِنَّ'), contains(TajwidRule.ghunnah));
    });

    test('meem with shadda', () {
      // ثُمَّ — meem mushaddad
      expect(rulesIn('ثُمَّ'), contains(TajwidRule.ghunnah));
    });

    test('a plain noon is not ghunnah', () {
      expect(rulesIn('نَعۡبُدُ'), isNot(contains(TajwidRule.ghunnah)));
    });
  });

  group('noon sakinah and tanween', () {
    test('idgham with ghunnah across a word boundary', () {
      // مَن يَقُولُ (2:8) — bare noon, then yeh in the next word.
      expect(
        rulesIn('مَن يَقُولُ'),
        contains(TajwidRule.idghamWithGhunnah),
      );
    });

    test('idgham without ghunnah before reh', () {
      // مِّن رَّبِّهِمۡ (2:5)
      expect(
        rulesIn('مِّن رَّبِّهِمۡ'),
        contains(TajwidRule.idghamWithoutGhunnah),
      );
    });

    test('noon then yeh inside one word is izhar, not idgham', () {
      // ٱلدُّنۡيَا — the classic izhar mutlaq case. Colouring this as idgham
      // is the mistake a word-boundary-blind rule makes.
      expect(
        rulesIn('ٱلدُّنۡيَا'),
        isNot(contains(TajwidRule.idghamWithGhunnah)),
      );
    });

    test('ikhfa before feh', () {
      // أَنفُسَهُمۡ (2:9)
      expect(rulesIn('أَنفُسَهُمۡ'), contains(TajwidRule.ikhfa));
    });

    test('iqlab is read from the written sign', () {
      // عَلِيمُۢ بِمَا (2:10) — U+06E2 marks the iqlab.
      expect(rulesIn('عَلِيمُۢ بِمَا'), contains(TajwidRule.iqlab));
    });

    test('izhar letters are left uncoloured', () {
      // مِنۡ هَادٍ — noon sakinah before heh is izhar.
      final rules = rulesIn('مِنۡ هَادٍ');
      expect(rules, isNot(contains(TajwidRule.ikhfa)));
      expect(rules, isNot(contains(TajwidRule.idghamWithGhunnah)));
    });
  });

  group('meem sakinah', () {
    test('idgham shafawi before another meem', () {
      expect(rulesIn('لَهُمۡ مَّا'), contains(TajwidRule.idghamShafawi));
    });

    test('ikhfa shafawi before beh', () {
      expect(rulesIn('هُمۡ بِهِۦ'), contains(TajwidRule.ikhfaShafawi));
    });
  });

  group('qalqalah', () {
    test('qaf with sukun', () {
      // رَزَقۡنَٰهُمۡ (2:3)
      expect(rulesIn('رَزَقۡنَٰ'), contains(TajwidRule.qalqalah));
      expect(matchedText('رَزَقۡنَٰ', TajwidRule.qalqalah).first, startsWith('ق'));
    });

    test('a vowelled qalqalah letter is not qalqalah', () {
      expect(rulesIn('قَالَ'), isNot(contains(TajwidRule.qalqalah)));
    });
  });

  group('madd', () {
    test('the maddah sign is detected', () {
      // 2:1 الٓمٓ — the data writes madd as a separate U+0653, never as the
      // precomposed U+0622, so the rule keys off the combining mark.
      expect(rulesIn('\u0627\u0644\u0653\u0645\u0653'),
          contains(TajwidRule.madd));
    });

    test('a letter with no maddah sign is not madd', () {
      expect(rulesIn('\u0644\u064E\u0627'), isNot(contains(TajwidRule.madd)));
    });
  });

  group('span integrity', () {
    const ayah = 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ';

    test('matches never overlap and stay in order', () {
      final matches = analyzeTajwid(ayah);
      for (var i = 1; i < matches.length; i++) {
        expect(matches[i].start, greaterThanOrEqualTo(matches[i - 1].end));
      }
    });

    test('every match lies inside the string', () {
      for (final m in analyzeTajwid(ayah)) {
        expect(m.start, inInclusiveRange(0, ayah.length));
        expect(m.end, inInclusiveRange(m.start + 1, ayah.length));
      }
    });

    test('empty text yields nothing', () {
      expect(analyzeTajwid(''), isEmpty);
    });
  });
}
