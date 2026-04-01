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
}
