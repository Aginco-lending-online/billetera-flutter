import 'billetera_genero.dart';

/// Datos que la app host envía para precargar [billetera-widget] en `/home`.
///
/// Debe coincidir con `parseHomeEntryQuery` en Angular (`dni`, `genero`, `correo`,
/// `celular`, `tenant`).
class BilleteraLaunchParams {
  const BilleteraLaunchParams({
    required this.dni,
    required this.genero,
    required this.correo,
    required this.celular,
    required this.tenant,
  });

  final String dni;

  /// [BilleteraGenero], letra `M`/`F`/`O`, o texto tipo `Masculino` / `Femenino` / `Otro`.
  final Object genero;
  final String correo;

  /// Número local o con prefijo 54 (se normaliza en el widget).
  final String celular;

  /// Token de aplicación / tenant (mismo valor que en la URL del widget).
  final String tenant;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Devuelve un mensaje de error o `null` si todo es válido.
  String? validate() {
    final d = dni.replaceAll(RegExp(r'\D'), '');
    if (d.length < 7 || d.length > 8) {
      return 'DNI debe tener entre 7 y 8 dígitos';
    }
    try {
      normalizeGeneroToQuery(genero);
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? 'Género no válido';
    }
    final mail = correo.trim();
    if (!_emailRe.hasMatch(mail)) {
      return 'Correo electrónico no válido';
    }
    final digits = celular.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return 'Celular no válido (mínimo 8 dígitos en total)';
    }
    if (tenant.trim().isEmpty) {
      return 'Tenant no puede estar vacío';
    }
    return null;
  }

  Map<String, String> toQueryParameters() {
    final err = validate();
    if (err != null) {
      throw StateError('BilleteraLaunchParams inválidos: $err');
    }
    final d = dni.replaceAll(RegExp(r'\D'), '');
    return {
      'dni': d,
      'genero': normalizeGeneroToQuery(genero),
      'correo': correo.trim(),
      'celular': celular.trim(),
      'tenant': tenant.trim(),
    };
  }
}
