// Bridges the app to the QQL native library.
//
// QQL resolves queries against JSON files on disk, but on Android and iOS the
// bundled data lives inside the app package where there is no real filesystem
// path. So the data is unpacked once into the app support directory, in the
// exact layout QQL expects, and the context is opened on that.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:path_provider/path_provider.dart';

import '../qql/qql.dart';
import 'models.dart';

/// Bump when the bundled data changes, to force a re-unpack on upgrade.
const _dataVersion = 1;

/// Prefix of the bundled QQL data inside the asset bundle. Everything under it
/// is unpacked with its relative path preserved.
const _assetPrefix = 'assets/qqldata/';

class QuranRepository {
  QuranRepository._(this._qql, this.surahs);

  final Qql _qql;

  /// The 114 surahs, in mushaf order.
  final List<Surah> surahs;

  /// Unpack the data if needed, then open a native context on it.
  static Future<QuranRepository> open() async {
    final dataDir = await _ensureDataUnpacked();
    final qql = Qql.open(dataDir.path);

    final indexJson = await rootBundle.loadString('assets/surah_index.json');
    final surahs = (jsonDecode(indexJson) as List)
        .cast<Map<String, dynamic>>()
        .map(Surah.fromJson)
        .toList(growable: false);

    return QuranRepository._(qql, surahs);
  }

  /// Native library version, shown on the settings page.
  String get engineVersion => _qql.version;

  /// Every ayah of [surah], in order.
  List<Ayah> surah(int surah) =>
      _qql.execute('Q:$surah').map(Ayah.fromQql).toList(growable: false);

  void dispose() => _qql.dispose();

  static Future<Directory> _ensureDataUnpacked() async {
    final support = await getApplicationSupportDirectory();
    final dataDir = Directory('${support.path}/qqldata');
    final stamp = File('${dataDir.path}/.version');

    if (await stamp.exists() &&
        await stamp.readAsString() == '$_dataVersion') {
      return dataDir;
    }

    // A stale unpack from an older data version would leave orphaned files
    // behind, so start clean rather than overwrite in place.
    if (await dataDir.exists()) {
      await dataDir.delete(recursive: true);
    }

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets =
        manifest.listAssets().where((k) => k.startsWith(_assetPrefix));

    for (final asset in assets) {
      final target = File(
        '${dataDir.path}/${asset.substring(_assetPrefix.length)}',
      );
      await target.parent.create(recursive: true);
      final bytes = await rootBundle.load(asset);
      await target.writeAsBytes(bytes.buffer.asUint8List(), flush: false);
    }

    await stamp.writeAsString('$_dataVersion');
    return dataDir;
  }
}
