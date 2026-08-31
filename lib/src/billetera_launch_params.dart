import 'billetera_genero.dart';

/// Datos con los que la app host precarga billetera-widget en `/home`.
///
/// Solo [dni] es obligatorio, igual que en el widget: es el unico dato sin el
/// cual el flujo no puede arrancar. El resto son precargas que el usuario puede
/// completar o corregir dentro del flujo, asi que si tu app no los tiene,
/// simplemente no los mandes. Los campos vacios se omiten de la URL.
class BilleteraLaunchParams {
  const BilleteraLaunchParams({
    required this.dni,
    this.genero,
    this.correo,
    this.celular,
    this.tenant,
    this.idEntidad,
  });

  final String dni;

  /// [BilleteraGenero], letra `M`/`F`/`O`, o texto tipo `Masculino` / `Femenino` / `Otro`.
  final Object? genero;

  final String? correo;

  /// Numero local o con prefijo 54 (se normaliza en el widget).
  final String? celular;

  /// Token de aplicacion / tenant. Sin el, el middleware resuelve con su
  /// configuracion de entorno; en produccion conviene mandarlo siempre.
  final String? tenant;

  /// Entidad de la app host. El widget la reenvia al middleware, que hoy solo
  /// la registra.
  final String? idEntidad;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Devuelve un mensaje de error o `null` si todo es válido.
  ///
  /// Los campos opcionales solo se validan cuando vienen con contenido: un
  /// dato ausente no es un error, es una precarga que hara el usuario.
  String? validate() {
    final d = dni.replaceAll(RegExp(r'\D'), '');
    if (d.length < 7 || d.length > 8) {
      return 'DNI debe tener entre 7 y 8 dígitos';
    }
    try {
      _generoQuery();
    } on ArgumentError catch (e) {
      return e.message?.toString() ?? 'Género no válido';
    }
    final mail = correo?.trim() ?? '';
    if (mail.isNotEmpty && !_emailRe.hasMatch(mail)) {
      return 'Correo electrónico no válido';
    }
    final digits = (celular ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && digits.length < 8) {
      return 'Celular no válido (mínimo 8 dígitos en total)';
    }
    return null;
  }

  Map<String, String> toQueryParameters() {
    final err = validate();
    if (err != null) {
      throw StateError('BilleteraLaunchParams inválidos: $err');
    }
    final generoQuery = _generoQuery();
    final mail = correo?.trim() ?? '';
    final cel = celular?.trim() ?? '';
    final tnt = tenant?.trim() ?? '';
    final entidad = idEntidad?.trim() ?? '';
    return {
      'dni': dni.replaceAll(RegExp(r'\D'), ''),
      if (generoQuery != null) 'genero': generoQuery,
      if (mail.isNotEmpty) 'correo': mail,
      if (cel.isNotEmpty) 'celular': cel,
      if (tnt.isNotEmpty) 'tenant': tnt,
      if (entidad.isNotEmpty) 'idEntidad': entidad,
    };
  }

  /// Letra `M`/`F`/`O`, o `null` si no se envió género.
  String? _generoQuery() {
    final value = genero;
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return normalizeGeneroToQuery(value);
  }
}
