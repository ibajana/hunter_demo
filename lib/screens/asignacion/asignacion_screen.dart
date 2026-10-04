import 'package:flutter/material.dart';

import '../../core/app_dates.dart';
import '../../models/workshop_models.dart';
import '../../repositories/app_repositories.dart';
import '../../state/asignacion_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/responsive.dart';

/// Sección Asignación de Técnico (index 1).
/// Permite consultar las O/Servicio pendientes por filtros y asignar el técnico
/// a una, varias o todas las O/Trabajo de una misma O/Servicio.
class AsignacionScreen extends StatefulWidget {
  const AsignacionScreen({super.key});

  @override
  State<AsignacionScreen> createState() => _AsignacionScreenState();
}

class _AsignacionScreenState extends State<AsignacionScreen> {
  final _state = AsignacionState();
  final _osCtrl = TextEditingController();
  final _fechaIniCtrl =
      TextEditingController(text: AppDates.defaultDesdeStr);
  final _fechaFinCtrl =
      TextEditingController(text: AppDates.defaultHastaStr);
  String _taller = AppCatalogs.talleres.first;
  bool _soloRecepcionada = false;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _osCtrl.dispose();
    _fechaIniCtrl.dispose();
    _fechaFinCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    _state.buscar(
      os: _osCtrl.text,
      soloRecepcionada: _soloRecepcionada,
      desde: parseFilterDate(_fechaIniCtrl.text),
      hasta: parseFilterDate(_fechaFinCtrl.text),
    );
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    setState(() {
      _fechaIniCtrl.text = AppDates.defaultDesdeStr;
      _fechaFinCtrl.text = AppDates.defaultHastaStr;
      _taller = AppCatalogs.talleres.first;
      _soloRecepcionada = false;
    });
    _buscar();
  }

  // --- Asignación individual (una O/Trabajo) ---
  Future<void> _asignarUno(WorkOrder w) async {
    final t = await _pickTecnico();
    if (t == null) return;
    if (!await _confirmar('Asignación', _mensajeUno(w, t))) return;
    _state.setTecnico(w, t);
    _toast(_resultadoMsg(t, w.ot));
  }

  Future<void> _asignarATodas(String os, List<WorkOrder> ots) async {
    final r = await _dialogMasivo(
        'Asignar a todas', 'las ${ots.length} O/Trabajo de $os');
    if (r == null) return;
    _state.asignarATodas(os, r.tecnico,
        fueraTaller: r.fueraTaller, fueraCiudad: r.fueraCiudad);
    _toast(_resultadoMsg(r.tecnico, 'todas las O/Trabajo de $os'));
  }

  Future<void> _asignarASeleccionadas() async {
    final n = _state.seleccionadasCount;
    final r =
        await _dialogMasivo('Asignar seleccionadas', '$n O/Trabajo seleccionada(s)');
    if (r == null) return;
    _state.asignarASeleccionadas(r.tecnico,
        fueraTaller: r.fueraTaller, fueraCiudad: r.fueraCiudad);
    _state.clearSeleccion();
    _toast(_resultadoMsg(r.tecnico, '$n O/Trabajo seleccionada(s)'));
  }

  /// Diálogo de asignación masiva: técnico + Fuera Taller/Ciudad para aplicar
  /// a todas las O/Trabajo del alcance a la vez.
  Future<({Technician tecnico, bool fueraTaller, bool fueraCiudad})?>
      _dialogMasivo(String titulo, String alcance) {
    Technician sel = Technician.sinAsignar;
    bool ft = false;
    bool fc = false;
    return showDialog<({Technician tecnico, bool fueraTaller, bool fueraCiudad})>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          final asignado = sel.code.isNotEmpty;
          return AlertDialog(
            title: Text(titulo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Se aplicará a $alcance.',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 12),
                DropdownButtonFormField<Technician>(
                  initialValue: sel,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Técnico'),
                  items: [
                    for (final t in AppCatalogs.tecnicosConVacio)
                      DropdownMenuItem(value: t, child: Text(t.name)),
                  ],
                  onChanged: (t) => setLocal(() {
                    sel = t!;
                    if (sel.code.isEmpty) {
                      ft = false;
                      fc = false;
                    }
                  }),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: ft,
                  title: const Text('Fuera Taller'),
                  onChanged:
                      asignado ? (v) => setLocal(() => ft = v ?? false) : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: fc,
                  title: const Text('Fuera Ciudad'),
                  onChanged:
                      asignado ? (v) => setLocal(() => fc = v ?? false) : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context,
                    (tecnico: sel, fueraTaller: ft, fueraCiudad: fc)),
                child: const Text('Grabar'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _mensajeUno(WorkOrder w, Technician t) =>
      '¿Grabar la asignación de "${t.name}" a la O/Trabajo ${w.ot}?';

  String _resultadoMsg(Technician t, String scope) => t.code.isEmpty
      ? 'Se dejó sin asignar $scope'
      : 'Técnico ${t.name} asignado a $scope';

  /// Bottom sheet de técnicos, con "SIN ASIGNAR" al inicio para poder
  /// cancelar/limpiar la asignación.
  Future<Technician?> _pickTecnico() {
    return showModalBottomSheet<Technician>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Seleccionar técnico',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined,
                  color: AppColors.editable),
              title: const Text('SIN ASIGNAR'),
              subtitle: const Text('Dejar / quitar la asignación'),
              onTap: () => Navigator.pop(context, Technician.sinAsignar),
            ),
            const Divider(height: 1),
            for (final t in AppCatalogs.tecnicos)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(t.name),
                subtitle: Text(t.code),
                onTap: () => Navigator.pop(context, t),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Grabar')),
        ],
      ),
    );
    return ok ?? false;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filtros(),
        Expanded(
          child: ListenableBuilder(
            listenable: _state,
            builder: (context, _) => _resultados(),
          ),
        ),
        // Barra de acción para la selección múltiple (checks de las O/T).
        ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            if (_state.seleccionadasCount == 0) return const SizedBox.shrink();
            return Material(
              elevation: 8,
              color: AppColors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text('${_state.seleccionadasCount} seleccionada(s)',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      TextButton(
                        onPressed: _state.clearSeleccion,
                        child: const Text('Quitar'),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: _asignarASeleccionadas,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Asignar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<String> _chips() => [
        if (_taller != AppCatalogs.talleres.first) _taller,
        if (_osCtrl.text.trim().isNotEmpty) 'OS: ${_osCtrl.text.trim()}',
        if (_soloRecepcionada) 'O/S Recepcionada',
      ];

  Widget _filtros() {
    return FilterPanel(
      onSearch: _buscar,
      onClear: _clear,
      activeChips: _chips(),
      fields: [
        FilterDateField(
            label: 'Fecha Inicio',
            controller: _fechaIniCtrl,
            lastDate: AppDates.hoy,
            onChanged: (d) => setState(() {
                  _fechaFinCtrl.text = AppDates.fmt(d);
                  _buscar();
                })),
        FilterDateField(
            label: 'Fecha Final',
            controller: _fechaFinCtrl,
            enabled: false),
        FilterDropdown<String>(
          label: 'Taller',
          value: _taller,
          items: AppCatalogs.talleres,
          itemLabel: (t) => t,
          onChanged: (v) => setState(() => _taller = v!),
        ),
        FilterField(
          label: 'Orden Servicio',
          controller: _osCtrl,
          hint: 'OS…',
          numeric: true,
          maxLength: 12,
          onSubmit: _buscar,
        ),
      ],
      extra: Row(
        children: [
          Checkbox(
            value: _soloRecepcionada,
            onChanged: (v) => setState(() => _soloRecepcionada = v ?? false),
          ),
          const Text('O/S Recepcionada', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _resultados() {
    if (_state.cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    final grupos = _state.porOrdenServicio;
    if (grupos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay O/Trabajo para el criterio de búsqueda.',
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    return ListView(
      children: [
        AutoGrid(
          children: [
            for (final entry in grupos.entries)
              _grupoOs(entry.key, entry.value),
          ],
        ),
      ],
    );
  }

  Widget _grupoOs(String os, List<WorkOrder> ots) {
    final order = AppCatalogs.orderFor(ots.first.os);
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              color: AppColors.sectionBg,
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'O/Servicio $os',
                          style: const TextStyle(
                              color: AppColors.textStrong,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5),
                        ),
                        Text(
                          order.client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        Text(
                          'Cédula/RUC: ${order.client.ruc}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _asignarATodas(os, ots),
                    icon: const Icon(Icons.group_add, size: 16),
                    label: const Text('Todas'),
                  ),
                ],
              ),
            ),
            for (final w in ots) _otTile(w),
          ],
        ),
    );
  }

  Widget _otTile(WorkOrder w) {
    final order = AppCatalogs.orderFor(w.os);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _state.isSelected(w),
            onChanged: (v) => _state.toggleSeleccion(w, v ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('O/T: ${w.ot}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                            fontSize: 13)),
                    const Spacer(),
                    w.asignado
                        ? const StatusPill('Asignado', kind: PillKind.success)
                        : const StatusPill('Sin asignar',
                            kind: PillKind.danger),
                  ],
                ),
                const SizedBox(height: 4),
                Text(order.vehicle.resumen,
                    style: const TextStyle(fontSize: 11.5, height: 1.35)),
                const SizedBox(height: 4),
                _kv('Productos', w.productos),
                _kv('Tipo Trabajo', w.tipoTrabajo),
                _kv('Concesionario', w.concesionario),
                _kv('Comentario', w.comentario),
                const SizedBox(height: 8),
                // Técnico: campo tocable que abre el selector + confirmación
                // (no cambia el estado hasta Grabar).
                InkWell(
                  onTap: () => _asignarUno(w),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Técnico',
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      isDense: true,
                    ),
                    child: Text(
                      w.tecnico.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: w.asignado
                            ? AppColors.textStrong
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: ValueKey('comtec-${w.ot}'),
                  initialValue: w.comTecnico,
                  minLines: 1,
                  maxLines: 2,
                  maxLength: 200,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Comentario Técnico',
                    isDense: true,
                  ),
                  onChanged: (v) => _state.setComTecnico(w, v),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _check('Fuera Taller', w.fueraTaller,
                        (v) => _state.setFueraTaller(w, v)),
                    _check('Fuera Ciudad', w.fueraCiudad,
                        (v) => _state.setFueraCiudad(w, v)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, color: Colors.black87),
          children: [
            TextSpan(
                text: '$k: ',
                style: const TextStyle(
                    color: AppColors.label, fontWeight: FontWeight.w600)),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return Expanded(
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
