import 'package:flutter/foundation.dart';

import '../models/photo_item.dart';
import '../models/workshop_models.dart';
import '../repositories/app_repositories.dart';

/// Progreso de control de calidad de UNA O/Servicio. Cada orden lleva su propio
/// avance por las 3 fases (Técnico → Supervisor → Entrega), de forma que el
/// proceso es por orden y no global.
class OrderQuality {
  // Técnico: fotos de soporte (máx 10).
  final List<PhotoItem> fotosTecnico = [];

  // Supervisor: parámetros de vehículo y de producto (propios de la orden).
  final List<QualityParam> paramsVehiculo = AppCatalogs.newParamsVehiculo();
  final List<QualityParam> paramsProducto = AppCatalogs.newParamsProducto();

  // Entrega: servicios del dispositivo.
  final List<ServiceItem> serviciosEntrega = AppCatalogs.newServicios();

  // Avance de fases.
  bool tecnicoGuardado = false;
  bool? supervisorAprobado; // null = pendiente, true = aprobado, false = rechazado
  bool entregado = false;

  /// Todos los parámetros del vehículo tienen calificación.
  bool get vehiculoCalificado =>
      paramsVehiculo.every((p) => p.calificacion.isNotEmpty);

  /// Todos los parámetros de producto están calificados (marcados).
  bool get productoCalificado => paramsProducto.every((p) => p.seleccionado);

  /// El supervisor cumple la obligación TOTAL de datos (vehículo + productos).
  bool get datosCompletos => vehiculoCalificado && productoCalificado;
}

/// Estado del control de calidad. Mantiene el avance **por O/Servicio**:
/// el supervisor no puede calificar hasta que el técnico ejecute su chequeo, y
/// la entrega solo procede sobre una orden aprobada (chequeada).
class ControlCalidadState extends ChangeNotifier {
  static const int maxFotos = 10;

  final Map<String, OrderQuality> _byOs = {};

  /// Devuelve (creando si hace falta) el progreso de la O/Servicio [os].
  OrderQuality forOrder(String os) =>
      _byOs.putIfAbsent(os, () => OrderQuality());

  void notify() => notifyListeners();

  // --- Técnico ---
  void guardarTecnico(String os) {
    forOrder(os).tecnicoGuardado = true;
    notifyListeners();
  }

  // --- Supervisor ---
  void setCalificacionVehiculo(String os, QualityParam p, String c) {
    p.calificacion = c;
    notifyListeners();
  }

  void toggleProducto(String os, QualityParam p, bool v) {
    p.seleccionado = v;
    notifyListeners();
  }

  void setAprobacion(String os, bool aprobado) {
    forOrder(os).supervisorAprobado = aprobado;
    notifyListeners();
  }

  // --- Entrega ---
  void toggleServicioEntrega(String os, ServiceItem s, bool v) {
    s.selected = v;
    notifyListeners();
  }

  void registrarEntrega(String os) {
    forOrder(os).entregado = true;
    notifyListeners();
  }
}
