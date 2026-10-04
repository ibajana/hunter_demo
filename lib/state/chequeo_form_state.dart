import 'package:flutter/foundation.dart';

import '../models/photo_item.dart';
import '../models/reception_models.dart';
import '../models/workshop_models.dart';
import '../repositories/app_repositories.dart';

/// Estado del formulario de chequeo de una O/Trabajo (el formulario grande con
/// pestañas Vehículo, Cliente, Dispositivo, Órdenes, Servicios, Imagen, Motivo).
class ChequeoFormState extends ChangeNotifier {
  ChequeoFormState({required this.workOrder, required this.conNovedad})
      : servicios = AppCatalogs.newServicios();

  final WorkOrder workOrder;
  final bool conNovedad;

  ServiceOrder get order => AppCatalogs.orderFor(workOrder.os);
  DeviceInfo get dispositivo => AppCatalogs.dispositivoDemo;

  // Datos generales
  final String latitud = '-2.189134';
  final String longitud = '-79.889903';

  // Toggles "Datos Correctos"
  bool vehiculoDatosCorrectos = false;
  bool clienteDatosCorrectos = false;
  bool productoDatosCorrectos = false;

  // Dispositivo / Orden
  String estadoDispositivo = AppCatalogs.estadosDispositivo.first;
  String estadoOrden = AppCatalogs.estadosOrden.first;
  String comentarioOrden = '';

  // Servicios asociados
  final List<ServiceItem> servicios;

  // Motivos registrados
  final List<String> motivos = [];

  // Fotos capturadas (Datos Generales / Imagen)
  final List<PhotoItem> fotos = [];

  void setVehiculoCorrecto(bool v) {
    vehiculoDatosCorrectos = v;
    notifyListeners();
  }

  void setClienteCorrecto(bool v) {
    clienteDatosCorrectos = v;
    notifyListeners();
  }

  void setProductoCorrecto(bool v) {
    productoDatosCorrectos = v;
    notifyListeners();
  }

  /// Los tres datos (vehículo, cliente, productos) deben confirmarse para grabar.
  bool get puedeGrabar =>
      vehiculoDatosCorrectos && clienteDatosCorrectos && productoDatosCorrectos;

  void setEstadoDispositivo(String v) {
    estadoDispositivo = v;
    notifyListeners();
  }

  void setEstadoOrden(String v) {
    estadoOrden = v;
    notifyListeners();
  }

  void toggleServicio(ServiceItem s, bool v) {
    s.selected = v;
    notifyListeners();
  }

  void addMotivo(String m) {
    if (m == 'Ninguna' || motivos.contains(m)) return;
    motivos.add(m);
    notifyListeners();
  }

  void removeMotivo(String m) {
    motivos.remove(m);
    notifyListeners();
  }

  void notify() => notifyListeners();

  /// Porcentaje de avance mostrado junto al panel de Motivos: combina los
  /// pasos completados del chequeo.
  int get avance {
    var done = 0;
    const total = 6;
    if (vehiculoDatosCorrectos) done++;
    if (clienteDatosCorrectos) done++;
    if (productoDatosCorrectos) done++;
    if (fotos.isNotEmpty) done++;
    if (comentarioOrden.trim().isNotEmpty) done++;
    if (estadoOrden == 'FINALIZADO' || estadoOrden == 'INSTALADO') done++;
    return ((done / total) * 100).round();
  }
}
