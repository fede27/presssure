import 'package:flutter_test/flutter_test.dart';

import 'package:presssure/main.dart';

void main() {
  testWidgets('Home page shows app title', (WidgetTester tester) async {
    await tester.pumpWidget(const PressSureApp());

    expect(find.text('PressSure'), findsOneWidget);
    expect(find.text('Diario della pressione'), findsOneWidget);
  });
}
