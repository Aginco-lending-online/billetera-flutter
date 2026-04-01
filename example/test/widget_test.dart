import 'package:billetera_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra botón Abrir billetera', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Abrir billetera'), findsOneWidget);
  });
}
