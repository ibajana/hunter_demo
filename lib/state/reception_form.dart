import 'package:flutter/foundation.dart';

import '../models/photo_item.dart';
import '../models/reception_models.dart';

/// Estado mutable de la recepción de un vehículo (pantallas B, C, D y E).
/// Se precarga con la información de la orden y permite editar los campos.
class ReceptionForm extends ChangeNotifier {
  ReceptionForm(this.order)
      : email = order.client.email,
        telefono = order.client.telefono,
        recibeCliente = order.client.name,
        entregaCliente = order.client.name,
        accesorios = _defaultAccessories();

  final ServiceOrder order;

  // --- B. Datos de la entrega del vehículo (editables) ---
  String email;
  String telefono;
  String recibeCliente;
  String entregaCliente;

  // --- C. Observaciones (todos opcionales) ---
  String odometro = '';
  String combustiblePct = '';
  String cantidadLlave = '';
  String cantidadControles = '';
  String fechaEntrega = '';
  String horaEntrega = '';
  String novedadesObservaciones = '';

  /// Novedad Comercial (catálogo) al crear la recepción.
  String novedadComercial = 'Ninguna';

  // --- D. Accesorios ---
  final List<Accessory> accesorios;
  String novedadesAccesorios = '';

  // --- E. Fotos ---
  final List<PhotoItem> fotos = [];
  static const int minFotos = 3;

  /// Notifica cambios externos (p. ej. desde el componente de fotos).
  void notify() => notifyListeners();

  int get fotosRestantes =>
      (minFotos - fotos.length).clamp(0, minFotos).toInt();
  bool get cumpleMinimoFotos => fotos.length >= minFotos;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  // Accesorios
  void toggleAccessory(Accessory a, bool value) {
    a.selected = value;
    notifyListeners();
  }

  void setAllAccessories(bool value) {
    for (final a in accesorios) {
      a.selected = value;
    }
    notifyListeners();
  }

  int get accesoriosSeleccionados =>
      accesorios.where((a) => a.selected).length;

  static List<Accessory> _defaultAccessories() => [
        Accessory('RADIO'),
        Accessory('MANUAL CARRO'),
        Accessory('LLANTA DE EMERGENCIA'),
        Accessory('GATA'),
        Accessory('JUEGO DE HERRAMIENTAS'),
        Accessory('TRIANGULOS DE SEGURIDAD'),
        Accessory('EXTINTOR'),
        Accessory('BOTIQUIN'),
        Accessory('TAPETES'),
        Accessory('ALFOMBRAS'),
      ];
}
