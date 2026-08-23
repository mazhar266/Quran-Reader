// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/src/screens/about_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    // The page is a lazy ListView, so a short test viewport would leave the
    // lower sections unbuilt and "not found" would mean nothing.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: AboutScreen(engineVersion: '0.1.0')),
    );
  }

  testWidgets('names the app and what it is', (tester) async {
    await pump(tester);
    expect(find.text('Quran Reader'), findsOneWidget);
    expect(find.text('An open source Quran app'), findsOneWidget);
  });

  testWidgets('credits the author with their qualifications', (tester) async {
    await pump(tester);
    expect(find.text('Mazhar Ahmed'), findsOneWidget);
    expect(find.text('BA in Islamic Studies from IOU'), findsOneWidget);
    expect(
      find.text('Dawra-e-hadith from Qawmi Madrasa, Bangladesh'),
      findsOneWidget,
    );
  });

  testWidgets('attributes the engine, data, font and licence', (tester) async {
    await pump(tester);
    // Attribution is a licence obligation for the text data, not decoration.
    expect(find.textContaining('QQL 0.1.0'), findsOneWidget);
    expect(find.textContaining('Tanzil Project'), findsOneWidget);
    expect(find.textContaining('King Fahd'), findsOneWidget);
    expect(find.textContaining('GNU General Public Licence'), findsOneWidget);
  });
}
