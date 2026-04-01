import 'package:flutter/material.dart';

export 'src/billetera_genero.dart';
export 'src/billetera_launch_params.dart';
export 'src/billetera_url_builder.dart';
export 'src/billetera_webview_screen.dart';
export 'src/billetera_widget_config.dart';

import 'src/billetera_launch_params.dart';
import 'src/billetera_webview_screen.dart';
import 'src/billetera_widget_config.dart';

/// Abre **billetera-widget** en un [WebView] dentro de un [MaterialPageRoute].
///
/// ```dart
/// await BilleteraWidget.open(
///   context,
///   config: BilleteraWidgetConfig(baseUrl: 'https://tu-widget.example.com'),
///   params: BilleteraLaunchParams(
///     dni: '12345678',
///     genero: BilleteraGenero.masculino,
///     correo: 'a@b.com',
///     celular: '1122334455',
///     tenant: 'mi-tenant',
///   ),
/// );
/// ```
abstract final class BilleteraWidget {
  static Future<void> open(
    BuildContext context, {
    required BilleteraWidgetConfig config,
    required BilleteraLaunchParams params,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BilleteraWebViewScreen(config: config, params: params),
      ),
    );
  }
}
