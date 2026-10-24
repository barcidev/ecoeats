import 'package:ecoeats/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the EcoEats placeholder', (tester) async {
    await tester.pumpWidget(const EcoEatsApp());

    expect(find.text('EcoEats'), findsOneWidget);
  });
}
