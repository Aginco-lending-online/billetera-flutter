import 'package:billetera_flutter/billetera_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billetera ejemplo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Billetera ejemplo')),
        body: Center(
          child: FilledButton(
            onPressed: () async {
              // QA por defecto; override: --dart-define=WIDGET_BASE_URL=http://10.0.2.2:4200
              const config = BilleteraWidgetConfig(
                baseUrl: String.fromEnvironment(
                  'WIDGET_BASE_URL',
                  defaultValue: 'https://billetera-widget.qa.lendrak.es',
                ),
                debugLogging: true,
              );
              const params = BilleteraLaunchParams(
                dni: '12345678',
                genero: BilleteraGenero.masculino,
                correo: 'usuario@correo.com',
                celular: '584120893949',
                tenant: 'TU_TENANT_TOKEN',
              );
              await BilleteraWidget.open(
                context,
                config: config,
                params: params,
              );
            },
            child: const Text('Abrir billetera'),
          ),
        ),
      ),
    );
  }
}
