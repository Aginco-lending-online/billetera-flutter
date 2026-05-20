# Ejemplo `billetera_flutter`

App mínima que abre el widget en un WebView vía `BilleteraWidget.open`.

## QA (recomendado para probar integración)

```bash
flutter run --dart-define=WIDGET_BASE_URL=https://billetera-widget.qa.lendrak.es
```

La URL del navegador en QA tiene esta forma:

```text
https://billetera-widget.qa.lendrak.es/home?dni=…&genero=m&correo=…&celular=…&tenant=…
```

En Flutter solo pasás el origen (`https://billetera-widget.qa.lendrak.es`); el resto va en `BilleteraLaunchParams` en `lib/main.dart`.

## Local (widget en tu máquina)

```bash
flutter run --dart-define=WIDGET_BASE_URL=http://10.0.2.2:4200
```

En emulador Android usá `10.0.2.2`; en simulador iOS, `http://127.0.0.1:4200`.

Documentación completa del paquete: [../README.md](../README.md).
