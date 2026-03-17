import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcash_pos/core/theme/ocean_theme.dart';

void main() {
  testWidgets('FishCash app smoke test', (WidgetTester tester) async {
    // Verify the theme can be built without errors
    await tester.pumpWidget(
      MaterialApp(
        theme: OceanTheme.light,
        darkTheme: OceanTheme.dark,
        home: const Scaffold(body: Center(child: Text('FishCash POS'))),
      ),
    );
    expect(find.text('FishCash POS'), findsOneWidget);
  });
}
