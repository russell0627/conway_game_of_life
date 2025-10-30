import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conway_game_of_life/main.dart';

void main() {
  testWidgets('App starts and displays initial UI', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the app bar title is correct.
    expect(find.text("Conway's Game of Life (Gen: 0)"), findsOneWidget);

    // Verify that the initial buttons are present.
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Step'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Verify the pattern dropdown is present
    expect(find.text('Select a Preset Pattern'), findsOneWidget);
  });
}
