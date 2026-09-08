import 'package:flutter_test/flutter_test.dart';
import 'package:coder_flutter/main.dart';

void main() {
  testWidgets('Coder Flutter smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
