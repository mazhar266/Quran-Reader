// Plain data holders for the pieces of a QQL response the UI cares about.
//
// SPDX-License-Identifier: GPL-3.0-or-later

/// One entry of the 114-surah index, read from `assets/surah_index.json`.
class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.ayahCount,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['id'] as int,
        nameArabic: json['name'] as String,
        nameEnglish: json['transliteration'] as String,
        revelationType: json['type'] as String,
        ayahCount: json['total_verses'] as int,
      );

  final int number;
  final String nameArabic;
  final String nameEnglish;

  /// `meccan` or `medinan`, as spelled in the upstream data.
  final String revelationType;
  final int ayahCount;
}

/// One ayah, as returned by a `Q:<surah>` query.
class Ayah {
  const Ayah({
    required this.surah,
    required this.number,
    required this.arabic,
    required this.english,
  });

  factory Ayah.fromQql(Map<String, dynamic> record) => Ayah(
        surah: record['surah'] as int,
        number: record['ayah'] as int,
        arabic: record['ar'] as String,
        english: record['en'] as String? ?? '',
      );

  final int surah;
  final int number;
  final String arabic;
  final String english;
}
