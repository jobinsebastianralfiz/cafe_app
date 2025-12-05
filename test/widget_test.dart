// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cafe_app/app.dart';

void main() {
  testWidgets('Cafe App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CafeApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Cafe App'), findsOneWidget);
  });
}
