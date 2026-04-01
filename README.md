# billetera-flutter

Paquete Flutter para **embeber el flujo de billetera en un WebView**. Tu app solo necesita:

- La **URL base** que te dé tu equipo (staging, producción o entorno local).
- Los datos de persona: `dni`, `género`, `correo`, `celular`, `tenant`.

El paquete construye la petición a la ruta `/home` con esos datos en el query string (equivalente a abrir una URL en el navegador).

**Requisitos:** Dart `>=3.2.0`, Flutter `>=3.16.0`.

---

## Resumen rápido

1. Agregá la dependencia `git` en `pubspec.yaml` → `flutter pub get`.
2. En **Android**, permití tráfico HTTP si usás `http://` local (ver [Android](#android-manifest)).
3. En **iOS**, configurá ATS para red local si usás `http://` (ver [iOS](#ios-infoplist)).
4. Llamá `BilleteraWidget.open(context, config: …, params: …)` con **`baseUrl` = solo el origen** que te indiquen (sin `/home` ni `?query`).

```dart
import 'package:billetera_flutter/billetera_flutter.dart';

await BilleteraWidget.open(
  context,
  config: BilleteraWidgetConfig(
    baseUrl: 'https://billetera.tu-dominio.com',
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

En **producción** la URL base debería ser **HTTPS**; así evitás bloqueos en Android/iOS.

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

El paquete **no** recibe la URL completa del navegador con `/home?dni=…`. Recibe el **origen** (protocolo + host + puerto opcional + path opcional de despliegue) y arma internamente:

`{baseUrl normalizado}/home?dni=…&genero=…&correo=…&celular=…&tenant=…`

### Ejemplo

Si te pasan o copiás del navegador algo como:

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
| Esquema `http` o `https` | `https://billetera.ejemplo.com` |
| Host y puerto si aplica | `http://10.0.2.2:4200` |
| Subpath si el despliegue está bajo una carpeta | `https://cdn.ejemplo.com/mi-app` → se abre `…/mi-app/home?…` |

### Qué no mezclar en `baseUrl`

| Evitar | Motivo |
|--------|--------|
| `/home` al final | El paquete ya agrega el segmento `home` (configurable con `homePath`). |
| `?dni=…&…` | Los query los arma el paquete desde `BilleteraLaunchParams`. |
| Barra final | Se normaliza; mejor sin barra para claridad. |

Si pegás una URL larga por error, el paquete **ignora** query y fragment del string base y solo usa host, puerto y path (no mezcla esos query con los del flujo).

### Esquema opcional

Si escribís solo host y puerto, se asume **HTTP**:

- `10.0.2.2:4200` → `http://10.0.2.2:4200`
- `localhost:4200` → `http://localhost:4200`

### Tabla por entorno

Pedí a tu equipo la URL exacta para cada entorno. Referencias habituales cuando el servidor corre en **tu PC** y la app en un dispositivo:

| Dónde corre la app | `baseUrl` típica hacia tu máquina |
|--------------------|-----------------------------------|
| Emulador Android | `http://10.0.2.2:PUERTO` (`10.0.2.2` es el alias del host desde el emulador) |
| Simulador iOS / macOS / mismo host | `http://127.0.0.1:PUERTO` o `http://localhost:PUERTO` |
| Dispositivo físico (misma WiFi) | `http://IP_DE_TU_PC:PUERTO` |
| Staging / producción | La HTTPS que te asignen (ej. `https://billetera.midominio.com`) |

**Emulador Android y servidor solo en `127.0.0.1`:** desde el emulador no sirve usar `http://localhost:4200` para llegar a tu PC; usá `10.0.2.2`. Además, el proceso que escucha en tu máquina debe aceptar conexiones **desde la red del emulador** (no solo loopback). Si no carga, pedí a tu equipo que el servidor de desarrollo escuche en **todas las interfaces** (`0.0.0.0`) o que te den la URL correcta para ese entorno.

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

Con `debugLogging: true` en `BilleteraWidgetConfig`, en consola verás:

`[billetera_flutter] WebView URL: …` — útil para comparar con lo que abrís en el navegador.

---

## 5. Errores en el WebView (página no carga)

La pantalla del paquete puede mostrar error de red y un botón **Reintentar**. Causas frecuentes:

| Síntoma | Acción |
|---------|--------|
| `ERR_CONNECTION_REFUSED` | Nada escucha en host:puerto, puerto incorrecto, o el servidor solo acepta loopback cuando la app usa otra dirección. |
| `ERR_ADDRESS_UNREACHABLE` / timeout | En emulador Android no uses `localhost` para referirte a tu PC; usá `10.0.2.2` (y el puerto acordado). |
| Página en blanco / cleartext (Android) | `usesCleartextTraffic` + `INTERNET` en el manifest. |
| ATS (iOS) bloqueando HTTP | `NSAllowsLocalNetworking` o HTTPS. |
| Certificado HTTPS inválido (staging) | Coordinar con tu equipo (certificados / entorno). |

---

## 6. API adicional

| API | Uso |
|-----|-----|
| `BilleteraWidget.open` | Abre la pantalla con `Navigator.push`. |
| `BilleteraWebViewScreen` | Misma UI dentro de tu propio `Navigator`. |
| `buildBilleteraWidgetUri` | Obtener el `Uri` final (tests, logs). |
| `parseWidgetBaseUri` | Normalizar solo la base. |
| `homePath` en `BilleteraWidgetConfig` | Si el segmento de ruta no es el predeterminado `home`. |

---

## 7. Variables por entorno (`--dart-define`)

Podés inyectar la URL en tiempo de compilación y leerla con `String.fromEnvironment` (el nombre de la variable lo elegís vos en tu app):

```bash
flutter run --dart-define=BILLETERA_BASE_URL=https://staging.midominio.com
```

```dart
const base = String.fromEnvironment(
  'BILLETERA_BASE_URL',
  defaultValue: 'https://billetera.midominio.com',
);
```

Para builds:

```bash
flutter build apk --dart-define=BILLETERA_BASE_URL=https://…
```

---

## 8. App de ejemplo

Si tu organización publica un proyecto demo de integración, usalo como referencia de `pubspec.yaml`, manifests iOS/Android y validación previa.

---

## 9. Desarrollo del paquete (contribuidores)

```bash
git clone https://github.com/Aginco-lending-online/billetera-flutter.git
cd billetera-flutter
flutter pub get
flutter test
cd example && flutter run --dart-define=WIDGET_BASE_URL=http://127.0.0.1:4200
```

*(En `example/` el nombre `WIDGET_BASE_URL` es solo del proyecto de ejemplo.)*

---

## Licencia

La que defina quien distribuya el paquete.
