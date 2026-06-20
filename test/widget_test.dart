// Basic smoke test for the app shell and routing.

import 'package:flutter_test/flutter_test.dart';

import 'package:plantid_app/app.dart';

void main() {
  testWidgets('App launches and shows the home screen via the navbar', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantIdApp());
    await tester.pumpAndSettle();

    expect(find.text('UENR Flora'), findsOneWidget);
    expect(find.text('Identify every plant on campus — instantly'), findsOneWidget);
  });
}
