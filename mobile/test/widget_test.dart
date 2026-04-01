import 'package:flutter_test/flutter_test.dart';
import 'package:rentgo_mobile/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const RenTGOApp());
    expect(find.byType(RenTGOApp), findsOneWidget);
  });
}
