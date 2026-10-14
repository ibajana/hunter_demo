import 'package:flutter/material.dart';

import '../../core/app_dates.dart';
import '../../models/workshop_models.dart';
import '../../repositories/app_repositories.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/responsive.dart';

/// Sección Salida de Vehículos (index 4). Autoriza la salida de los vehículos
/// una vez concluidos los controles. Consulta por fecha y despliega un grid
/// coloreado por estado, con leyenda de contadores.
class SalidaScreen extends StatefulWidget {
  const SalidaScreen({super.key});

  @override
  State<SalidaScreen> createState() => _SalidaScreenState();
}

class _SalidaScreenState extends State<SalidaScreen> {
  final _fechaIniCtrl =
      TextEditingController(text: AppDates.defaultDesdeStr);
  final _fechaFinCtrl =
      TextEditingController(text: AppDates.defaultHastaStr);
  List<SalidaRow> _rows = const [];
  bool _cargando = true;

  /// Filtro de estado tipo Option Button. null = Todos.
  OrderStage? _stageFilter;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  @override
  void dispose() {
    _fechaIniCtrl.dispose();
    _fechaFinCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    await _consultar();
  }

  /// Consulta al repositorio sin tocar el foco (segura en initState).
  Future<void> _consultar() async {
    setState(() => _cargando = true);
    final r = await Repositories.taller.fetchSalidaRows(
      desde: parseFilterDate(_fechaIniCtrl.text),
      hasta: parseFilterDate(_fechaFinCtrl.text),
    );
    if (!mounted) return;
    setState(() {
      _rows = r;
      _cargando = false;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    setState(() {
      _fechaIniCtrl.text = AppDates.defaultDesdeStr;
      _fechaFinCtrl.text = AppDates.defaultHastaStr;
      _stageFilter = null;
    });
    _buscar();
  }

  Map<OrderStage, int> get _conteos {
    final m = {for (final s in OrderStage.values) s: 0};
    for (final r in _rows) {
      m[r.stage] = (m[r.stage] ?? 0) + 1;
    }
    return m;
  }

  List<SalidaRow> get _visibles => _stageFilter == null
      ? _rows
      : _rows.where((r) => r.stage == _stageFilter).toList();

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    return Column(
      children: [
        FilterPanel(
          onSearch: _buscar,
          onClear: _clear,
          activeChips: [
            _fechaIniCtrl.text,
            if (_stageFilter != null) _stageFilter!.label,
          ],
          fields: [
            FilterDateField(
                label: 'Fecha Inicio',
                controller: _fechaIniCtrl,
                lastDate: AppDates.hoy,
                onChanged: (d) {
                  _fechaFinCtrl.text = AppDates.fmt(d);
                  _buscar();
                }),
            FilterDateField(
                label: 'Fecha Final',
                controller: _fechaFinCtrl,
                enabled: false),
          ],
        ),
        // Option buttons de estado + total (filtran el grid).
        Container(
          width: double.infinity,
          color: AppColors.sectionBg,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: _optionButtons(),
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : visibles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay vehículos en este estado.',
                        style: TextStyle(color: Colors.black54)),
                  ),
                )
              : ListView(
                  children: [
                    AutoGrid(
                      children: [
                        for (final r in visibles) _salidaCard(r),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _optionButtons() {
    final c = _conteos;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _stageChip('Todos', null, _rows.length, AppColors.primary),
        for (final s in OrderStage.values)
          _stageChip(s.label, s, c[s] ?? 0, Color(s.colorValue)),
      ],
    );
  }

  Widget _stageChip(String label, OrderStage? stage, int count, Color color) {
    final selected = _stageFilter == stage;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _stageFilter = stage),
      showCheckmark: false,
      backgroundColor: Colors.white,
      selectedColor: color.withValues(alpha: 0.15),
      side: BorderSide(
          color: selected ? color : AppColors.border,
          width: selected ? 1.4 : 1),
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text('$label ($count)'),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? color : AppColors.textBody,
      ),
    );
  }

  Widget _salidaCard(SalidaRow r) {
    final o = r.order;
    final color = Color(r.stage.colorValue);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'O/Servicio ${o.os} · ${o.client.ruc} - '
                            '${o.client.name}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.steel,
                                fontSize: 12.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusPill.tint(r.stage.label, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(o.vehicle.resumen,
                        style: const TextStyle(fontSize: 11.5, height: 1.35)),
                    const SizedBox(height: 4),
                    Text('Taller: ${r.taller}',
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black54)),
                    Text('Entrega Cliente: ${r.entregaCliente}',
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black54)),
                    // Solo las órdenes en Control pueden enviarse a Salida.
                    if (r.stage == OrderStage.control) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _enviarASalida(r),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(OrderStage.salida.colorValue),
                            side: BorderSide(
                                color: Color(OrderStage.salida.colorValue)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Enviar a Salida',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarASalida(SalidaRow r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar a Salida'),
        content: Text(
          '¿Deseas enviar la O/Servicio ${r.order.os} al estado de Salida?\n\n'
          'Cliente: ${r.order.client.name}\n'
          'Vehículo: ${r.order.vehicle.marcaModelo}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(OrderStage.salida.colorValue)),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => r.stage = OrderStage.salida);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(OrderStage.salida.colorValue),
        content: Text('O/Servicio ${r.order.os} enviada a Salida.'),
      ),
    );
  }
}
