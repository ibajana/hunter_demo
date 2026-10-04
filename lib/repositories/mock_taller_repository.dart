import '../data/mock_orders.dart';
import '../data/mock_workshop.dart';
import '../models/reception_models.dart';
import '../models/workshop_models.dart';
import 'taller_repository.dart';

/// Implementación de [TallerRepository] con los datos de ejemplo en memoria
/// ([MockOrders] / [MockWorkshop]). Simula la latencia de red con un pequeño
/// retardo para que la app ya trabaje de forma asíncrona (igual que con un
/// backend real). Para conectar el backend se crea otra implementación
/// (`ApiTallerRepository`) y se registra en [Repositories.taller]; las
/// pantallas no cambian.
class MockTallerRepository implements TallerRepository {
  const MockTallerRepository();

  /// Retardo que imita una respuesta de red.
  static const Duration _latency = Duration(milliseconds: 120);

  Future<T> _reply<T>(T value) async {
    await Future<void>.delayed(_latency);
    return value;
  }

  // --- Catálogos ---
  @override
  Future<List<Technician>> fetchTecnicos() => _reply(MockWorkshop.tecnicos);

  @override
  Future<List<String>> fetchTalleres() => _reply(MockWorkshop.talleres);

  @override
  Future<List<String>> fetchCatalogoNovedad() =>
      _reply(MockWorkshop.catalogoNovedad);

  @override
  Future<List<String>> fetchCatalogoNovedadComercial() =>
      _reply(MockWorkshop.catalogoNovedadComercial);

  @override
  Future<List<String>> fetchCatalogoMotivo() =>
      _reply(MockWorkshop.catalogoMotivo);

  @override
  Future<List<String>> fetchEstadosDispositivo() =>
      _reply(MockWorkshop.estadosDispositivo);

  @override
  Future<List<String>> fetchEstadosOrden() =>
      _reply(MockWorkshop.estadosOrden);

  @override
  Future<List<String>> fetchCalificaciones() =>
      _reply(MockWorkshop.calificaciones);

  @override
  Future<DeviceInfo> fetchDispositivoDemo() =>
      _reply(MockWorkshop.dispositivoDemo);

  @override
  Future<List<QualityParam>> fetchParamsVehiculo() =>
      _reply(MockWorkshop.paramsVehiculo());

  @override
  Future<List<QualityParam>> fetchParamsProducto() =>
      _reply(MockWorkshop.paramsProducto());

  @override
  Future<List<ServiceItem>> fetchServicios() =>
      _reply(MockWorkshop.servicios());

  @override
  Future<List<ServiceOrder>> fetchAllOrders() => _reply(MockOrders.all);

  // --- Consultas dinámicas ---
  @override
  Future<List<ServiceOrder>> searchOrders({
    String placa = '',
    String identificacion = '',
    String os = '',
  }) =>
      _reply(MockOrders.search(
        placa: placa,
        identificacion: identificacion,
        os: os,
      ));

  @override
  Future<List<WorkOrder>> fetchWorkOrders({
    String os = '',
    DateTime? desde,
    DateTime? hasta,
  }) =>
      _reply(MockWorkshop.workOrdersByOs(os, desde: desde, hasta: hasta));

  @override
  Future<List<SalidaRow>> fetchSalidaRows({DateTime? desde, DateTime? hasta}) =>
      _reply(MockWorkshop.salidaRowsEnRango(desde, hasta));
}
