// Tajwid rule detection for Uthmani Quranic text.
//
// This colours the places where a rule changes how a letter is pronounced. It
// is a reading aid, not a scholarly reference: it covers the rules that can be
// decided from the written form alone, and deliberately says nothing where
// that would take recitation knowledge it does not have. See the notes on
// [TajwidRule] for what is and is not detected.
//
// The rules are driven by the character inventory actually used by the bundled
// text, which matters in two places:
//
//   * Sukun is usually U+06E1 (SMALL HIGH DOTLESS HEAD OF KHAH), not U+0652.
//   * Iqlab is written explicitly, as U+06E2 or U+06ED, rather than left to be
//     inferred from a following beh.
//
// SPDX-License-Identifier: GPL-3.0-or-later

/// A rule of tajwid that this helper can recognise.
enum TajwidRule {
  /// Noon or meem carrying shadda — held with a nasal sound for two counts.
  ghunnah,

  /// Noon sakinah or tanween merging into a following ي ن م و, with ghunnah.
  idghamWithGhunnah,

  /// Noon sakinah or tanween merging into a following ل ر, without ghunnah.
  idghamWithoutGhunnah,

  /// Noon sakinah or tanween turning into a meem sound before beh.
  iqlab,

  /// Noon sakinah or tanween hidden before one of the fifteen ikhfa letters.
  ikhfa,

  /// Meem sakinah merging into a following meem.
  idghamShafawi,

  /// Meem sakinah hidden before beh.
  ikhfaShafawi,

  /// One of ق ط ب ج د carrying sukun — released with a slight echo.
  qalqalah,

  /// A letter carrying the maddah sign, held longer than a plain vowel.
  ///
  /// The written form does not distinguish the two-, four- and six-count
  /// lengths, so they are not separated here.
  madd,
}

/// Where a rule applies, as a range over the analysed string.
///
/// [start] is inclusive and [end] exclusive, both in UTF-16 code units so the
/// range can be used directly to slice the string.
class TajwidMatch {
  const TajwidMatch(this.start, this.end, this.rule);

  final int start;
  final int end;
  final TajwidRule rule;

  @override
  String toString() => '$rule[$start,$end)';
}

// --- Character classes ------------------------------------------------------

const _shadda = 'ّ';
const _maddah = 'ٓ';
const _sukunSigns = {'ْ', 'ۡ'};
const _tanween = {'ً', 'ٌ', 'ٍ'};
const _iqlabSigns = {'ۢ', 'ۭ'};

/// Marks that give a letter a vowel, so it is not sakin.
const _vowelSigns = {'َ', 'ُ', 'ِ', 'ٰ', 'ٖ', 'ٗ'};

const _noon = 'ن';
const _meem = 'م';
const _beh = 'ب';

/// Noon sakinah or tanween merges into these, keeping the nasal sound.
const _idghamGhunnahLetters = {'ي', 'ن', 'م', 'و'};

/// ...and into these without it.
const _idghamPlainLetters = {'ل', 'ر'};

/// The fifteen letters that hide a preceding noon sakinah or tanween.
const _ikhfaLetters = {
  'ت', 'ث', 'ج', 'د', 'ذ', 'ز', 'س',
  'ش', 'ص', 'ض', 'ط', 'ظ', 'ف', 'ق',
  'ك',
};

const _qalqalahLetters = {'ق', 'ط', 'ب', 'ج', 'د'};

/// True for the combining marks that hang off a letter rather than standing
/// as one. Waqf and sajdah signs count: they interrupt neither the letter nor
/// the rule that spans it.
bool _isMark(String ch) {
  final c = ch.codeUnitAt(0);
  // 0x064B-0x065F are the vowel and tanween marks; U+0670 is the superscript
  // alef. The gap between them is Arabic-Indic digits and separators, which
  // are not marks — the ayah numbers are set in those.
  return (c >= 0x064B && c <= 0x065F) ||
      c == 0x0670 ||
      (c >= 0x06D6 && c <= 0x06ED) ||
      c == 0x0640; // tatweel, a stretching glyph rather than a letter
}

/// One letter together with the marks written on it.
class _Unit {
  _Unit(this.letter, this.start, this.end, this.marks);

  final String letter;
  final int start;

  /// Exclusive, and past the letter's marks.
  final int end;
  final Set<String> marks;

  bool get hasShadda => marks.contains(_shadda);
  bool get hasSukun => marks.any(_sukunSigns.contains);
  bool get hasTanween => marks.any(_tanween.contains);
  bool get hasIqlabSign => marks.any(_iqlabSigns.contains);
  bool get hasVowel => marks.any(_vowelSigns.contains);

  /// A letter is sakin when it is marked so, or simply carries no vowel at
  /// all — which is how the bundled text writes the noon before idgham and
  /// ikhfa.
  bool get isSakin => hasSukun || (!hasVowel && !hasShadda && !hasTanween);
}

List<_Unit> _units(String text) {
  final units = <_Unit>[];
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (ch == ' ' || _isMark(ch)) {
      i++;
      continue;
    }
    final start = i;
    final marks = <String>{};
    var j = i + 1;
    while (j < text.length && _isMark(text[j])) {
      marks.add(text[j]);
      j++;
    }
    units.add(_Unit(ch, start, j, marks));
    i = j;
  }
  return units;
}

// --- Analysis ---------------------------------------------------------------

/// Find every rule that applies in [text].
///
/// Matches never overlap: where two rules could cover the same letter the
/// earlier-starting one wins, so the result can be turned straight into a run
/// of spans.
List<TajwidMatch> analyzeTajwid(String text) {
  final units = _units(text);
  final matches = <TajwidMatch>[];

  for (var i = 0; i < units.length; i++) {
    final unit = units[i];
    final next = i + 1 < units.length ? units[i + 1] : null;

    // Whether a space separates this letter from the next one. Idgham only
    // happens across that boundary — a noon followed by yeh or waw inside one
    // word is izhar mutlaq, and colouring it as idgham would be wrong.
    final acrossWords =
        next != null && text.substring(unit.end, next.start).contains(' ');

    final rule = _ruleFor(unit, next, acrossWords: acrossWords);
    if (rule != null) {
      matches.add(TajwidMatch(unit.start, unit.end, rule));
    }
  }

  return matches;
}

TajwidRule? _ruleFor(_Unit unit, _Unit? next, {required bool acrossWords}) {
  // Ghunnah and qalqalah are decided by the letter alone, so they come first.
  if ((unit.letter == _noon || unit.letter == _meem) && unit.hasShadda) {
    return TajwidRule.ghunnah;
  }
  if (_qalqalahLetters.contains(unit.letter) && unit.hasSukun) {
    return TajwidRule.qalqalah;
  }

  // Iqlab is written into the text, so it does not need to be inferred.
  if (unit.hasIqlabSign) return TajwidRule.iqlab;

  final triggersNoonRule =
      (unit.letter == _noon && unit.isSakin) || unit.hasTanween;
  if (triggersNoonRule && next != null) {
    final after = next.letter;
    if (acrossWords && _idghamGhunnahLetters.contains(after)) {
      return TajwidRule.idghamWithGhunnah;
    }
    if (acrossWords && _idghamPlainLetters.contains(after)) {
      return TajwidRule.idghamWithoutGhunnah;
    }
    if (after == _beh) return TajwidRule.iqlab;
    if (_ikhfaLetters.contains(after)) return TajwidRule.ikhfa;
    // Anything else is izhar, which is the default pronunciation and so is
    // left uncoloured.
  }

  if (unit.letter == _meem && unit.isSakin && next != null) {
    if (next.letter == _meem) return TajwidRule.idghamShafawi;
    if (next.letter == _beh) return TajwidRule.ikhfaShafawi;
  }

  // Checked last: a letter can carry maddah and still be, say, the noon of an
  // ikhfa, and the consonant rule is the more useful thing to show.
  if (unit.marks.contains(_maddah)) return TajwidRule.madd;

  return null;
}
