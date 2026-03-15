import 'package:flutter_test/flutter_test.dart';
import 'package:popgrid/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PopGridApp());
    expect(find.text('PopGrid'), findsOneWidget);
  });
}
