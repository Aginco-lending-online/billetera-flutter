# billetera-flutter

Paquete Flutter para **embeber el flujo de billetera en un WebView**. Tu app solo necesita:

- La **URL base** del widget (en staging: `https://staging.agiltech.io/billetera-widget`; ver [Entornos](#entornos)).
- El **DNI** de la persona y el **tenant** de tu app: el paquete solo exige el DNI, pero sin `tenant` el middleware no deja crear la solicitud. `genero`, `correo`, `celular` e `idEntidad` sí son **opcionales**: ver [Parámetros](#parámetros).

El paquete construye la petición a la ruta `/home` con esos datos en el query string (equivalente a abrir una URL en el navegador).

**Requisitos:** Dart `>=3.5.0`, Flutter `>=3.24.0`.

---

## Resumen rápido

1. Agregá la dependencia `git` en `pubspec.yaml` → `flutter pub get`.
2. En **Android**, permití tráfico HTTP si usás `http://` local (ver [Android](#android-manifest)).
3. En **iOS**, configurá ATS para red local si usás `http://` (ver [iOS](#ios-infoplist)).
4. Llamá `BilleteraWidget.open(context, config: …, params: …)` con **`baseUrl` = el origen con el subpath donde esté montado el widget** (sin `/home` ni `?query`).

```dart
import 'package:billetera_flutter/billetera_flutter.dart';

await BilleteraWidget.open(
  context,
  config: const BilleteraWidgetConfig(
    baseUrl: 'https://staging.agiltech.io/billetera-widget',
    debugLogging: true,
  ),
  params: const BilleteraLaunchParams(
    dni: '12345678',
    tenant: 'TU_TENANT_TOKEN',
  ),
);
```

Si tu app ya conoce más datos de la persona, pasalos y el widget los usa como precarga:

```dart
params: const BilleteraLaunchParams(
  dni: '12345678',
  genero: BilleteraGenero.masculino,
  correo: 'usuario@correo.com',
  celular: '584120893949',
  tenant: 'TU_TENANT_TOKEN',
),
```

---

## Entornos

| Entorno | `baseUrl` (sin `/home` ni query) |
|---------|-----------------------------------------------|
| **Staging** | `https://staging.agiltech.io/billetera-widget` |
| Local (emulador Android → host) | `http://10.0.2.2:4200` |
| Local (simulador iOS / mismo host) | `http://127.0.0.1:4200` |
| Producción | La HTTPS que asigne tu equipo (aún no documentada aquí) |

En **staging** el widget ya está en HTTPS: no hace falta `usesCleartextTraffic` ni excepciones ATS solo por cargar la URL de staging.

---

## Guía: implementar el WebView en tu app

Esta sección es para el equipo que integra el paquete en una app Flutter existente.

### Paso 1 — Dependencia

Agregá `billetera_flutter` en `pubspec.yaml` (ver [§1 Instalar el paquete](#1-instalar-el-paquete)) y ejecutá `flutter pub get`.

### Paso 2 — Permisos de red

**Android** — en `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Solo necesitás `android:usesCleartextTraffic="true"` si probás contra `http://` local (ver [§2](#2-plataforma-http-local-http)).

**iOS** — para staging/producción con HTTPS no suele hacer falta ATS extra. Para `http://` local, ver [§2](#2-plataforma-http-local-http).

### Paso 3 — De la URL del navegador al código Flutter

Si en el navegador (o te la pasan por Slack) ves una URL como esta de **staging**:

```text
https://staging.agiltech.io/billetera-widget/home?dni=12345678&genero=m&correo=usuario@correo.com&celular=584120893949&tenant=TU_TENANT_TOKEN
```

| Parte de la URL | Dónde va en Flutter |
|-----------------|---------------------|
| `https://staging.agiltech.io/billetera-widget` | `BilleteraWidgetConfig.baseUrl` |
| `/home` | **No** lo pongas en `baseUrl`; el paquete lo agrega (`homePath` por defecto). |
| `dni`, `genero`, `correo`, `celular`, `tenant`, `idEntidad` | `BilleteraLaunchParams` (campo a campo). Los opcionales que no tengas, omitilos; el `tenant` no es uno de ellos. |

Ejemplo equivalente en código:

```dart
import 'package:billetera_flutter/billetera_flutter.dart';

Future<void> abrirBilletera(BuildContext context) async {
  const config = BilleteraWidgetConfig(
    baseUrl: 'https://staging.agiltech.io/billetera-widget',
    debugLogging: true, // imprime la URL final en consola
  );
  const params = BilleteraLaunchParams(
    dni: '12345678',
    genero: BilleteraGenero.masculino, // en la URL suele verse como genero=m
    correo: 'usuario@correo.com',
    celular: '584120893949',
    tenant: 'TU_TENANT_TOKEN',
  );

  final urlErr = validateBilleteraBaseUrl(config.baseUrl);
  final paramErr = params.validate();
  if (urlErr != null || paramErr != null) {
    // Mostrá el error al usuario antes de abrir el WebView
    return;
  }

  await BilleteraWidget.open(context, config: config, params: params);
}
```

Activá `debugLogging: true` y compará en consola:

`[billetera_flutter] WebView URL: …`

con la URL que abrís en Chrome/Safari (mismo host, mismos query).

### Parámetros

El paquete acepta **exactamente los mismos parámetros que el widget**. Valida solo el DNI, pero eso no alcanza para completar el flujo: sin `tenant` el middleware rechaza la creación de la solicitud.

| Parámetro | ¿Obligatorio? | Para qué sirve |
|-----------|---------------|----------------|
| `dni` | **Sí** | Identifica a la persona. Sin él, el widget no deja arrancar la solicitud. |
| `tenant` | **Sí, en la práctica** | Token de aplicación. Con él el middleware sabe contra qué núcleo de préstamos hablar y aplica el límite de solicitudes del comercio. El paquete no lo exige y el flujo se abre igual, pero al crear la solicitud el middleware la rechaza con `Falta el tenant (appToken)`. **Mandalo siempre.** |
| `genero` | No | Precarga. `BilleteraGenero`, letra `M`/`F`/`O`, o texto `Masculino`/`Femenino`/`Otro`. |
| `correo` | No | Precarga del formulario de datos. |
| `celular` | No | Precarga del formulario de datos. |
| `idEntidad` | No | Entidad de tu app dentro de la operación. |

**Los campos que no mandes, el widget se los pide al usuario** en la pantalla de datos adicionales; los que sí mandes vienen precargados y siguen siendo editables. Si tu app todavía no tiene el correo o el celular de la persona, no los pases: no hace falta inventar valores para poder abrir el flujo.

Un valor vacío o solo con espacios se trata como ausente y no llega a la URL.

Sobre `idEntidad`: queda como `…&idEntidad=ENT-9911` en la URL y el widget lo reenvía al middleware en cada llamada mediante la cabecera `X-Entity-Id`.

> **Estado actual de `idEntidad`:** el backend lo recibe y lo registra, pero todavía no lo usa para ninguna decisión de negocio. No afecta ofertas, evaluación de riesgo ni alta del préstamo. Podés empezar a enviarlo desde ya para no tener que actualizar la app cuando se le dé uso.

### Paso 4 — Dónde llamar `open`

- Tras login o apenas tengas el **DNI** de la persona. El **tenant** tiene que estar resuelto antes de abrir el flujo, no después.
- Desde un botón o al entrar a la sección “Billetera” de tu app.
- Usá el `BuildContext` de un widget montado (por ejemplo dentro de `onPressed`).

### Paso 5 — Botón atrás

El flujo son varias pantallas **dentro** del WebView. El paquete ya intercepta el botón atrás del teléfono: retrocede en el historial del widget y solo cierra la pantalla cuando ya no hay a dónde volver. No tenés que hacer nada.

Si embebés `BilleteraWebViewScreen` por tu cuenta en vez de usar `BilleteraWidget.open`, ese comportamiento viene incluido igual.

### Paso 6 — Errores frecuentes al integrar

| Error | Causa | Solución |
|-------|--------|----------|
| Página en blanco | `baseUrl` con `/home` o query mezclados | Sin `/home` ni query: `https://staging.agiltech.io/billetera-widget` |
| URL distinta al navegador | Parámetros armados a mano en la URL | Usá solo `BilleteraLaunchParams` |
| La solicitud falla al crearse (`Falta el tenant`) | Se abrió el flujo sin `tenant` | Resolvelo antes de abrir: el paquete no lo valida, el middleware sí |
| `genero` inválido | Valor fuera de M/F/O | `BilleteraGenero` o `'m'`/`'f'`/`'o'`, o no lo mandes |
| Sin red en Android | Falta `INTERNET` | Agregar permiso en manifest |

### Paso 7 — Probar sin escribir código nuevo

Desde el repo del paquete:

```bash
cd example
flutter run --dart-define=WIDGET_BASE_URL=https://staging.agiltech.io/billetera-widget
```

Ajustá `BilleteraLaunchParams` en `example/lib/main.dart` con datos de prueba válidos para tu tenant en staging.

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

`{baseUrl normalizado}/home?dni=…&genero=…&correo=…&celular=…&tenant=…&idEntidad=…`

En la URL solo aparecen los parámetros que hayas mandado con contenido, siempre en ese orden. Con solo el DNI, la URL final es `{baseUrl}/home?dni=12345678`.

### Ejemplo

**Staging** — si copiás del navegador:

```text
https://staging.agiltech.io/billetera-widget/home?dni=12345678&genero=m&correo=…&celular=…&tenant=…
```

En Flutter pasá **solo**:

```dart
baseUrl: 'https://staging.agiltech.io/billetera-widget'
```

**Local** — si copiás algo como:

```text
http://localhost:4200/home?dni=12345678&genero=M&correo=a@b.com&celular=…&tenant=…
```

En Flutter:

```dart
baseUrl: 'http://localhost:4200'  // emulador Android: http://10.0.2.2:4200
```

Los datos van siempre en `BilleteraLaunchParams`, no en la URL manual.

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

| Entorno | `baseUrl` |
|---------|-----------|
| **Staging (widget desplegado)** | `https://staging.agiltech.io/billetera-widget` |
| Emulador Android → servidor en tu PC | `http://10.0.2.2:PUERTO` (`10.0.2.2` es el alias del host desde el emulador) |
| Simulador iOS / macOS / mismo host | `http://127.0.0.1:PUERTO` o `http://localhost:PUERTO` |
| Dispositivo físico (misma WiFi) | `http://IP_DE_TU_PC:PUERTO` |
| Producción | La HTTPS que asigne tu equipo |

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

Los campos opcionales **solo se validan cuando los mandás con contenido**: que falten no es un error.

| Problema | Mensaje |
|----------|---------|
| DNI ausente o mal formado | `DNI debe tener entre 7 y 8 dígitos` |
| Género no reconocido | Depende del valor; usá `M`/`F`/`O` o `BilleteraGenero` |
| Correo con formato inválido | `Correo electrónico no válido` |
| Celular demasiado corto | `Celular no válido (mínimo 8 dígitos en total)` |

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
| `BilleteraWebViewScreen` | Misma UI para embeber donde quieras (pestaña, `IndexedStack`, tu propio `Navigator`). |
| `buildBilleteraWidgetUri` | Obtener el `Uri` final (tests, logs). |
| `parseWidgetBaseUri` | Normalizar solo la base. |
| `homePath` en `BilleteraWidgetConfig` | Si el segmento de ruta no es el predeterminado `home`. |
| `showAppBar` en `BilleteraWidgetConfig` | `false` para ocultar el `AppBar` del paquete. El widget ya trae su propio encabezado, así que evita la doble barra. |
| `appBarTitle` en `BilleteraWidgetConfig` | Título del `AppBar` cuando sí lo mostrás. |

---

## 7. Variables por entorno (`--dart-define`)

Podés inyectar la URL en tiempo de compilación y leerla con `String.fromEnvironment` (el nombre de la variable lo elegís vos en tu app):

```bash
flutter run --dart-define=BILLETERA_BASE_URL=https://staging.agiltech.io/billetera-widget
```

```dart
const base = String.fromEnvironment(
  'BILLETERA_BASE_URL',
  defaultValue: 'https://staging.agiltech.io/billetera-widget',
);
```

Para builds:

```bash
flutter build apk --dart-define=BILLETERA_BASE_URL=https://…
```

---

## 8. App de ejemplo

En `example/` hay una app mínima con `BilleteraWidget.open`. Por defecto apunta a **staging**; podés cambiar la URL con `--dart-define=WIDGET_BASE_URL=…`.

Ver [example/README.md](example/README.md).

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
