import 'package:flutter/foundation.dart';

/// Configuración de la URL del widget (por entorno o custom).
///
/// [baseUrl]: origen del sitio del widget **sin** barra final (`https://…`, `http://…`,
/// o `host:puerto` / `IP:puerto` sin esquema → se asume `http://`).
/// Validación: `validateBilleteraBaseUrl` / `parseWidgetBaseUri` en el paquete exportado.
///
/// [homePath] por defecto `home` → ruta Angular típica `/home`.
@immutable
class BilleteraWidgetConfig {
  const BilleteraWidgetConfig({
    required this.baseUrl,
    this.homePath = 'home',
    this.appBarTitle = 'Billetera',
    this.showAppBar = true,
    this.debugLogging = false,
  });

  /// URL base del despliegue de billetera-widget.
  final String baseUrl;

  /// Segmento de ruta bajo el origen (sin `/` inicial).
  final String homePath;

  final String appBarTitle;

  /// El widget ya dibuja su propio encabezado con el título de cada pantalla.
  /// Poné `false` para no duplicar barras y dejar el WebView a pantalla completa.
  final bool showAppBar;

  /// Si es true, imprime la URL final en consola (solo depuración).
  final bool debugLogging;

  /// Entorno staging desplegado (`staging.agiltech.io/billetera-widget`).
  static const BilleteraWidgetConfig staging = BilleteraWidgetConfig(
    baseUrl: 'https://staging.agiltech.io/billetera-widget',
    debugLogging: kDebugMode,
  );

  /// Desarrollo local típico (Angular `ng serve` en el host; emulador Android → 10.0.2.2).
  static const BilleteraWidgetConfig localAndroidEmulator =
      BilleteraWidgetConfig(
    baseUrl: 'http://10.0.2.2:4200',
    debugLogging: kDebugMode,
  );

  /// iOS simulator / macOS: localhost del host.
  static const BilleteraWidgetConfig localIosSimulator = BilleteraWidgetConfig(
    baseUrl: 'http://127.0.0.1:4200',
    debugLogging: kDebugMode,
  );
}
