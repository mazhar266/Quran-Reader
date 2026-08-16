// Where the reader last was, so they can pick up from it.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last ayah the reader had in view.
@immutable
class ReadingPosition {
  const ReadingPosition({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) =>
      other is ReadingPosition && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);
}

/// Remembers the last reading position across launches.
///
/// Only one position is kept: the point of this is "carry on where I left
/// off", not a bookmark list.
class ReadingPositionStore extends ChangeNotifier {
  ReadingPositionStore._(this._prefs, this._position);

  static const _key = 'last_read';

  static Future<ReadingPositionStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReadingPositionStore._(prefs, _decode(prefs.getString(_key)));
  }

  final SharedPreferences _prefs;
  ReadingPosition? _position;

  ReadingPosition? get position => _position;

  /// Record that [ayah] of [surah] is in view.
  ///
  /// Called as the reader scrolls, so it returns early when nothing moved —
  /// otherwise every frame of a scroll would write to disk and rebuild.
  void record(int surah, int ayah) {
    if (_position?.surah == surah && _position?.ayah == ayah) return;
    _position = ReadingPosition(surah: surah, ayah: ayah);
    _prefs.setString(_key, '$surah:$ayah');
    notifyListeners();
  }

  void clear() {
    if (_position == null) return;
    _position = null;
    _prefs.remove(_key);
    notifyListeners();
  }

  static ReadingPosition? _decode(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;
    return ReadingPosition(surah: surah, ayah: ayah);
  }
}
