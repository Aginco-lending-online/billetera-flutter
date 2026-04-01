# billetera-flutter

Paquete Flutter que abre **billetera-widget** en un **WebView**. Envía `dni`, `género`, `correo`, `celular` y `tenant` como query en la ruta `/home` (mismo contrato que el widget Angular).

---

## Implementación paso a paso (para desarrolladores)

### Paso 1 — Agregar la dependencia

En el `pubspec.yaml` de tu aplicación:

```yaml
dependencies:
  flutter:
    sdk: flutter

  billetera_flutter:
    git:
      url: https://github.com/Aginco-lending-online/billetera-flutter.git
      ref: main
```

- **Versión estable:** cambiá `ref` por un **tag** (ej. `v0.1.0`) o un **commit** concreto.
- **Repo privado:** usá la URL SSH, por ejemplo `git@github.com:Aginco-lending-online/billetera-flutter.git`, y tené configurada tu clave o credenciales en el entorno.

### Paso 2 — Descargar dependencias

```bash
flutter pub get
```

### Paso 3 — Permitir HTTP en desarrollo (solo si usás `http://` local)

El paquete acepta **`http://`** y **`https://`**. En **producción** usá siempre **HTTPS**.

#### Android

Si cargás el widget con `http://` (ej. `http://10.0.2.2:4200`), Android 9+ puede bloquear cleartext.

En `android/app/src/main/AndroidManifest.xml`, dentro de `<application …>`:

```xml
<application
    android:usesCleartextTraffic="true"
    … >
```

Restringilo a **debug** si podés (build flavors / manifest por variante). En **release** hacia internet, preferí HTTPS y podés omitir esto.

#### iOS

Para `http://` en simulador o dispositivo, en `ios/Runner/Info.plist` podés añadir (solo mientras desarrollás):

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

O excepciones por dominio/IP según la [documentación de Apple](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity). En **App Store** conviene servir el widget por **HTTPS**.

### Paso 4 — Llamar al paquete desde tu UI

```dart
import 'package:billetera_flutter/billetera_flutter.dart';

Future<void> abrirWidget(BuildContext context) async {
  await BilleteraWidget.open(
    context,
    config: BilleteraWidgetConfig(
      baseUrl: 'https://widget.tu-dominio.com',
      debugLogging: true, // opcional: imprime la URL en consola
    ),
    params: BilleteraLaunchParams(
      dni: '12345678',
      genero: BilleteraGenero.masculino, // o 'M' / 'F' / 'O'
      correo: 'usuario@correo.com',
      celular: '1122334455',
      tenant: 'tu-tenant',
    ),
  );
}
```

Si los datos o la URL base son inválidos, la pantalla del paquete muestra el error en lugar de cargar el WebView.

### Paso 5 — Elegir bien `baseUrl` (por entorno)

`baseUrl` es el **origen del sitio del widget** (esquema + host + puerto opcional + path opcional), **sin barra final**.

| Situación | Ejemplo de `baseUrl` |
|-----------|----------------------|
| Emulador Android + `ng serve` en la PC | `http://10.0.2.2:4200` |
| Simulador iOS / app en el mismo host que el dev server | `http://127.0.0.1:4200` |
| Dispositivo físico en la misma WiFi | `http://192.168.x.x:4200` (IP de tu máquina) |
| Staging / producción | `https://widget.tu-dominio.com` |
| Widget bajo subcarpeta | `https://cdn.ejemplo.com/mi-app` → la pantalla carga `…/mi-app/home?…` |

**Comodidades del paquete**

- Podés escribir **`localhost:4200`** o **`10.0.2.2:4200`** sin `http://`: se asume **HTTP**.
- **`HTTPS://…`** en mayúsculas se normaliza bien.
- Query o fragment en el string de base (errores de copy-paste) **no** se mezclan con los parámetros del widget; solo se usa host, puerto y path.

**Validación previa (opcional)**

```dart
final urlError = validateBilleteraBaseUrl(miBaseUrl);
final paramsError = misParams.validate();
```

### Paso 6 — API alternativa (más control)

- **`BilleteraWebViewScreen`**: misma pantalla que usa `BilleteraWidget.open`, por si querés envolverla en tu propio `Navigator`.
- **`buildBilleteraWidgetUri`**: obtiene el `Uri` final (tests, deep links, depuración).
- **`parseWidgetBaseUri`**: normaliza solo la base.

---

## Parámetros de persona

| Campo | Reglas |
|-------|--------|
| `dni` | 7 u 8 dígitos (se ignoran caracteres no numéricos al armar el query) |
| `genero` | `BilleteraGenero`, letra `M` / `F` / `O`, o texto tipo Masculino / Femenino / Otro |
| `correo` | Formato email simple |
| `celular` | Al menos 8 dígitos en total |
| `tenant` | No vacío |

---

## Desarrollo de este paquete (contribuidores)

Ejemplo dentro del repo:

```bash
cd example
flutter run --dart-define=WIDGET_BASE_URL=http://127.0.0.1:4200
```

Tests:

```bash
flutter test
```

---

## Licencia

La que defina quien distribuya el paquete.
