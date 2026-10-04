import '../models/reception_models.dart';
import '../models/workshop_models.dart';
import 'mock_taller_repository.dart';
import 'taller_repository.dart';

/// Punto único de acceso al repositorio (y de intercambio de fuente de datos).
///
/// Para conectar el backend, basta con cambiar [taller] por la implementación
/// real (p. ej. `Repositories.taller = ApiTallerRepository(...)`) antes de
/// llamar a [bootstrap]. Ninguna pantalla se modifica.
class Repositories {
  Repositories._();

  /// Implementación activa. Hoy: datos de ejemplo. Mañana: backend.
  static TallerRepository taller = const MockTallerRepository();

  /// Carga los catálogos/datos de referencia una sola vez al iniciar la app.
  /// Debe llamarse antes de usar [AppCatalogs].
  static Future<void> bootstrap() => AppCatalogs._load(taller);
}

/// Caché en memoria de los datos de referencia (catálogos y plantillas), que
/// las pantallas y los dropdowns consultan de forma síncrona. Se llena una vez
/// desde el repositorio en [Repositories.bootstrap]. Con un backend real, estos
/// mismos datos vendrían de la API en el arranque.
class AppCatalogs {
  AppCatalogs._();

  static late List<Technician> tecnicos;
  static late List<String> talleres;
  static late List<String> catalogoNovedad;
  static late List<String> catalogoNovedadComercial;
  static late List<String> catalogoMotivo;
  static late List<String> estadosDispositivo;
  static late List<String> estadosOrden;
  static late List<String> calificaciones;
  static late DeviceInfo dispositivoDemo;

  // Plantillas (se clonan por orden/formulario porque su estado se edita).
  static late List<QualityParam> _tplParamsVehiculo;
  static late List<QualityParam> _tplParamsProducto;
  static late List<ServiceItem> _tplServicios;

  // Directorio de O/Servicio para resolver la orden de una O/Trabajo.
  static late List<ServiceOrder> _orders;

  /// Técnicos con "SIN ASIGNAR" al inicio (para los dropdowns de asignación).
  static List<Technician> get tecnicosConVacio =>
      [Technician.sinAsignar, ...tecnicos];

  static List<QualityParam> newParamsVehiculo() =>
      _tplParamsVehiculo.map((p) => p.copy()).toList();
  static List<QualityParam> newParamsProducto() =>
      _tplParamsProducto.map((p) => p.copy()).toList();
  static List<ServiceItem> newServicios() =>
      _tplServicios.map((s) => s.copy()).toList();

  /// Directorio completo de O/Servicio (precargado).
  static List<ServiceOrder> get allOrders => _orders;

  /// O/Servicio por código (lanza si no existe; el directorio se precarga).
  static ServiceOrder orderFor(String os) =>
      _orders.firstWhere((o) => o.os == os);

  static Future<void> _load(TallerRepository r) async {
    // En paralelo para que el arranque sea rápido (una sola espera de red).
    final res = await Future.wait<dynamic>([
      r.fetchTecnicos(),
      r.fetchTalleres(),
      r.fetchCatalogoNovedad(),
      r.fetchCatalogoNovedadComercial(),
      r.fetchCatalogoMotivo(),
      r.fetchEstadosDispositivo(),
      r.fetchEstadosOrden(),
      r.fetchCalificaciones(),
      r.fetchDispositivoDemo(),
      r.fetchParamsVehiculo(),
      r.fetchParamsProducto(),
      r.fetchServicios(),
      r.fetchAllOrders(),
    ]);
    tecnicos = res[0] as List<Technician>;
    talleres = res[1] as List<String>;
    catalogoNovedad = res[2] as List<String>;
    catalogoNovedadComercial = res[3] as List<String>;
    catalogoMotivo = res[4] as List<String>;
    estadosDispositivo = res[5] as List<String>;
    estadosOrden = res[6] as List<String>;
    calificaciones = res[7] as List<String>;
    dispositivoDemo = res[8] as DeviceInfo;
    _tplParamsVehiculo = res[9] as List<QualityParam>;
    _tplParamsProducto = res[10] as List<QualityParam>;
    _tplServicios = res[11] as List<ServiceItem>;
    _orders = res[12] as List<ServiceOrder>;
  }
}
