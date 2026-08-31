import 'package:billetera_flutter/billetera_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const params = BilleteraLaunchParams(
    dni: '12345678',
    genero: BilleteraGenero.femenino,
    correo: 'a@b.co',
    celular: '5491112345678',
    tenant: 't1',
  );

  test('https sin path → /home + query', () {
    const config = BilleteraWidgetConfig(baseUrl: 'https://widget.example.com');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.scheme, 'https');
    expect(u.host, 'widget.example.com');
    expect(u.path, '/home');
    expect(u.queryParameters['dni'], '12345678');
    expect(u.queryParameters['genero'], 'F');
  });

  test('http local emulador Android', () {
    const config = BilleteraWidgetConfig(baseUrl: 'http://10.0.2.2:4200');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.scheme, 'http');
    expect(u.host, '10.0.2.2');
    expect(u.port, 4200);
    expect(u.path, '/home');
  });

  test('http 127.0.0.1 con puerto', () {
    const config = BilleteraWidgetConfig(baseUrl: 'http://127.0.0.1:4200/');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.host, '127.0.0.1');
    expect(u.port, 4200);
    expect(u.path, '/home');
  });

  test('sin esquema → se asume http', () {
    const config = BilleteraWidgetConfig(baseUrl: 'localhost:4200');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.scheme, 'http');
    expect(u.host, 'localhost');
    expect(u.port, 4200);
  });

  test('sin esquema IP:puerto', () {
    const config = BilleteraWidgetConfig(baseUrl: '192.168.0.10:4200');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.scheme, 'http');
    expect(u.host, '192.168.0.10');
    expect(u.port, 4200);
    expect(u.path, '/home');
  });

  test('https con subpath y homePath', () {
    const config = BilleteraWidgetConfig(
      baseUrl: 'https://cdn.example.com/app/',
      homePath: 'home',
    );
    const p = BilleteraLaunchParams(
      dni: '1234567',
      genero: 'M',
      correo: 'x@y.z',
      celular: '1112345678',
      tenant: 'x',
    );
    final u = buildBilleteraWidgetUri(config, p);
    expect(u.path, '/app/home');
    expect(u.scheme, 'https');
  });

  test('HTTPS en mayúsculas se normaliza', () {
    const config = BilleteraWidgetConfig(baseUrl: 'HTTPS://w.example.com/');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.scheme, 'https');
    expect(u.host, 'w.example.com');
  });

  test('query/fragment en baseUrl no contaminan la URL final', () {
    const config = BilleteraWidgetConfig(
      baseUrl: 'http://127.0.0.1:4200/old?x=1#frag',
    );
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.path, '/old/home');
    expect(u.queryParameters.containsKey('x'), isFalse);
    expect(u.queryParameters['dni'], isNotNull);
  });

  test('validateBilleteraBaseUrl rechaza vacío', () {
    expect(validateBilleteraBaseUrl(''), isNotNull);
    expect(validateBilleteraBaseUrl('   '), isNotNull);
  });

  test('validateBilleteraBaseUrl rechaza esquema no http(s)', () {
    expect(validateBilleteraBaseUrl('ftp://a.com'), isNotNull);
  });

  test('parseWidgetBaseUri IPv6 localhost', () {
    final u = parseWidgetBaseUri('http://[::1]:4200');
    expect(u.host, '::1');
    expect(u.port, 4200);
  });

  test('idEntidad se omite cuando no se envía', () {
    const config = BilleteraWidgetConfig(baseUrl: 'https://w.example.com');
    final u = buildBilleteraWidgetUri(config, params);
    expect(u.queryParameters.containsKey('idEntidad'), isFalse);
  });

  test('idEntidad viaja en la query cuando se envía', () {
    const config = BilleteraWidgetConfig(baseUrl: 'https://w.example.com');
    const p = BilleteraLaunchParams(
      dni: '12345678',
      genero: BilleteraGenero.femenino,
      correo: 'a@b.co',
      celular: '5491112345678',
      tenant: 't1',
      idEntidad: '  ENT-9911  ',
    );
    final u = buildBilleteraWidgetUri(config, p);
    expect(u.queryParameters['idEntidad'], 'ENT-9911');
  });

  test('idEntidad en blanco se trata como ausente', () {
    const config = BilleteraWidgetConfig(baseUrl: 'https://w.example.com');
    const p = BilleteraLaunchParams(
      dni: '12345678',
      genero: BilleteraGenero.femenino,
      correo: 'a@b.co',
      celular: '5491112345678',
      tenant: 't1',
      idEntidad: '   ',
    );
    final u = buildBilleteraWidgetUri(config, p);
    expect(u.queryParameters.containsKey('idEntidad'), isFalse);
  });

  group('solo el DNI es obligatorio, igual que en el widget', () {
    test('con el DNI solo alcanza para abrir el widget', () {
      const p = BilleteraLaunchParams(dni: '12345678');
      expect(p.validate(), isNull);
      const config = BilleteraWidgetConfig(baseUrl: 'https://w.example.com');
      final u = buildBilleteraWidgetUri(config, p);
      expect(u.queryParameters, {'dni': '12345678'});
    });

    test('los campos ausentes no aparecen en la query', () {
      const p = BilleteraLaunchParams(dni: '12345678', tenant: 't1');
      final q = p.toQueryParameters();
      expect(q.keys.toList(), ['dni', 'tenant']);
    });

    test('los campos en blanco se tratan como ausentes', () {
      const p = BilleteraLaunchParams(
        dni: '12345678',
        genero: '',
        correo: '  ',
        celular: '',
        tenant: '   ',
      );
      expect(p.validate(), isNull);
      expect(p.toQueryParameters(), {'dni': '12345678'});
    });

    test('el DNI sigue siendo obligatorio y validado', () {
      expect(const BilleteraLaunchParams(dni: '').validate(), isNotNull);
      expect(const BilleteraLaunchParams(dni: '123').validate(), isNotNull);
    });

    test('lo que sí se envía se sigue validando', () {
      expect(
        const BilleteraLaunchParams(dni: '12345678', correo: 'no-es-mail')
            .validate(),
        isNotNull,
      );
      expect(
        const BilleteraLaunchParams(dni: '12345678', celular: '123').validate(),
        isNotNull,
      );
      expect(
        const BilleteraLaunchParams(dni: '12345678', genero: 'X').validate(),
        isNotNull,
      );
    });

    test('el género acepta enum, letra y texto', () {
      String? letra(Object g) => BilleteraLaunchParams(dni: '12345678', genero: g)
          .toQueryParameters()['genero'];
      expect(letra(BilleteraGenero.masculino), 'M');
      expect(letra('f'), 'F');
      expect(letra('Femenino'), 'F');
      expect(letra('Otro'), 'O');
    });
  });
}
