import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gas_hop/main.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GasHopApp());

    // Verify that we start on the Favorites screen
    expect(find.text('Favorite Stations'), findsOneWidget);
  });
}
