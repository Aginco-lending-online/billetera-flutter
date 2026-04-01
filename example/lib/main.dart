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
              // Ajustá la URL al entorno (dev / staging / prod).
              const config = BilleteraWidgetConfig(
                baseUrl: String.fromEnvironment(
                  'WIDGET_BASE_URL',
                  defaultValue: 'http://10.0.2.2:4200',
                ),
                debugLogging: true,
              );
              const params = BilleteraLaunchParams(
                dni: '12345678',
                genero: BilleteraGenero.masculino,
                correo: 'demo@example.com',
                celular: '1122334455',
                tenant: 'demo-tenant',
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
