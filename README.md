# billetera-flutter

Paquete Flutter que abre **billetera-widget** en un **WebView**. Los datos de persona (`dni`, `género`, `correo`, `celular`, `tenant`) se envían como query en la ruta `/home`, igual que si el usuario abriera una URL en el navegador.

**Requisitos:** Dart `>=3.2.0`, Flutter `>=3.16.0`.

---

## Resumen rápido

1. Agregá la dependencia `git` en `pubspec.yaml` → `flutter pub get`.
2. En **Android**, permití tráfico HTTP si usás `http://` local (ver [Android](#android-manifest)).
3. En **iOS**, configurá ATS para red local si usás `http://` (ver [iOS](#ios-infoplist)).
4. Llamá `BilleteraWidget.open(context, config: …, params: …)` con **`baseUrl` = solo origen del sitio** (sin `/home` ni `?query`).

```dart
import 'package:billetera_flutter/billetera_flutter.dart';

await BilleteraWidget.open(
  context,
  config: BilleteraWidgetConfig(
    baseUrl: 'https://widget.tu-dominio.com',
    debugLogging: true,
  ),
  params: BilleteraLaunchParams(
    dni: '12345678',
    genero: BilleteraGenero.masculino,
    correo: 'usuario@correo.com',
    celular: '1122334455',
    tenant: 'tu-tenant',
  ),
);
```

---

## 1. Instalar el paquete

### `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  billetera_flutter:
    git:
      url: https://github.com/Aginco-lending-online/billetera-flutter.git
      ref: main
```

- **Fijar versión:** usá un **tag** (`ref: v0.1.0`) o el **SHA** de un commit en lugar de `main`.
- **Repo privado (SSH):**

```yaml
  billetera_flutter:
    git:
      url: git@github.com:Aginco-lending-online/billetera-flutter.git
      ref: main
```

### Comandos

```bash
flutter pub get
```

Verificá que se resolvió:

```bash
flutter pub deps | grep billetera_flutter
```

### Errores al hacer `pub get`

| Síntoma | Qué revisar |
|--------|-------------|
| `Repository not found` | Acceso al repo (¿privado?). Probá SSH o `gh auth login` / credenciales HTTPS. |
| `Permission denied (publickey)` | Clave SSH cargada en el agente y agregada en GitHub. |
| Timeout / red | VPN, proxy o firewall bloqueando `github.com`. |

---

## 2. Plataforma: HTTP local (`http://`)

En **producción** el widget debería servirse por **HTTPS**; así evitás excepciones en Android/iOS.

Si en desarrollo usás `http://127.0.0.1:4200`, `http://10.0.2.2:4200`, etc.:

### Android (`AndroidManifest.xml`)

Dentro de `<manifest>` (permiso de red):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Dentro de `<application …>`:

```xml
<application
    android:usesCleartextTraffic="true"
    …>
```

Sin `usesCleartextTraffic` (o política de red que bloquee HTTP), el WebView puede mostrar errores tipo **cleartext not permitted** / página en blanco.

**Tip:** En release, si solo usás HTTPS, podés quitar `usesCleartextTraffic` o limitarlo a un flavor de debug.

### iOS (`Info.plist`)

Para cargar `http://` hacia tu Mac o LAN en desarrollo:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

Más opciones en la [documentación de Apple sobre ATS](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity).

---

## 3. Cómo armar `baseUrl` (muy importante)

El paquete **no** recibe la URL completa del navegador con `/home?dni=…`. Recibe el **origen del despliegue del widget** y arma internamente:

`{baseUrl normalizado}/home?dni=…&genero=…&correo=…&celular=…&tenant=…`

### Ejemplo

Si en el navegador abrís:

```text
http://localhost:4200/home?dni=12345678&genero=M&correo=a@b.com&celular=…&tenant=…
```

En Flutter pasá **solo**:

```dart
baseUrl: 'http://localhost:4200'
```

Los datos van en `BilleteraLaunchParams`, no en la URL manual.

### Qué incluye `baseUrl`

| Incluir | Ejemplo |
|--------|---------|
| Esquema `http` o `https` | `https://widget.ejemplo.com` |
| Host y puerto si aplica | `http://10.0.2.2:4200` |
| Subpath si el widget vive bajo carpeta | `https://cdn.ejemplo.com/mi-app` → se abre `…/mi-app/home?…` |

### Qué no mezclar en `baseUrl`

| Evitar | Motivo |
|--------|--------|
| `/home` al final | El paquete ya agrega `home` (configurable con `homePath`). |
| `?dni=…&…` | Los query los arma el paquete desde `BilleteraLaunchParams`. |
| Barra final | Se normaliza; mejor sin barra para claridad. |

Si copiás una URL larga por error, el paquete **ignora** query y fragment del string base y solo usa host, puerto y path (no mezcla esos query con los del formulario).

### Esquema opcional

Si escribís solo host y puerto, se asume **HTTP**:

- `10.0.2.2:4200` → `http://10.0.2.2:4200`
- `localhost:4200` → `http://localhost:4200`

### Tabla por entorno

| Dónde corre la app | `baseUrl` típica para `ng serve` en tu PC |
|--------------------|-------------------------------------------|
| Emulador Android | `http://10.0.2.2:4200` |
| Simulador iOS / macOS / mismo host | `http://127.0.0.1:4200` o `http://localhost:4200` |
| Dispositivo físico (misma WiFi) | `http://IP_DE_TU_PC:4200` |
| Producción | `https://tu-dominio-del-widget.com` |

**Angular:** para que el emulador Android llegue al dev server:

```bash
ng serve --host 0.0.0.0 --port 4200
```

---

## 4. Validación y mensajes de error

### URL (`validateBilleteraBaseUrl` / pantalla del paquete)

| Problema | Mensaje aproximado |
|----------|-------------------|
| Cadena vacía | `La URL base no puede estar vacía` |
| Sin host válido | `URL base inválida: se necesita un host (ej. http://127.0.0.1:4200…)` |
| Esquema que no sea http/https (`ftp://`, etc.) | `Solo se admite http o https (recibido: …)` |

### Parámetros (`BilleteraLaunchParams.validate()`)

| Problema | Mensaje |
|----------|---------|
| DNI | `DNI debe tener entre 7 y 8 dígitos` |
| Género no reconocido | Depende del valor; usá `M`/`F`/`O` o `BilleteraGenero` |
| Correo | `Correo electrónico no válido` |
| Celular | `Celular no válido (mínimo 8 dígitos en total)` |
| Tenant vacío | `Tenant no puede estar vacío` |

### Validar antes de abrir (tu app)

```dart
final config = BilleteraWidgetConfig(baseUrl: url);
final params = BilleteraLaunchParams(/* … */);

final urlErr = validateBilleteraBaseUrl(config.baseUrl);
final paramErr = params.validate();
if (urlErr != null || paramErr != null) {
  // SnackBar, diálogo, etc.
  return;
}

await BilleteraWidget.open(context, config: config, params: params);
```

Con `debugLogging: true` en `BilleteraWidgetConfig`, en consola verás la línea:

`[billetera_flutter] WebView URL: …` — útil para comparar con lo que abrís en Chrome.

---

## 5. Errores en el WebView (página no carga)

La pantalla del paquete puede mostrar error de red y un botón **Reintentar**. Causas frecuentes:

| Síntoma | Acción |
|---------|--------|
| `ERR_CONNECTION_REFUSED` | El servidor Angular no está levantado o el puerto es otro. |
| `ERR_ADDRESS_UNREACHABLE` / timeout | En emulador Android no uses `localhost` para el host; usá `10.0.2.2`. |
| Página en blanco / cleartext (Android) | `usesCleartextTraffic` + `INTERNET` en el manifest. |
| ATS (iOS) bloqueando HTTP | `NSAllowsLocalNetworking` o servir por HTTPS. |
| Certificado HTTPS inválido (staging) | Ajustar red / certificados; en dev preferí HTTP local. |

---

## 6. API adicional

| API | Uso |
|-----|-----|
| `BilleteraWidget.open` | Abre la ruta con `Navigator.push`. |
| `BilleteraWebViewScreen` | Misma UI en tu propio `Navigator`. |
| `buildBilleteraWidgetUri` | Obtener el `Uri` final (tests, logs). |
| `parseWidgetBaseUri` | Normalizar solo la base. |
| `homePath` en `BilleteraWidgetConfig` | Si la ruta no es `home` (por defecto `home`). |

---

## 7. Variables por entorno (`--dart-define`)

Podés inyectar la URL en tiempo de compilación y leerla con `String.fromEnvironment`:

```bash
flutter run --dart-define=WIDGET_BASE_URL=https://staging-widget.ejemplo.com
```

```dart
const base = String.fromEnvironment('WIDGET_BASE_URL', defaultValue: 'https://prod-widget.ejemplo.com');
```

Para builds:

```bash
flutter build apk --dart-define=WIDGET_BASE_URL=https://…
```

---

## 8. App de ejemplo

Si tu equipo mantiene un proyecto demo aparte, usalo como referencia de `pubspec.yaml`, manifest iOS/Android y validación previa. La URL del repo depende de tu organización en GitHub.

---

## 9. Desarrollo del paquete (contribuidores)

```bash
git clone https://github.com/Aginco-lending-online/billetera-flutter.git
cd billetera-flutter
flutter pub get
flutter test
cd example && flutter run --dart-define=WIDGET_BASE_URL=http://127.0.0.1:4200
```

---

## Licencia

La que defina quien distribuya el paquete.
