import 'package:billetera_flutter/billetera_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Con parametros invalidos la pantalla no llega a crear el WebViewController,
// asi que se puede montar en tests sin canal nativo.
const _invalid = BilleteraLaunchParams(dni: '123');

Widget _host(BilleteraWidgetConfig config) => MaterialApp(
      home: BilleteraWebViewScreen(config: config, params: _invalid),
    );

void main() {
  testWidgets('muestra el error de parámetros en vez del WebView',
      (tester) async {
    await tester.pumpWidget(
      _host(const BilleteraWidgetConfig(baseUrl: 'https://w.example.com')),
    );
    expect(find.text('DNI debe tener entre 7 y 8 dígitos'), findsOneWidget);
  });

  testWidgets('el AppBar se muestra por defecto y se puede ocultar',
      (tester) async {
    await tester.pumpWidget(
      _host(const BilleteraWidgetConfig(baseUrl: 'https://w.example.com')),
    );
    expect(find.text('Billetera'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const BilleteraWidgetConfig(
          baseUrl: 'https://w.example.com',
          showAppBar: false,
        ),
      ),
    );
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('una baseUrl inválida se reporta antes de abrir el WebView',
      (tester) async {
    await tester.pumpWidget(_host(const BilleteraWidgetConfig(baseUrl: '')));
    expect(find.text('La URL base no puede estar vacía'), findsOneWidget);
  });
}
