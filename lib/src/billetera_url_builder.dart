import 'billetera_launch_params.dart';
import 'billetera_widget_config.dart';

/// Comprueba [baseUrl] antes de abrir el WebView. Devuelve mensaje de error o `null`.
String? validateBilleteraBaseUrl(String baseUrl) {
  try {
    parseWidgetBaseUri(baseUrl);
    return null;
  } on ArgumentError catch (e) {
    return e.message?.toString() ?? e.toString();
  }
}

/// Normaliza y parsea la base del widget: `http`/`https`, host obligatorio.
///
/// - Acepta `https://host`, `http://10.0.2.2:4200`, `http://host:puerto/path`.
/// - Si falta el esquema (ej. `localhost:4200`, `10.0.2.2:4200`), se asume **`http://`**.
/// - Quita barra final, **ignora** query y fragment del string base (solo usa origen + path).
/// - Solo se permiten esquemas `http` y `https`.
Uri parseWidgetBaseUri(String raw) {
  var trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(
        raw, 'baseUrl', 'La URL base no puede estar vacía');
  }
  trimmed = trimmed.replaceAll(RegExp(r'/+$'), '');

  var toParse = trimmed;
  if (!_hasHttpScheme(toParse)) {
    final explicit = _explicitScheme(trimmed);
    if (explicit != null && explicit != 'http' && explicit != 'https') {
      throw ArgumentError.value(
        raw,
        'baseUrl',
        'Solo se admite http o https (recibido: $explicit://)',
      );
    }
    toParse = 'http://$toParse';
  }

  final parsed = Uri.parse(toParse);
  if (parsed.host.isEmpty) {
    throw ArgumentError.value(
      raw,
      'baseUrl',
      'URL base inválida: se necesita un host (ej. http://127.0.0.1:4200 o https://widget.ejemplo.com)',
    );
  }

  final scheme = parsed.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    throw ArgumentError.value(
      raw,
      'baseUrl',
      'Solo se admite http o https (recibido: ${parsed.scheme})',
    );
  }

  final pathSegments = parsed.pathSegments.where((s) => s.isNotEmpty).toList();
  return Uri(
    scheme: scheme,
    host: parsed.host,
    port: parsed.hasPort ? parsed.port : null,
    pathSegments: pathSegments,
  );
}

/// Solo consideramos esquema si es explícitamente `http` o `https` (evita
/// que `localhost:4200` se interprete como esquema `localhost`).
bool _hasHttpScheme(String s) {
  final lower = s.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Si el texto contiene `esquema://`, devuelve ese esquema en minúsculas.
String? _explicitScheme(String s) {
  final idx = s.indexOf('://');
  if (idx <= 0) return null;
  final sch = s.substring(0, idx).toLowerCase();
  if (!RegExp(r'^[a-z][a-z0-9+.\-]*$').hasMatch(sch)) return null;
  return sch;
}

/// Construye la URL de entrada al widget (`…/home?dni=…`).
Uri buildBilleteraWidgetUri(
  BilleteraWidgetConfig config,
  BilleteraLaunchParams params,
) {
  final base = parseWidgetBaseUri(config.baseUrl);
  final home = config.homePath.trim().replaceAll(RegExp(r'^/+|/+$'), '');
  final homeSegs = home.isEmpty
      ? <String>[]
      : home.split('/').where((s) => s.isNotEmpty).toList();
  final pathSegs = [
    ...base.pathSegments,
    ...homeSegs,
  ];
  final uri = Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    pathSegments: pathSegs,
    queryParameters: params.toQueryParameters(),
  );
  if (config.debugLogging) {
    // ignore: avoid_print
    print('[billetera_flutter] WebView URL: $uri');
  }
  return uri;
}
