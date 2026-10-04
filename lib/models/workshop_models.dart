import 'reception_models.dart';

/// Técnico que puede ser asignado a una O/Trabajo.
class Technician {
  final String code;
  final String name;

  const Technician({required this.code, required this.name});

  /// Valor "sin asignar" usado por defecto en los dropdowns.
  static const Technician sinAsignar =
      Technician(code: '', name: 'SIN ASIGNAR');
}

/// Estado de avance de una O/Servicio dentro del taller. El color se usa en el
/// grid de Salida de Vehículos para identificar rápidamente la fase.
enum OrderStage {
  recepcion('Recepción', 0xFFF1C40F),
  revision('Revisión', 0xFF2980B9),
  control('Control', 0xFF16A085),
  salida('Salida', 0xFF7F8C8D);

  const OrderStage(this.label, this.colorValue);

  final String label;
  final int colorValue;
}

/// Orden de Trabajo (O/Trabajo) perteneciente a una O/Servicio. Una O/Servicio
/// puede tener varias O/Trabajo (p. ej. instalar dispositivo, mantenimiento…).
class WorkOrder {
  final String ot; // OT0000230970
  final String os; // OS al que pertenece (vincula con ServiceOrder)
  final String tipoTrabajo; // 001 - INST. DISPOSITIVO
  final String productos; // CAD - ALQU HM CORPORATIVO...
  final String concesionario;
  final String comentario;

  // Estado mutable (se ajusta durante asignación / chequeo).
  String comTecnico;
  Technician tecnico;
  bool fueraTaller;
  bool fueraCiudad;
  String novedad; // catálogo de novedad seleccionada
  String observacionNovedad;

  WorkOrder({
    required this.ot,
    required this.os,
    required this.tipoTrabajo,
    required this.productos,
    required this.concesionario,
    this.comentario = 'Comentario',
    this.comTecnico = '',
    this.tecnico = Technician.sinAsignar,
    this.fueraTaller = false,
    this.fueraCiudad = false,
    this.novedad = 'Ninguna',
    this.observacionNovedad = '',
  });

  bool get asignado => tecnico.code.isNotEmpty;
}

/// Configuración del dispositivo/equipo que se instala en el bien.
class DeviceInfo {
  final String dispositivo; // MON - 4634238459
  final String serie;
  final String unidad; // CALAMP
  final String modelo; // LMU2630
  final String vid;
  final String ip;
  final String simCard;
  final String ubicacion;
  final String servidor;
  final String firmware;
  final String script;
  final String apn;

  const DeviceInfo({
    required this.dispositivo,
    required this.serie,
    required this.unidad,
    required this.modelo,
    required this.vid,
    required this.ip,
    required this.simCard,
    required this.ubicacion,
    required this.servidor,
    required this.firmware,
    required this.script,
    required this.apn,
  });
}

/// Servicio asociado al dispositivo (BLOQUEAR ENCENDIDO, ABRIR SEGUROS…).
class ServiceItem {
  final String name;
  bool selected;
  final String? nota;

  ServiceItem(this.name, {this.selected = false, this.nota});

  /// Copia independiente (el estado se edita por orden/formulario).
  ServiceItem copy() => ServiceItem(name, selected: selected, nota: nota);
}

/// Parámetro de calidad a calificar (vehículo o producto).
class QualityParam {
  final String code; // 001
  final String name; // ARMADO Y TAPIZADO
  String calificacion; // '', BUENO, REGULAR, MALO...
  bool seleccionado;

  QualityParam({
    required this.code,
    required this.name,
    this.calificacion = '',
    this.seleccionado = false,
  });

  /// Copia independiente (la calificación se edita por orden).
  QualityParam copy() => QualityParam(
        code: code,
        name: name,
        calificacion: calificacion,
        seleccionado: seleccionado,
      );

  String get etiqueta => '$code - $name';
}

/// Fila del grid de Salida de Vehículos: O/Servicio + su fase actual.
/// [stage] es mutable: una orden en "Control" puede enviarse a "Salida".
class SalidaRow {
  final ServiceOrder order;
  final String taller;
  final String entregaCliente;
  OrderStage stage;

  SalidaRow({
    required this.order,
    required this.taller,
    required this.entregaCliente,
    required this.stage,
  });
}
