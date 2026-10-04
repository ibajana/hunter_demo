import 'package:flutter/foundation.dart';

import '../models/workshop_models.dart';
import '../repositories/app_repositories.dart';

/// Estado de la asignación de técnicos. Mantiene el filtro aplicado, la
/// selección múltiple de O/Trabajo y aplica la asignación de un técnico a una,
/// varias o todas las O/Trabajo de una misma O/Servicio.
class AsignacionState extends ChangeNotifier {
  List<WorkOrder> _resultados = const [];
  final Set<String> _seleccionadas = {}; // por OT
  bool _busco = false;
  bool _cargando = false;

  List<WorkOrder> get resultados => _resultados;
  bool get busco => _busco;
  bool get cargando => _cargando;

  /// Agrupa los resultados por O/Servicio conservando el orden.
  Map<String, List<WorkOrder>> get porOrdenServicio {
    final map = <String, List<WorkOrder>>{};
    for (final w in _resultados) {
      map.putIfAbsent(w.os, () => []).add(w);
    }
    return map;
  }

  bool isSelected(WorkOrder w) => _seleccionadas.contains(w.ot);

  void toggleSeleccion(WorkOrder w, bool value) {
    if (value) {
      _seleccionadas.add(w.ot);
    } else {
      _seleccionadas.remove(w.ot);
    }
    notifyListeners();
  }

  int get seleccionadasCount => _seleccionadas.length;

  Future<void> buscar({
    String os = '',
    bool soloRecepcionada = false,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    _busco = true;
    _cargando = true;
    _seleccionadas.clear();
    notifyListeners();
    _resultados = await Repositories.taller
        .fetchWorkOrders(os: os, desde: desde, hasta: hasta);
    _cargando = false;
    notifyListeners();
  }

  void setTecnico(WorkOrder w, Technician t) {
    _aplicarTecnico(w, t);
    notifyListeners();
  }

  /// Asigna el técnico a la O/Trabajo. Si se deja SIN ASIGNAR, reinicializa
  /// los indicadores de Fuera Taller / Fuera Ciudad. En asignación masiva se
  /// pueden fijar esos indicadores con [fueraTaller]/[fueraCiudad].
  void _aplicarTecnico(WorkOrder w, Technician t,
      {bool? fueraTaller, bool? fueraCiudad}) {
    w.tecnico = t;
    if (t.code.isEmpty) {
      w.fueraTaller = false;
      w.fueraCiudad = false;
    } else {
      if (fueraTaller != null) w.fueraTaller = fueraTaller;
      if (fueraCiudad != null) w.fueraCiudad = fueraCiudad;
    }
  }

  void setComTecnico(WorkOrder w, String v) {
    w.comTecnico = v;
    // No notifica: el campo de texto gestiona su propio estado.
  }

  void clearSeleccion() {
    _seleccionadas.clear();
    notifyListeners();
  }

  void setFueraTaller(WorkOrder w, bool v) {
    w.fueraTaller = v;
    notifyListeners();
  }

  void setFueraCiudad(WorkOrder w, bool v) {
    w.fueraCiudad = v;
    notifyListeners();
  }

  /// Asigna [t] a todas las O/Trabajo de [os], fijando también los
  /// indicadores Fuera Taller / Fuera Ciudad.
  void asignarATodas(String os, Technician t,
      {bool fueraTaller = false, bool fueraCiudad = false}) {
    for (final w in _resultados.where((w) => w.os == os)) {
      _aplicarTecnico(w, t,
          fueraTaller: fueraTaller, fueraCiudad: fueraCiudad);
    }
    notifyListeners();
  }

  /// Asigna [t] a las O/Trabajo seleccionadas, fijando los indicadores.
  void asignarASeleccionadas(Technician t,
      {bool fueraTaller = false, bool fueraCiudad = false}) {
    for (final w in _resultados.where((w) => _seleccionadas.contains(w.ot))) {
      _aplicarTecnico(w, t,
          fueraTaller: fueraTaller, fueraCiudad: fueraCiudad);
    }
    notifyListeners();
  }
}
