import 'package:flutter_test/flutter_test.dart';
import 'package:fishcash_pos/app/app.dart';

void main() {
  testWidgets('FishCash app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FishCashApp());
    expect(find.text('Tổng quan'), findsOneWidget);
  });
}
