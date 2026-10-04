import 'package:flutter/material.dart';

import '../../core/app_dates.dart';
import '../../models/workshop_models.dart';
import '../../repositories/app_repositories.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/responsive.dart';
import 'chequeo_recepcion_screen.dart';

/// Sección Chequeo de Órdenes de Trabajo (index 2). Dos sub-pestañas:
/// Chequeos y Novedad.
class ChequeoScreen extends StatefulWidget {
  const ChequeoScreen({super.key});

  @override
  State<ChequeoScreen> createState() => _ChequeoScreenState();
}

class _ChequeoScreenState extends State<ChequeoScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubTabBar(
          labels: const ['Chequeos', 'Novedad'],
          activeIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: _tab == 0 ? const _ChequeoTab() : const _NovedadTab(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña CHEQUEO
// ---------------------------------------------------------------------------
class _ChequeoTab extends StatefulWidget {
  const _ChequeoTab();

  @override
  State<_ChequeoTab> createState() => _ChequeoTabState();
}

class _ChequeoTabState extends State<_ChequeoTab> {
  final _fechaIniCtrl =
      TextEditingController(text: AppDates.defaultDesdeStr);
  final _fechaFinCtrl =
      TextEditingController(text: AppDates.defaultHastaStr);
  final _osCtrl = TextEditingController();
  Technician _tecnico = AppCatalogs.tecnicos.first;
  List<WorkOrder> _resultados = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _fechaIniCtrl.dispose();
    _fechaFinCtrl.dispose();
    _osCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    final r = await Repositories.taller.fetchWorkOrders(
      os: _osCtrl.text,
      desde: parseFilterDate(_fechaIniCtrl.text),
      hasta: parseFilterDate(_fechaFinCtrl.text),
    );
    if (!mounted) return;
    setState(() {
      _resultados = r;
      _cargando = false;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    setState(() {
      _fechaIniCtrl.text = AppDates.defaultDesdeStr;
      _fechaFinCtrl.text = AppDates.defaultHastaStr;
      _tecnico = AppCatalogs.tecnicos.first;
    });
    _buscar();
  }

  Future<void> _trabajar(WorkOrder w) async {
    final order = AppCatalogs.orderFor(w.os);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mensaje de confirmación'),
        content: Text(
          'Desea Trabajar la Orden Trabajo: ${w.ot}\n'
          'Cliente: ${order.client.ruc} - ${order.client.name}\n'
          'Orden de Servicio: ${w.os}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aceptar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChequeoRecepcionScreen(workOrder: w)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterPanel(
          onSearch: _buscar,
          onClear: _clear,
          activeChips: [
            _tecnico.name,
            if (_osCtrl.text.trim().isNotEmpty) 'OS: ${_osCtrl.text.trim()}',
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
            FilterDropdown<Technician>(
              label: 'Técnico',
              value: _tecnico,
              items: AppCatalogs.tecnicos,
              itemLabel: (t) => t.name,
              onChanged: (v) => setState(() => _tecnico = v!),
            ),
            FilterField(
                label: 'Orden Servicio',
                controller: _osCtrl,
                hint: 'Orden Servicio',
                numeric: true,
                maxLength: 12,
                onSubmit: _buscar),
          ],
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _grupos.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No hay O/Servicio para el criterio.',
                        style: TextStyle(color: Colors.black54)),
                  ),
                )
              : ListView(
                  children: [
                    AutoGrid(
                      children: [
                        for (final os in _grupos.keys)
                          _osGroupCard(os, _grupos[os]!),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Agrupa las O/Trabajo resultantes por O/Servicio (conserva el orden).
  Map<String, List<WorkOrder>> get _grupos {
    final map = <String, List<WorkOrder>>{};
    for (final w in _resultados) {
      map.putIfAbsent(w.os, () => []).add(w);
    }
    return map;
  }

  /// Tarjeta de una O/Servicio con sus O/Trabajo listadas; se elige cuál
  /// chequear tocándola.
  Widget _osGroupCard(String os, List<WorkOrder> ots) {
    final order = AppCatalogs.orderFor(ots.first.os);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.sectionBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('O/Servicio $os',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 13)),
                    ),
                    StatusPill('${ots.length} O/Trabajo', kind: PillKind.info),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${order.client.ruc} - ${order.client.name}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textStrong,
                        fontWeight: FontWeight.w600)),
                Text(order.vehicle.resumen,
                    style: const TextStyle(fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          for (var i = 0; i < ots.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: () => _trabajar(ots[i]),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primarySoft,
                      child:
                          Icon(Icons.build, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ots[i].ot,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.steel,
                                  fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text('Tipo Trabajo: ${ots[i].tipoTrabajo}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.label,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(ots[i].productos,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black38),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña NOVEDAD
// ---------------------------------------------------------------------------
class _NovedadTab extends StatefulWidget {
  const _NovedadTab();

  @override
  State<_NovedadTab> createState() => _NovedadTabState();
}

class _NovedadTabState extends State<_NovedadTab> {
  // Fecha única = un solo día (novedades de esa fecha).
  final _fechaCtrl =
      TextEditingController(text: AppDates.defaultDesdeStr);
  final _osCtrl = TextEditingController();
  String _taller = AppCatalogs.talleres.first;
  List<WorkOrder> _resultados = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _fechaCtrl.dispose();
    _osCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    FocusScope.of(context).unfocus();
    final dia = parseFilterDate(_fechaCtrl.text);
    setState(() => _cargando = true);
    final r = await Repositories.taller
        .fetchWorkOrders(os: _osCtrl.text, desde: dia, hasta: dia);
    if (!mounted) return;
    setState(() {
      _resultados = r;
      _cargando = false;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    setState(() {
      _fechaCtrl.text = AppDates.defaultDesdeStr;
      _taller = AppCatalogs.talleres.first;
    });
    _buscar();
  }

  void _grabar(WorkOrder w) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Novedad "${w.novedad}" registrada en ${w.ot}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterPanel(
          onSearch: _buscar,
          onClear: _clear,
          activeChips: [
            if (_taller != AppCatalogs.talleres.first) _taller,
            if (_osCtrl.text.trim().isNotEmpty) 'OS: ${_osCtrl.text.trim()}',
          ],
          fields: [
            FilterDateField(
                label: 'Fecha',
                controller: _fechaCtrl,
                lastDate: AppDates.hoy,
                onChanged: (_) => _buscar()),
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
                numeric: true,
                maxLength: 12,
                onSubmit: _buscar),
          ],
        ),
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    AutoGrid(
                      children: [
                        for (final w in _resultados) _novedadCard(w),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _novedadCard(WorkOrder w) {
    final order = AppCatalogs.orderFor(w.os);
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${w.os} · ${w.ot}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.steel,
                      fontSize: 13)),
              const SizedBox(height: 4),
              _nov('Cliente', '${order.client.ruc} - ${order.client.name}'),
              _nov('Productos', w.productos),
              _nov('Tipo Trabajo', w.tipoTrabajo),
              _nov('Técnico', w.tecnico.name),
              _nov('Concesionario', w.concesionario),
              _nov('Comentario', w.comentario),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: w.novedad,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                decoration: const InputDecoration(
                    labelText: 'Novedad',
                    filled: true,
                    fillColor: Colors.white),
                items: [
                  for (final n in AppCatalogs.catalogoNovedad)
                    DropdownMenuItem(value: n, child: Text(n)),
                ],
                onChanged: (v) => setState(() => w.novedad = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 2,
                maxLength: 200,
                initialValue: w.observacionNovedad,
                onChanged: (v) => w.observacionNovedad = v,
                decoration: const InputDecoration(
                    labelText: 'Observación',
                    filled: true,
                    fillColor: Colors.white),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _grabar(w),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Grabar'),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _nov(String k, String v) {
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
}

