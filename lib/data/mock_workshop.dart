import '../models/reception_models.dart';
import '../models/workshop_models.dart';
import 'mock_orders.dart';

/// Datos de demo para los procesos del taller (asignación, chequeo, control de
/// calidad, salida). Todo en memoria; las O/Trabajo se derivan de las
/// [ServiceOrder] de [MockOrders].
class MockWorkshop {
  MockWorkshop._();

  // --- Técnicos (según el PDF) ---
  static const List<Technician> tecnicos = [
    Technician(code: 'E-1101', name: 'PABLO NAVARRETE'),
    Technician(code: 'E-1102', name: 'RICHARD LEON'),
    Technician(code: 'E-1103', name: 'CARLOS CAIZA'),
    Technician(code: 'E-1104', name: 'FERNANDO CHANCAY'),
    Technician(code: 'E-1105', name: 'HECTOR ALAY'),
    Technician(code: 'E-1106', name: 'LUIS CAMACHO'),
    Technician(code: 'E-1107', name: 'VARGAS MIÑO MARIA LUISA'),
    Technician(code: 'E-1108', name: 'RONY ALVARADO'),
    Technician(code: 'E-1109', name: 'SEGUNDO CANDO'),
    Technician(code: 'E-1110', name: 'GILSON AROCA'),
    Technician(code: 'E-1111', name: 'LUIS GORDILLO'),
  ];

  /// Lista con "SIN ASIGNAR" al inicio, para los dropdowns.
  static List<Technician> get tecnicosConVacio =>
      [Technician.sinAsignar, ...tecnicos];

  // --- Talleres ---
  static const List<String> talleres = [
    'TODOS LOS TALLERES',
    'GUAYAQUIL B2B',
    'GUAYAQUIL B2B (fuera)',
    'QUITO NORTE',
    'CUENCA CENTRO',
  ];

  // --- Catálogo de Novedad ---
  static const List<String> catalogoNovedad = [
    'Ninguna',
    'Accesorio',
    'Agencia incorrecta',
    'Convenio',
    'No alcanzó el tiempo',
    'No disponible',
    'No está en el Concesionario',
    'No hay autorización del Concesionario',
    'No hay con quien hablar',
    'Reprogramar',
  ];

  // --- Catálogo de Novedad Comercial (al crear la recepción) ---
  static const List<String> catalogoNovedadComercial = [
    'Ninguna',
    'Cambio de titular',
    'Renovación de contrato',
    'Garantía',
    'Reclamo comercial',
    'Convenio corporativo',
  ];

  // --- Catálogo de Motivo (por qué no se realiza el trabajo) ---
  static const List<String> catalogoMotivo = [
    'Ninguna',
    'Cliente no autoriza',
    'Falta de repuesto',
    'Vehículo no disponible',
    'Requiere reprogramación',
    'Documentación incompleta',
  ];

  // --- Estados del dispositivo / orden ---
  static const List<String> estadosDispositivo = [
    '001 - INSTALADO',
    '002 - RETIRADO',
    '003 - REVISADO',
    '004 - PENDIENTE',
  ];

  static const List<String> estadosOrden = [
    'TRABAJANDO',
    'INSTALADO',
    'PENDIENTE',
    'FINALIZADO',
  ];

  // --- Calificaciones ---
  static const List<String> calificaciones = [
    'BUENO',
    'REGULAR',
    'MALO',
    'N/A',
  ];

  // --- Parámetros de calidad del vehículo (Supervisor) ---
  static List<QualityParam> paramsVehiculo() => [
        QualityParam(code: '001', name: 'ARMADO Y TAPIZADO'),
        QualityParam(code: '008', name: 'ALFOMBRA DE PISO'),
        QualityParam(code: '010', name: 'AIRE ACONDICIONADO'),
        QualityParam(code: '012', name: 'TABLERO DE INSTRUMENTOS'),
        QualityParam(code: '015', name: 'LUCES Y SEÑALIZACIÓN'),
      ];

  // --- Parámetros de calificación del producto (Supervisor) ---
  static List<QualityParam> paramsProducto() => [
        QualityParam(code: '001', name: 'ADECUADO TIEMPO DE TRABAJO'),
        QualityParam(code: '002', name: 'APROPIADA SELECCIÓN DE MATERIALES'),
        QualityParam(code: '003', name: 'ADECUADA CONEXIÓN DE CABLES'),
        QualityParam(code: '004', name: 'CORRECTA COLOCACIÓN DEL DISPOSITIVO'),
        QualityParam(code: '005', name: 'PRUEBAS DE FUNCIONAMIENTO OK'),
      ];

  // --- Servicios del dispositivo ---
  static List<ServiceItem> servicios() => [
        ServiceItem('BLOQUEAR ENCENDIDO',
            selected: true, nota: 'Aún no está el proceso de Ejecución'),
        ServiceItem('DESBLOQUEAR ENCENDIDO'),
        ServiceItem('ABRIR SEGUROS'),
        ServiceItem('PARALIZACIÓN DE VEHÍCULO'),
      ];

  // --- Dispositivo de ejemplo ---
  static const DeviceInfo dispositivoDemo = DeviceInfo(
    dispositivo: 'MON - 4634238459',
    serie: '4634238459',
    unidad: 'CALAMP',
    modelo: 'LMU2630',
    vid: '4634238459',
    ip: '10.60.13.157',
    simCard: '8934076100148474033',
    ubicacion: '100',
    servidor: 'HECTOR',
    firmware: 'V 3.9C - 170',
    script: 'HM04071610IC',
    apn: 'mtm.movistar.ec',
  );

  // --- O/Trabajo derivadas de cada O/Servicio ---
  static final List<WorkOrder> workOrders = _buildWorkOrders();

  static List<WorkOrder> _buildWorkOrders() {
    final list = <WorkOrder>[];
    var seq = 219971;
    for (final o in MockOrders.all) {
      // O/Servicio de prueba con VARIAS (4) O/Trabajo asociadas.
      if (o.os == 'OS1025200777') {
        list.addAll(_multiOts(o, () => seq++));
        continue;
      }
      // El resto: cada O/Servicio genera 2 O/Trabajo.
      list.add(WorkOrder(
        ot: 'OT${(seq++).toString().padLeft(10, '0')}',
        os: o.os,
        tipoTrabajo: '001 - INST. DISPOSITIVO',
        productos: o.producto,
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: o.vehicle.comentario,
      ));
      list.add(WorkOrder(
        ot: 'OT${(seq++).toString().padLeft(10, '0')}',
        os: o.os,
        tipoTrabajo: '006 - MANTENIMIENTO- CHEQUEO DE DISPOSITIVO',
        productos: 'MCH - CHEQ HM CORPORATIVO CHEQUEO',
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: 'Equipo dañado se instala otro equipo',
      ));
    }
    return list;
  }

  /// 4 O/Trabajo distintas para la misma O/Servicio (caso de prueba multi-OT).
  static List<WorkOrder> _multiOts(ServiceOrder o, int Function() next) {
    String ot() => 'OT${next().toString().padLeft(10, '0')}';
    return [
      WorkOrder(
        ot: ot(),
        os: o.os,
        tipoTrabajo: '001 - INST. DISPOSITIVO',
        productos: 'CAD - ALQU HM CORPORATIVO EQUIPO ALQUILER',
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: 'Instalación de rastreo GPS principal',
      ),
      WorkOrder(
        ot: ot(),
        os: o.os,
        tipoTrabajo: '006 - MANTENIMIENTO- CHEQUEO DE DISPOSITIVO',
        productos: 'MCH - CHEQ HM CORPORATIVO CHEQUEO',
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: 'Chequeo preventivo del dispositivo instalado',
      ),
      WorkOrder(
        ot: ot(),
        os: o.os,
        tipoTrabajo: '002 - CAMBIO DE DISPOSITIVO',
        productos: 'CDP - CAMBIO HM CORPORATIVO DISPOSITIVO',
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: 'Reemplazo de equipo por falla de módem',
      ),
      WorkOrder(
        ot: ot(),
        os: o.os,
        tipoTrabajo: '010 - INSTALACION DE ACCESORIO',
        productos: 'ACC - BOTON DE PANICO / BLOQUEO',
        concesionario: '9980000000006 SIN CONCESIONARIOS',
        comentario: 'Instalación de botón de pánico y bloqueo',
      ),
    ];
  }

  /// Los filtros son de **un solo día** y por defecto cargan el día actual.
  /// La fecha final siempre coincide con la inicial (se deshabilita su edición).
  static final DateTime hoy = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();
  static String fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime get defaultDesde => hoy;
  static DateTime get defaultHasta => hoy;
  static String get defaultDesdeStr => fmtFecha(hoy);
  static String get defaultHastaStr => fmtFecha(hoy);

  /// Busca O/Trabajo por O/Servicio (parcial) y por rango de fechas.
  static List<WorkOrder> workOrdersByOs(String os,
      {DateTime? desde, DateTime? hasta}) {
    final q = os.trim().toLowerCase();
    return workOrders.where((w) {
      final coincideOs = q.isEmpty ||
          w.os.toLowerCase().contains(q) ||
          w.os.replaceAll(RegExp('[^0-9]'), '').contains(q);
      return coincideOs && orderFor(w).enRango(desde, hasta);
    }).toList();
  }

  static ServiceOrder orderFor(WorkOrder w) =>
      MockOrders.all.firstWhere((o) => o.os == w.os);

  /// Filas de Salida dentro del rango de fechas.
  static List<SalidaRow> salidaRowsEnRango(DateTime? desde, DateTime? hasta) =>
      salidaRows.where((r) => r.order.enRango(desde, hasta)).toList();

  // --- Filas de Salida de Vehículos con estado/fase ---
  static final List<SalidaRow> salidaRows = _buildSalida();

  static List<SalidaRow> _buildSalida() {
    const stages = OrderStage.values;
    final rows = <SalidaRow>[];
    for (var i = 0; i < MockOrders.all.length; i++) {
      final o = MockOrders.all[i];
      rows.add(SalidaRow(
        order: o,
        taller: 'GUAYAQUIL Regular (taller Veraza)',
        entregaCliente: o.client.telefono,
        stage: stages[i % stages.length],
      ));
    }
    return rows;
  }
}
