// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/src/data/reading_position.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts with nothing recorded', () async {
    final store = await ReadingPositionStore.load();
    expect(store.position, isNull);
  });

  test('records and restores a position', () async {
    final store = await ReadingPositionStore.load();
    store.record(18, 47);
    expect(store.position, const ReadingPosition(surah: 18, ayah: 47));

    // A fresh store reads it back from disk.
    final reopened = await ReadingPositionStore.load();
    expect(reopened.position, const ReadingPosition(surah: 18, ayah: 47));
  });

  test('only notifies when the position actually moves', () async {
    final store = await ReadingPositionStore.load();
    var notifications = 0;
    store.addListener(() => notifications++);

    store.record(2, 10);
    store.record(2, 10); // same ayah, e.g. a scroll that stayed put
    expect(notifications, 1);

    store.record(2, 11);
    expect(notifications, 2);
  });

  test('clearing removes it', () async {
    final store = await ReadingPositionStore.load();
    store.record(3, 5);
    store.clear();
    expect(store.position, isNull);
    expect((await ReadingPositionStore.load()).position, isNull);
  });

  test('a corrupt stored value is ignored rather than thrown on', () async {
    SharedPreferences.setMockInitialValues({'last_read': 'not-a-position'});
    expect((await ReadingPositionStore.load()).position, isNull);

    SharedPreferences.setMockInitialValues({'last_read': '7:'});
    expect((await ReadingPositionStore.load()).position, isNull);
  });
}
