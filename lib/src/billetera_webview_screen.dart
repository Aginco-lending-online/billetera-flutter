import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'billetera_launch_params.dart';
import 'billetera_url_builder.dart';
import 'billetera_widget_config.dart';

/// Pantalla con [WebView] que carga billetera-widget en `/home` con query params.
///
/// Se puede usar suelta (por ejemplo dentro de un `IndexedStack` o una pestaña)
/// o a traves de `BilleteraWidget.open`, que la empuja como ruta.
class BilleteraWebViewScreen extends StatefulWidget {
  const BilleteraWebViewScreen({
    super.key,
    required this.config,
    required this.params,
  });

  final BilleteraWidgetConfig config;
  final BilleteraLaunchParams params;

  @override
  State<BilleteraWebViewScreen> createState() => _BilleteraWebViewScreenState();
}

class _BilleteraWebViewScreenState extends State<BilleteraWebViewScreen> {
  WebViewController? _controller;
  String? _paramsError;
  String? _pageError;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    final baseErr = validateBilleteraBaseUrl(widget.config.baseUrl);
    final paramErr = widget.params.validate();
    final validation = baseErr ?? paramErr;
    if (validation != null) {
      _paramsError = validation;
      _loading = false;
      return;
    }
    final uri = buildBilleteraWidgetUri(widget.config, widget.params);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _pageError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _pageError = err.description;
              });
            }
          },
        ),
      )
      ..loadRequest(uri);
    _controller = controller;
  }

  /// El flujo son varias pantallas dentro del WebView: el boton atras del
  /// telefono tiene que retroceder ahi y recien cerrar cuando no hay a donde
  /// volver. Sin esto, el primer atras abandona toda la solicitud.
  Future<void> _handlePop(bool didPop) async {
    if (didPop) return;
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    // pop y no maybePop: maybePop volveria a consultar este mismo PopScope,
    // que sigue diciendo canPop=false, y el atras nunca cerraria la pantalla.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final showError = _paramsError != null;

    return PopScope(
      // Con la pantalla de error no hay historial que recorrer: se cierra directo.
      canPop: showError,
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Scaffold(
        appBar: widget.config.showAppBar
            ? AppBar(title: Text(widget.config.appBarTitle))
            : null,
        body: SafeArea(
          child: showError ? _buildParamsError(context) : _buildWebView(),
        ),
      ),
    );
  }

  Widget _buildParamsError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _paramsError!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller!),
        if (_loading)
          const ColoredBox(
            color: Color(0x66FFFFFF),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_pageError != null)
          Material(
            color: Colors.black54,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_pageError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _pageError = null;
                              _loading = true;
                            });
                            _controller?.reload();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
