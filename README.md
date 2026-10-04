# App Taller — Hunter Demo

Aplicación móvil (Flutter) de demostración para la **gestión de procesos de un taller de instalación/mantenimiento de dispositivos de rastreo vehicular**. Cubre el ciclo operativo completo: recepción del vehículo, asignación de técnicos, chequeo de órdenes de trabajo, control de calidad y salida del vehículo.

La aplicación funciona hoy con **datos de ejemplo en memoria** (sin backend), pero está estructurada detrás de una **capa de repositorio asíncrona** diseñada para que la conexión a una API real se realice sin modificar las pantallas. El contexto de negocio es un taller en Ecuador (identificación por RUC/cédula, formato de O/Servicio y O/Trabajo).

---

## Tabla de contenido

1. [Visión general funcional](#1-visión-general-funcional)
2. [Stack tecnológico y requisitos](#2-stack-tecnológico-y-requisitos)
3. [Estructura del proyecto](#3-estructura-del-proyecto)
4. [Arquitectura y flujo de datos](#4-arquitectura-y-flujo-de-datos)
5. [Módulos funcionales](#5-módulos-funcionales)
6. [Modelo de datos](#6-modelo-de-datos)
7. [Ejecución y pruebas](#7-ejecución-y-pruebas)
8. [Integración con un backend](#8-integración-con-un-backend)
9. [Convenciones y reglas transversales](#9-convenciones-y-reglas-transversales)
10. [Limitaciones del demo](#10-limitaciones-del-demo)

---

## 1. Visión general funcional

La app organiza el trabajo del taller en cinco secciones, accesibles desde una barra de navegación inferior. El orden refleja el flujo operativo:

| #   | Sección                    | Propósito                                                                                                         |
| --- | -------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 1   | **Recepción de Vehículos** | Buscar la O/Servicio y registrar la recepción del vehículo (datos de entrega, observaciones, accesorios y fotos). |
| 2   | **Asignación de Técnico**  | Asignar un técnico a las O/Trabajo de una O/Servicio (individual, por selección o masiva).                        |
| 3   | **Chequeo de Órdenes**     | Realizar el chequeo de las O/Trabajo agrupadas por O/Servicio, y registrar novedades.                             |
| 4   | **Control de Calidad**     | Tres procesos independientes por rol: Técnico, Supervisor (Calidad) y Entrega.                                    |
| 5   | **Salida de Vehículos**    | Consultar el estado de las órdenes y autorizar la salida del vehículo.                                            |

**Conceptos de dominio:**

- **O/Servicio (Orden de Servicio):** solicitud asociada a un cliente y un vehículo (p. ej. `OS1025200777`). Es la unidad de negocio principal.
- **O/Trabajo (Orden de Trabajo):** tarea concreta dentro de una O/Servicio (instalación, mantenimiento, cambio de dispositivo, accesorio…). **Una O/Servicio puede tener varias O/Trabajo.**
- **Técnico:** recurso asignable a una O/Trabajo.
- **Estado de la orden (fase):** Recepción → Revisión → Control → Salida (usado en la sección Salida).

---

## 2. Stack tecnológico y requisitos

- **Framework:** Flutter (Dart 3, `sdk: ^3.12.2`). Validado con Flutter 3.44.x (canal stable).
- **UI:** Material 3, fuente **Inter** (incluida en `assets/fonts/`), color primario `#1E3A8A`.
- **Gestión de estado:** `ChangeNotifier` + `ListenableBuilder` (sin paquetes externos de estado) y estado local de `StatefulWidget`.
- **Dependencias** (`pubspec.yaml`):
  - `image_picker` — captura desde cámara y selección múltiple desde galería.
  - `intl` — formato y parseo de fechas (`dd/MM/yyyy`).
  - `flutter_lints` (dev) — reglas de análisis estático.
- **Plataformas:** Android e iOS. Identificador de aplicación Android: `com.example.hunter_demo`.
- **Permisos nativos:** iOS declara en `Info.plist` las claves de uso de cámara, galería y micrófono (necesarias para `image_picker`).

Requisitos para compilar: Flutter SDK instalado (`flutter doctor` en verde para la plataforma objetivo), y Android SDK/Xcode según el destino.

---

## 3. Estructura del proyecto

```
lib/
├── main.dart                     # Punto de entrada; ejecuta el bootstrap del repositorio
├── core/
│   └── app_dates.dart            # Utilidades de fecha (hoy, formato, valores por defecto de filtros)
├── models/                       # Entidades del dominio (POJOs Dart)
│   ├── reception_models.dart     # Client, Vehicle, ServiceOrder, Accessory
│   ├── workshop_models.dart      # Technician, WorkOrder, OrderStage, DeviceInfo, ServiceItem, QualityParam, SalidaRow
│   └── photo_item.dart           # PhotoItem (bytes + caption + base64)
├── repositories/                 # Capa de acceso a datos (punto de integración con backend)
│   ├── taller_repository.dart    # Interfaz (contrato) — toda asíncrona
│   ├── mock_taller_repository.dart # Implementación con datos de ejemplo + latencia simulada
│   └── app_repositories.dart     # Locator (punto de intercambio) + caché de catálogos + bootstrap
├── data/                         # Fuente de datos de ejemplo (solo la usa el repositorio mock)
│   ├── mock_orders.dart          # Órdenes de servicio de ejemplo
│   └── mock_workshop.dart        # Catálogos, técnicos, O/Trabajo derivadas, filas de salida
├── state/                        # Estado de pantallas complejas (ChangeNotifier)
│   ├── reception_form.dart
│   ├── asignacion_state.dart
│   ├── chequeo_form_state.dart
│   └── control_calidad_state.dart
├── screens/                      # Pantallas (UI)
│   ├── login_screen.dart
│   ├── main_shell.dart           # Contenedor con AppBar + NavigationBar
│   ├── reception/                # Recepción (búsqueda, detalle, pestañas B/C/D/E)
│   ├── asignacion/
│   ├── chequeo/                  # Lista + recepción de taller + formulario de 7 pestañas
│   ├── control_calidad/
│   └── salida/
├── widgets/                      # Componentes reutilizables
│   ├── common.dart               # Campos de filtro, pills de estado, headers, date field, etc.
│   ├── filter_panel.dart         # Panel de filtros colapsable (adaptable a orientación)
│   ├── photo_collection.dart     # Galería de fotos estilo moderno + visor full-screen
│   └── responsive.dart           # Breakpoints, AutoGrid y utilidades responsive
└── theme/
    └── app_theme.dart            # Tema (colores, tipografía, estilos de componentes, PillKind)
```

---

## 4. Arquitectura y flujo de datos

La aplicación sigue un patrón por capas con separación entre UI, estado y acceso a datos.

```
┌────────────────────────────────────────────────────────┐
│  UI (screens/) + estado (state/)                         │
│  - Consultas dinámicas → await Repositories.taller.X()   │
│  - Datos de referencia  → AppCatalogs.X (síncrono)       │
│  - Fechas               → AppDates.X                     │
└───────────────┬──────────────────────┬───────────────────┘
                │                      │
                ▼                      ▼
     Repositories.taller         AppCatalogs
     (TallerRepository)          (caché en memoria, cargada
                │                 en el arranque desde el repo)
                ▼
     MockTallerRepository  ──►  MockOrders / MockWorkshop
     (hoy; latencia simulada)   (datos de ejemplo)

     [Futuro: ApiTallerRepository ──► Backend / JSON]
```

### 4.1 Capa de repositorio

- **`TallerRepository`** (`repositories/taller_repository.dart`): interfaz abstracta con **todos los métodos asíncronos** (`Future`). Define el contrato que cualquier fuente de datos debe cumplir. Dos tipos de métodos:
  - **Catálogos / datos de referencia** (`fetchTecnicos`, `fetchTalleres`, `fetchCatalogoMotivo`, `fetchParamsVehiculo`, `fetchAllOrders`, etc.): se cargan una sola vez al iniciar.
  - **Consultas dinámicas** (`searchOrders`, `fetchWorkOrders`, `fetchSalidaRows`): representan las respuestas propias del backend por cada operación del usuario.
- **`MockTallerRepository`** (`repositories/mock_taller_repository.dart`): implementación actual. Delega en `MockOrders`/`MockWorkshop` y envuelve cada respuesta con un retardo de ~120 ms (`_latency`) para imitar la red y forzar que la UI trabaje de forma asíncrona.
- **`Repositories`** (`repositories/app_repositories.dart`): punto único de acceso e intercambio. El campo `Repositories.taller` determina la implementación activa.

### 4.2 Caché de catálogos (`AppCatalogs`)

Los datos de referencia (catálogos y plantillas) se consultan de forma **síncrona** por los dropdowns y constructores de estado. Para ello se precargan una sola vez al arrancar:

- `main()` ejecuta `await Repositories.bootstrap()`, que invoca `AppCatalogs._load(...)`.
- `_load` pide todos los catálogos al repositorio **en paralelo** (`Future.wait`) y los guarda en campos estáticos (`AppCatalogs.tecnicos`, `talleres`, `calificaciones`, `dispositivoDemo`, etc.).
- Las plantillas mutables (parámetros de calidad y servicios) se guardan como plantilla y se **clonan** por orden/formulario mediante `AppCatalogs.newParamsVehiculo()`, `newParamsProducto()`, `newServicios()` (cada O/Servicio edita su propia copia).
- `AppCatalogs.orderFor(os)` / `AppCatalogs.allOrders` resuelven el directorio de O/Servicio de forma síncrona (útil para construir tarjetas a partir de una O/Trabajo).

### 4.3 Estado de pantalla

- Pantallas con lógica compleja usan `ChangeNotifier`: `ReceptionForm`, `AsignacionState`, `ChequeoFormState`, `ControlCalidadState`. La UI se suscribe con `ListenableBuilder`.
- Las consultas asíncronas exponen un indicador de carga (`cargando` / `_cargando`) que las pantallas usan para mostrar un `CircularProgressIndicator` mientras llega la respuesta.

---

## 5. Módulos funcionales

### 5.1 Autenticación

- Pantalla de login con credenciales **fijas de demo**: usuario `admin`, contraseña `1234` (definidas en `login_screen.dart`).
- Un login correcto navega a `MainShell`; el botón de logout del `AppBar` pide confirmación y regresa al login.

### 5.2 Recepción de Vehículos

- **Búsqueda** por Placa/Serie (máx. 10), Identificación/RUC (numérico, máx. 13) u O/Servicio (numérico, máx. 12). Sin criterios, lista todas las órdenes.
- Cada resultado abre el **detalle de recepción** con tres pestañas:
  - **Datos del Vehículo:** datos de entrega (editables), observaciones (odómetro, combustible, llaves, controles, fecha/hora) y **Novedad Comercial** (catálogo).
  - **Accesorios:** checklist de accesorios con opción "marcar todos" y campo de novedades.
  - **Fotos:** captura/selección de imágenes. Se exige un **mínimo de 3 fotos** para finalizar la recepción.

### 5.3 Asignación de Técnico

- **Filtros:** fecha (de un solo día, ver §9), O/Servicio, taller y técnico.
- Los resultados se **agrupan por O/Servicio**, mostrando sus O/Trabajo.
- Asignación de técnico en tres modalidades: **individual** (una O/Trabajo), **por selección múltiple** y **masiva** (todas las O/Trabajo de una O/Servicio).
- Reglas:
  - Asignar `SIN ASIGNAR` **reinicia** los indicadores _Fuera Taller_ / _Fuera Ciudad_ de la O/Trabajo.
  - La asignación masiva permite fijar _Fuera Taller_ / _Fuera Ciudad_ para todas a la vez.
  - Operaciones con confirmación (Grabar/Cancelar) y campo de **Comentario Técnico**.

### 5.4 Chequeo de Órdenes

Dos sub-pestañas:

- **Chequeos:** lista **una tarjeta por O/Servicio** que agrupa sus O/Trabajo; se selecciona la O/Trabajo a chequear. El flujo es:
  1. **Recepción de taller** — se marca _Con Novedad_ / _Sin Novedad_ y se registra un comentario.
  2. **Formulario de chequeo** con 7 pestañas: Vehículo, Cliente, Dispositivo, Ordenes, Servicios, Imagen y Motivo.
     - En Vehículo, Cliente y Ordenes hay un interruptor **"Datos Correctos"**; los tres deben confirmarse para **finalizar el chequeo**.
     - Un panel superior muestra el **porcentaje de avance** del chequeo y la lista de motivos.
     - **Motivo:** se selecciona un motivo del catálogo y se pulsa el botón de **correo** ("Enviar"), que registra el motivo y simula su envío por email.
- **Novedad:** consulta por día; permite registrar una **novedad** (catálogo) y una observación por O/Trabajo.

### 5.5 Control de Calidad

Tres **procesos independientes según el rol** del usuario (no son pasos de un asistente). El estado de calidad se lleva **por O/Servicio**:

- **Técnico:** sube las fotos de soporte del chequeo (máx. 10).
- **Supervisor (Calidad):** califica los parámetros del **vehículo** (BUENO/REGULAR/MALO/N/A) y de **producto** (checklist). **Relación con Técnico:** no puede calificar hasta que el técnico haya guardado su chequeo de esa O/Servicio (muestra un panel bloqueado). Para **aprobar** es obligatorio completar **todos** los parámetros de vehículo y de producto; también puede **rechazar**.
- **Entrega:** marca los servicios del dispositivo y registra la entrega. Es un proceso **independiente del supervisor**, pero **por orden chequeada**: requiere que el técnico haya realizado el chequeo (si no, se bloquea).

El selector de O/Servicio muestra el estado de cada orden mediante píldoras (estado de calidad: _Sin chequeo / Chequeo listo / Aprobado / Rechazado_; y, por separado, _Entregado_).

### 5.6 Salida de Vehículos

- **Filtro** de fecha (de un solo día) y botones de opción por **estado/fase** (Todos, Recepción, Revisión, Control, Salida) con contadores.
- Grid de tarjetas coloreadas por fase.
- Las órdenes en estado **Control** muestran un botón **"Enviar a Salida"**, que —tras una **confirmación**— cambia la fase de la orden a _Salida_ y actualiza los contadores.

---

## 6. Modelo de datos

Entidades principales (`models/`):

| Entidad             | Descripción               | Campos destacados                                                                                                                         |
| ------------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `ServiceOrder`      | Orden de Servicio         | `os`, `producto`, `fecha` (`DateTime`), `client`, `vehicle`; `enRango(desde, hasta)`                                                      |
| `Client`            | Cliente                   | `name`, `ruc`, `direccion`, `telefono`, `email`                                                                                           |
| `Vehicle`           | Vehículo                  | `placa`, `motor`, `chasis`, `marca`, `modelo`, `color`, `cv`; `resumen`, `marcaModelo`                                                    |
| `Accessory`         | Accesorio del vehículo    | `name`, `selected`                                                                                                                        |
| `WorkOrder`         | Orden de Trabajo          | `ot`, `os`, `tipoTrabajo`, `productos`, `concesionario`; estado mutable: `tecnico`, `fueraTaller`, `fueraCiudad`, `novedad`, `comTecnico` |
| `Technician`        | Técnico                   | `code`, `name`; constante `sinAsignar`                                                                                                    |
| `OrderStage` (enum) | Fase de la orden          | `recepcion`, `revision`, `control`, `salida` (cada una con `label` y color)                                                               |
| `DeviceInfo`        | Dispositivo instalado     | `dispositivo`, `serie`, `unidad`, `modelo`, `ip`, `simCard`, `firmware`, `apn`…                                                           |
| `ServiceItem`       | Servicio del dispositivo  | `name`, `selected`, `nota`; `copy()`                                                                                                      |
| `QualityParam`      | Parámetro de calidad      | `code`, `name`, `calificacion`, `seleccionado`; `copy()`, `etiqueta`                                                                      |
| `SalidaRow`         | Fila de la sección Salida | `order`, `taller`, `entregaCliente`, `stage` (mutable)                                                                                    |
| `PhotoItem`         | Imagen                    | `bytes` (`Uint8List`), `caption`; `base64` (para envío al backend)                                                                        |

> Las imágenes se exponen como `base64` precisamente para facilitar su envío a una API. `WorkOrder` y `SalidaRow` tienen estado **mutable** porque la asignación de técnico y el cambio de fase se aplican en memoria sobre la misma instancia.

---

## 7. Ejecución y pruebas

### 7.1 Preparación

```bash
flutter pub get
```

### 7.2 Ejecutar en modo desarrollo

```bash
flutter run
```

### 7.3 Compilar APK (Android)

APK universal (debug, todas las ABIs):

```bash
flutter build apk --debug
```

APK de release optimizado para un solo ABI (recomendado para instalar en dispositivos ARM64, ~18 MB):

```bash
flutter build apk --release --target-platform android-arm64
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

Instalación por cable (requiere **depuración USB** activada y el modo USB en _Transferencia de archivos_):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Alternativamente, el APK puede transferirse al dispositivo e instalarse manualmente (habilitando "instalar apps de esta fuente").

### 7.4 Acceso

- Usuario: `admin`
- Contraseña: `1234`

### 7.5 Datos de prueba relevantes

Los datos de ejemplo se generan **relativos al día actual** del dispositivo, de modo que los filtros (que cargan "hoy" por defecto) siempre muestran resultados:

- Varias O/Servicio quedan fechadas **hoy**; una queda fechada **ayer** (para validar que el filtro por fecha realmente filtra).
- **`OS1025200777`** es un caso de prueba con **4 O/Trabajo** asociadas a una misma O/Servicio (útil para validar el agrupamiento en Chequeos y Asignación).
- En **Salida**, existe una O/Servicio en estado **Control** que habilita el botón "Enviar a Salida".

### 7.6 Análisis estático

```bash
flutter analyze
```

---

## 8. Integración con un backend

La arquitectura está preparada para sustituir la fuente de datos de ejemplo por una API real **sin modificar las pantallas**. Los pasos son:

### Paso 1 — Serialización de los modelos

Agregar `factory X.fromJson(Map<String, dynamic>)` y `Map<String, dynamic> toJson()` a las entidades de `models/`. Puede hacerse manualmente o con `json_serializable`.

Ejemplo de contrato JSON esperado para una `ServiceOrder`:

```json
{
  "os": "OS1025200777",
  "producto": "CAD - PROYECTO FLOTA CORPORATIVA (MULTI OT)",
  "fecha": "2026-10-04",
  "client": {
    "name": "MULTISERVICIOS DEL SUR CIA. LTDA.",
    "ruc": "0993456789001",
    "direccion": "AV. DOMINGO COMIN Y LA 40",
    "telefono": "+593986543210",
    "email": "flota@multiserviciossur.com.ec"
  },
  "vehicle": {
    "placa": "MSS-2045",
    "motor": "D4CB-556677",
    "chasis": "KMFWBX7JAPU998877",
    "marca": "HYUNDAI",
    "tipo": "CAMIONETA",
    "modelo": "H1 2.5 CRDI",
    "color": "GRIS",
    "comentario": "FLOTA SUR - UNIDAD 07",
    "cv": "1090777"
  }
}
```

### Paso 2 — Implementar el repositorio de API

Crear `lib/repositories/api_taller_repository.dart` que **implemente `TallerRepository`**, usando un cliente HTTP (`http`, `dio`, etc.) y los `fromJson` del Paso 1:

```dart
class ApiTallerRepository implements TallerRepository {
  ApiTallerRepository({required this.baseUrl});
  final String baseUrl;

  @override
  Future<List<ServiceOrder>> searchOrders({
    String placa = '', String identificacion = '', String os = '',
  }) async {
    final res = await http.get(Uri.parse('$baseUrl/orders?placa=$placa&...'));
    final list = jsonDecode(res.body) as List;
    return list.map((e) => ServiceOrder.fromJson(e)).toList();
  }

  // ... resto de métodos de la interfaz ...
}
```

### Paso 3 — Registrar la implementación (único cambio de "cableado")

En `lib/repositories/app_repositories.dart`, cambiar la implementación activa:

```dart
// Antes:
static TallerRepository taller = const MockTallerRepository();
// Después:
static TallerRepository taller = ApiTallerRepository(baseUrl: 'https://api.ejemplo.com');
```

El `bootstrap()` cargará los catálogos desde la API en el arranque y las consultas de las pantallas pasarán a consumir el backend. **Ninguna pantalla requiere cambios.**

### Paso 4 — Operaciones de escritura

Las acciones que hoy modifican estado **en memoria** deben convertirse en llamadas de escritura (POST/PUT) cuando exista backend. Son, principalmente:

- Asignación de técnico y de indicadores _Fuera Taller/Ciudad_ (`AsignacionState`).
- Guardado del chequeo y motivos (`ChequeoFormState`).
- Guardado de técnico / aprobación del supervisor / registro de entrega (`ControlCalidadState`).
- Cambio de fase a _Salida_ (`SalidaRow.stage`).

Se recomienda añadir los métodos de escritura correspondientes a `TallerRepository` (p. ej. `assignTechnician`, `submitQuality`, `markExit`) e invocarlos desde el estado de cada pantalla.

### Paso 5 — Autenticación

El login usa credenciales fijas (`admin`/`1234`) en `login_screen.dart`. Para producción debe reemplazarse por autenticación real (token, almacenamiento seguro de sesión y protección de las llamadas del repositorio).

### Consideraciones adicionales

- Las consultas de la UI **ya son asíncronas** y muestran indicador de carga, por lo que no requieren refactor al introducir latencia real.
- Conviene añadir **manejo de errores** (reintentos, estados de error y mensajes) en las pantallas; el demo asume respuestas exitosas.
- El retardo simulado (`MockTallerRepository._latency`) puede eliminarse o ajustarse; no afecta a la implementación de API.

---

## 9. Convenciones y reglas transversales

- **Filtros de fecha de un solo día:** todas las secciones con filtro de fecha (Asignación, Chequeos, Novedad, Salida) usan un rango de **un día**. La _Fecha Inicio_ carga **hoy** por defecto; la _Fecha Final_ está **deshabilitada** e igualada a la inicial. El **tope máximo** seleccionable es **hoy** (no se permiten fechas futuras). Las utilidades viven en `core/app_dates.dart`.
- **Tipos y longitudes de campo:** Placa/Serie 10, Identificación/RUC numérico 13, O/Servicio numérico 12, Chasis 17. Campos de texto de dato con longitud por defecto 50 y contador.
- **Validación de rango:** cuando aplica, se impide que la fecha final sea anterior a la inicial.
- **Fotos:** captura desde cámara o selección múltiple de galería (`image_picker`), miniaturas en el mismo contenedor, visor a pantalla completa con comentario (caption) y conversión a `base64`.
- **Diseño responsive:** panel de filtros colapsable (colapsado por defecto) que se adapta a orientación horizontal; `AutoGrid` distribuye las tarjetas según el ancho disponible (`widgets/responsive.dart`).
- **Tema visual:** Material 3, color primario `#1E3A8A`, AppBar blanca, `NavigationBar` inferior, tarjetas redondeadas, píldoras de estado semánticas (`PillKind`) y tipografía Inter (`theme/app_theme.dart`).

---

## 10. Limitaciones del demo

- **Sin persistencia ni backend:** los datos viven en memoria y se reinician al cerrar la app. Los cambios (asignaciones, chequeos, calidad, salida) no se guardan entre ejecuciones.
- **Autenticación simulada:** credenciales fijas, sin gestión de sesión real.
- **Acciones "enviadas por correo" / reportes:** se simulan con confirmaciones en pantalla; no envían correos reales.
- **Datos de ejemplo acotados:** un conjunto reducido de O/Servicio pensado para demostrar cada flujo.
- **Sin manejo de errores de red:** la capa mock asume siempre respuestas exitosas.
