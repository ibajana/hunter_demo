import '../models/reception_models.dart';
import '../models/workshop_models.dart';

/// Contrato de acceso a datos del taller. Las pantallas dependen SOLO de esta
/// interfaz; hoy la cumple [MockTallerRepository] (datos de ejemplo), mañana
/// un `ApiTallerRepository` que consuma el backend (JSON). Cambiar de fuente
/// es cambiar la implementación registrada en [Repositories.taller].
///
/// Todos los métodos son asíncronos (`Future`) porque así responde un backend.
abstract class TallerRepository {
  // --- Catálogos / datos de referencia (se cargan una vez al iniciar) ---
  Future<List<Technician>> fetchTecnicos();
  Future<List<String>> fetchTalleres();
  Future<List<String>> fetchCatalogoNovedad();
  Future<List<String>> fetchCatalogoNovedadComercial();
  Future<List<String>> fetchCatalogoMotivo();
  Future<List<String>> fetchEstadosDispositivo();
  Future<List<String>> fetchEstadosOrden();
  Future<List<String>> fetchCalificaciones();
  Future<DeviceInfo> fetchDispositivoDemo();
  Future<List<QualityParam>> fetchParamsVehiculo();
  Future<List<QualityParam>> fetchParamsProducto();
  Future<List<ServiceItem>> fetchServicios();

  /// Directorio de O/Servicio (para resolver la orden de una O/Trabajo).
  Future<List<ServiceOrder>> fetchAllOrders();

  // --- Consultas dinámicas (las "respuestas" propias del backend) ---

  /// Recepción: busca por placa/serie, identificación (RUC) u OS.
  Future<List<ServiceOrder>> searchOrders({
    String placa = '',
    String identificacion = '',
    String os = '',
  });

  /// Chequeo / Asignación / Novedad: O/Trabajo por O/Servicio y rango de fecha.
  Future<List<WorkOrder>> fetchWorkOrders({
    String os = '',
    DateTime? desde,
    DateTime? hasta,
  });

  /// Salida de Vehículos: filas por rango de fecha.
  Future<List<SalidaRow>> fetchSalidaRows({DateTime? desde, DateTime? hasta});
}
