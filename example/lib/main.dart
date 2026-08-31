import 'package:billetera_flutter/billetera_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

// QA por defecto; override: --dart-define=WIDGET_BASE_URL=http://10.0.2.2:4200
const _config = BilleteraWidgetConfig(
  baseUrl: String.fromEnvironment(
    'WIDGET_BASE_URL',
    defaultValue: 'https://billetera-widget.qa.lendrak.es',
  ),
  debugLogging: true,
);

const _tenant = String.fromEnvironment('TENANT', defaultValue: 'TU_TENANT_TOKEN');

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Billetera ejemplo',
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billetera ejemplo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lo minimo que necesita el SDK: el DNI. El resto se lo pide el
            // widget al usuario dentro del flujo.
            FilledButton(
              onPressed: () => BilleteraWidget.open(
                context,
                config: _config,
                params: const BilleteraLaunchParams(
                  dni: '12345678',
                  tenant: _tenant,
                ),
              ),
              child: const Text('Abrir billetera'),
            ),
            const SizedBox(height: 12),
            // Con los datos que ya tenga tu app precargados, para que el
            // usuario no los vuelva a tipear.
            OutlinedButton(
              onPressed: () => BilleteraWidget.open(
                context,
                config: _config,
                params: const BilleteraLaunchParams(
                  dni: '12345678',
                  genero: BilleteraGenero.masculino,
                  correo: 'usuario@correo.com',
                  celular: '584120893949',
                  tenant: _tenant,
                  idEntidad: 'ENT-9911',
                ),
              ),
              child: const Text('Abrir con datos precargados'),
            ),
          ],
        ),
      ),
    );
  }
}
