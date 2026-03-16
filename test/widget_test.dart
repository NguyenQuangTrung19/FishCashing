import 'package:flutter_test/flutter_test.dart';
import 'package:fishcash_pos/app/app.dart';
import 'package:fishcash_pos/core/theme/theme_notifier.dart';

void main() {
  testWidgets('FishCash app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(FishCashApp(themeNotifier: ThemeNotifier()));
    expect(find.text('Tổng quan'), findsOneWidget);
  });
}
