import '../models/reception_models.dart';

/// Datos de demo. Órdenes de servicio buscables por placa, identificación
/// (RUC del cliente) u OS.
class MockOrders {
  MockOrders._();

  /// Día actual (sin hora). Las fechas de ejemplo se generan alrededor de hoy
  /// para que el filtro por día (que carga hoy por defecto) muestre resultados.
  static final DateTime _hoy = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();

  static DateTime _dia(int offset) => _hoy.add(Duration(days: offset));

  static const List<String> _meses = [
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
  ];

  static String _lugarFecha(DateTime d) =>
      'Guayaquil, ${d.day} ${_meses[d.month - 1]} ${d.year}';

  static final List<ServiceOrder> all = [
    ServiceOrder(
      os: 'OS1025175792',
      producto: 'CAD - ALQU HM CORPORATIVO EQUIPO ALQUILER',
      lugarFecha: _lugarFecha(_dia(-1)),
      fecha: _dia(-1),
      client: Client(
        name: 'IN. CAR. PALM. INDUSTRIA CARTONERA PALMAR S.A.',
        ruc: '0791717884001',
        direccion: 'AV. 25 DE JUNIO. KM 4.5 VIA A PASAJE',
        telefono: '+593984881122',
        email: 'freddyroman@incarpalm.com.ec',
      ),
      vehicle: Vehicle(
        placa: 'S/P',
        motor: '77730073',
        chasis: 'LGDCU91L4TA606821',
        marca: 'DONGFENG',
        tipo: 'CAMION',
        modelo: 'EQ1090S8CDB AC 3.8 2P 4X2 TM',
        color: 'BLANCO',
        comentario: 'INCARPALM CARROS 2',
        cv: '1066337',
      ),
    ),
    ServiceOrder(
      os: 'OS1025180044',
      producto: 'CAD - MANTENIMIENTO PREVENTIVO 10.000 KM',
      lugarFecha: _lugarFecha(_hoy),
      fecha: _hoy,
      client: Client(
        name: 'COMERCIAL ANDINA CIA. LTDA.',
        ruc: '0992133445001',
        direccion: 'AV. JUAN TANCA MARENGO KM 2.5',
        telefono: '+593991234567',
        email: 'compras@andina.com.ec',
      ),
      vehicle: Vehicle(
        placa: 'GSX-1042',
        motor: 'A15-993210',
        chasis: 'LVVDB12B8KD552001',
        marca: 'CHEVROLET',
        tipo: 'CAMIONETA',
        modelo: 'D-MAX 3.0 CRDI 4X4 CD',
        color: 'PLATA',
        comentario: 'FLOTA ANDINA 04',
        cv: '1070512',
      ),
    ),
    ServiceOrder(
      os: 'OS1025190318',
      producto: 'CAD - REVISION POR GARANTIA',
      lugarFecha: _lugarFecha(_hoy),
      fecha: _hoy,
      client: Client(
        name: 'TRANSPORTES DEL PACIFICO S.A.',
        ruc: '0990555221001',
        direccion: 'VIA PERIMETRAL KM 12.5',
        telefono: '+593987776655',
        email: 'logistica@pacificotrans.com.ec',
      ),
      vehicle: Vehicle(
        placa: 'PWT-8890',
        motor: 'J05E-778120',
        chasis: 'JHHFE8JT4LK334120',
        marca: 'HINO',
        tipo: 'CAMION',
        modelo: 'GH 500 8.0 6X2',
        color: 'AZUL',
        comentario: 'UNIDAD 12 - PACIFICO',
        cv: '1081933',
      ),
    ),
    // --- Caso de prueba: una O/Servicio con VARIAS O/Trabajo asociadas ---
    ServiceOrder(
      os: 'OS1025200777',
      producto: 'CAD - PROYECTO FLOTA CORPORATIVA (MULTI OT)',
      lugarFecha: _lugarFecha(_hoy),
      fecha: _hoy,
      client: Client(
        name: 'MULTISERVICIOS DEL SUR CIA. LTDA.',
        ruc: '0993456789001',
        direccion: 'AV. DOMINGO COMIN Y LA 40',
        telefono: '+593986543210',
        email: 'flota@multiserviciossur.com.ec',
      ),
      vehicle: Vehicle(
        placa: 'MSS-2045',
        motor: 'D4CB-556677',
        chasis: 'KMFWBX7JAPU998877',
        marca: 'HYUNDAI',
        tipo: 'CAMIONETA',
        modelo: 'H1 2.5 CRDI',
        color: 'GRIS',
        comentario: 'FLOTA SUR - UNIDAD 07',
        cv: '1090777',
      ),
    ),
  ];

  /// Busca por placa, identificación (RUC) u OS. Cualquier criterio que
  /// coincida (parcial, sin distinguir mayúsculas) devuelve la orden.
  static List<ServiceOrder> search({
    String placa = '',
    String identificacion = '',
    String os = '',
  }) {
    final p = placa.trim().toLowerCase();
    final id = identificacion.trim().toLowerCase();
    final o = os.trim().toLowerCase();

    if (p.isEmpty && id.isEmpty && o.isEmpty) return const [];

    return all.where((order) {
      final matchPlaca =
          p.isNotEmpty && order.vehicle.placa.toLowerCase().contains(p);
      final matchId =
          id.isNotEmpty && order.client.ruc.toLowerCase().contains(id);
      final matchOs = o.isNotEmpty &&
          (order.os.toLowerCase().contains(o) ||
              order.osNumber.contains(o));
      return matchPlaca || matchId || matchOs;
    }).toList();
  }
}
