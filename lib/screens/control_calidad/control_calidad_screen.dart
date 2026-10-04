import 'package:flutter/material.dart';

import '../../models/reception_models.dart';
import '../../repositories/app_repositories.dart';
import '../../state/control_calidad_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/photo_collection.dart';

/// Sección Control de Calidad (index 3). Tres procesos INDEPENDIENTES según el
/// rol del usuario: Técnico · Supervisor (Calidad) · Entrega. Técnico y Calidad
/// están relacionados (el supervisor requiere el chequeo del técnico); la
/// Entrega es un proceso independiente.
class ControlCalidadScreen extends StatefulWidget {
  const ControlCalidadScreen({super.key});

  @override
  State<ControlCalidadScreen> createState() => _ControlCalidadScreenState();
}

class _ControlCalidadScreenState extends State<ControlCalidadScreen> {
  final _state = ControlCalidadState();
  int _tab = 0;

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  static const _fases = [
    _FaseHeader(
      titulo: 'Técnico',
      descripcion: 'Proceso del técnico: toma y sube las fotos de soporte del '
          'chequeo (máx 10).',
      icon: Icons.photo_camera_outlined,
      color: Color(0xFF1D4ED8), // azul
    ),
    _FaseHeader(
      titulo: 'Supervisor (Calidad)',
      descripcion: 'Proceso de calidad: requiere el chequeo del técnico. '
          'Califica los parámetros y aprueba o rechaza.',
      icon: Icons.fact_check_outlined,
      color: Color(0xFFEA580C), // naranja
    ),
    _FaseHeader(
      titulo: 'Entrega',
      descripcion: 'Proceso independiente, por orden chequeada: requiere el '
          'chequeo del técnico. Marca los servicios y registra la entrega.',
      icon: Icons.assignment_turned_in_outlined,
      color: Color(0xFF15803D), // verde
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubTabBar(
          labels: const ['Técnico', 'Supervisor', 'Entrega'],
          activeIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        _fases[_tab],
        Expanded(
          child: ListenableBuilder(
            listenable: _state,
            builder: (context, _) {
              switch (_tab) {
                case 0:
                  return _TecnicoTab(state: _state);
                case 1:
                  return _SupervisorTab(state: _state);
                default:
                  return _EntregaTab(state: _state);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Cabecera de proceso: diferencia visualmente Técnico / Supervisor / Entrega
/// (ícono + color + descripción). Son procesos independientes por rol, no pasos.
class _FaseHeader extends StatelessWidget {
  const _FaseHeader({
    required this.titulo,
    required this.descripcion,
    required this.icon,
    required this.color,
  });

  final String titulo;
  final String descripcion;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border(bottom: BorderSide(color: color, width: 2.5)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de consulta por O/Servicio o Chasis, reutilizada por las 3 fases.
class _ConsultaBar extends StatelessWidget {
  const _ConsultaBar({
    required this.osCtrl,
    required this.chasisCtrl,
    required this.onSearch,
    required this.onClear,
    this.showChasis = true,
  });

  final TextEditingController osCtrl;
  final TextEditingController chasisCtrl;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final bool showChasis;

  @override
  Widget build(BuildContext context) {
    return FilterPanel(
      onSearch: onSearch,
      onClear: onClear,
      activeChips: [
        if (osCtrl.text.trim().isNotEmpty) 'OS: ${osCtrl.text.trim()}',
        if (showChasis && chasisCtrl.text.trim().isNotEmpty)
          'Chasis: ${chasisCtrl.text.trim()}',
      ],
      fields: [
        FilterField(
            label: 'Orden Servicio',
            controller: osCtrl,
            numeric: true,
            maxLength: 12,
            onSubmit: onSearch),
        if (showChasis)
          FilterField(
              label: 'Chasis',
              controller: chasisCtrl,
              maxLength: 17,
              onSubmit: onSearch),
      ],
    );
  }
}

/// Lista de O/Servicio que coinciden con el filtro (o todas si está vacío).
List<ServiceOrder> _buscarOrdenes(String os, String chasis) {
  final o = os.trim().toLowerCase();
  final c = chasis.trim().toLowerCase();
  if (o.isEmpty && c.isEmpty) return AppCatalogs.allOrders;
  return AppCatalogs.allOrders.where((order) {
    final matchOs = o.isNotEmpty &&
        (order.os.toLowerCase().contains(o) || order.osNumber.contains(o));
    final matchCh =
        c.isNotEmpty && order.vehicle.chasis.toLowerCase().contains(c);
    return matchOs || matchCh;
  }).toList();
}

/// Estado de una O/Servicio en cada proceso (independientes). Devuelve una
/// píldora de calidad (técnico+supervisor) y, por separado, la de entrega.
List<({String label, PillKind kind})> _estadoOrden(OrderQuality q) {
  final pills = <({String label, PillKind kind})>[];
  // Calidad: técnico y supervisor están relacionados.
  if (q.supervisorAprobado == true) {
    pills.add((label: 'Aprobado', kind: PillKind.success));
  } else if (q.supervisorAprobado == false) {
    pills.add((label: 'Rechazado', kind: PillKind.danger));
  } else if (q.tecnicoGuardado) {
    pills.add((label: 'Chequeo listo', kind: PillKind.info));
  } else {
    pills.add((label: 'Sin chequeo', kind: PillKind.neutral));
  }
  // Entrega: proceso independiente.
  if (q.entregado) pills.add((label: 'Entregado', kind: PillKind.success));
  return pills;
}

/// Lista seleccionable de O/Servicio: se muestra mientras no se elige una,
/// para que Control de Calidad sea intuitivo (no una pantalla vacía). Cada
/// tarjeta muestra el estado de la orden dentro del flujo de calidad.
class _OrdenSelector extends StatelessWidget {
  const _OrdenSelector({
    required this.orders,
    required this.onSelect,
    required this.state,
  });

  final List<ServiceOrder> orders;
  final ValueChanged<ServiceOrder> onSelect;
  final ControlCalidadState state;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No hay O/Servicio para el criterio de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Selecciona una O/Servicio para continuar',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ),
        for (final o in orders)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(o),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(Icons.directions_car,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.os,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(o.client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5)),
                            const SizedBox(height: 2),
                            Text(
                                '${o.vehicle.marcaModelo} · ${o.vehicle.chasis}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final e
                                    in _estadoOrden(state.forOrder(o.os)))
                                  StatusPill(e.label, kind: e.kind),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Cabecera con la O/Servicio seleccionada. (Sin botón "Cambiar": para elegir
/// otra orden se usa Limpiar / la barra de búsqueda.)
class _SeleccionHeader extends StatelessWidget {
  const _SeleccionHeader({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${order.os} · ${order.client.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

/// Panel que bloquea una fase hasta que se cumpla el paso anterior.
class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 13.5, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TÉCNICO — datos del producto + fotos (máx 10)
// ---------------------------------------------------------------------------
class _TecnicoTab extends StatefulWidget {
  const _TecnicoTab({required this.state});
  final ControlCalidadState state;

  @override
  State<_TecnicoTab> createState() => _TecnicoTabState();
}

class _TecnicoTabState extends State<_TecnicoTab> {
  final _osCtrl = TextEditingController();
  final _chasisCtrl = TextEditingController();
  ServiceOrder? _order;

  @override
  void dispose() {
    _osCtrl.dispose();
    _chasisCtrl.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    // Filtra la lista (vuelve al selector); el usuario elige de la lista.
    setState(() => _order = null);
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    _chasisCtrl.clear();
    setState(() => _order = null);
  }

  void _guardar() {
    widget.state.guardarTecnico(_order!.os);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Chequeo del técnico guardado para ${_order!.os}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final q = _order == null ? null : s.forOrder(_order!.os);
    return Column(
      children: [
        _ConsultaBar(
            osCtrl: _osCtrl,
            chasisCtrl: _chasisCtrl,
            onSearch: _buscar,
            onClear: _clear),
        Expanded(
          child: _order == null
              ? _OrdenSelector(
                  orders: _buscarOrdenes(_osCtrl.text, _chasisCtrl.text),
                  onSelect: (o) => setState(() => _order = o),
                  state: s,
                )
              : ListView(
                  children: [
                    _SeleccionHeader(order: _order!),
                    const SectionHeader('Datos del Producto'),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Orden Servicio ${_order!.os} · ${_order!.producto}\n'
                        'Vehículo: ${_order!.vehicle.marcaModelo}',
                        style: const TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                    PhotoCollectionField(
                      items: q!.fotosTecnico,
                      onChanged: s.notify,
                      title: 'Fotos de soporte',
                      maxPhotos: ControlCalidadState.maxFotos,
                      captionLabel: 'Comentario',
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardar,
                          icon: Icon(q.tecnicoGuardado
                              ? Icons.check_circle
                              : Icons.save),
                          label: Text(q.tecnicoGuardado
                              ? 'Chequeo guardado'
                              : 'Guardar chequeo'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SUPERVISOR — calificar vehículo y producto + ver fotos del técnico
// ---------------------------------------------------------------------------
class _SupervisorTab extends StatefulWidget {
  const _SupervisorTab({required this.state});
  final ControlCalidadState state;

  @override
  State<_SupervisorTab> createState() => _SupervisorTabState();
}

class _SupervisorTabState extends State<_SupervisorTab> {
  final _osCtrl = TextEditingController();
  final _chasisCtrl = TextEditingController();
  ServiceOrder? _order;

  @override
  void dispose() {
    _osCtrl.dispose();
    _chasisCtrl.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    setState(() => _order = null);
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    _chasisCtrl.clear();
    setState(() => _order = null);
  }

  void _decidir(bool aprobado) {
    final q = widget.state.forOrder(_order!.os);
    if (aprobado && !q.datosCompletos) {
      final falta = !q.vehiculoCalificado
          ? 'todos los parámetros del vehículo'
          : 'todos los parámetros de producto';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.editable,
          content: Text('Debe calificar $falta antes de aprobar.'),
        ),
      );
      return;
    }
    widget.state.setAprobacion(_order!.os, aprobado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: aprobado ? AppColors.accent : AppColors.editable,
        content: Text(aprobado
            ? 'Control de calidad APROBADO por el supervisor.'
            : 'Control de calidad RECHAZADO.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final q = _order == null ? null : s.forOrder(_order!.os);
    return Column(
      children: [
        _ConsultaBar(
            osCtrl: _osCtrl,
            chasisCtrl: _chasisCtrl,
            onSearch: _buscar,
            onClear: _clear),
        Expanded(
          child: _order == null
              ? _OrdenSelector(
                  orders: _buscarOrdenes(_osCtrl.text, _chasisCtrl.text),
                  onSelect: (o) => setState(() => _order = o),
                  state: s,
                )
              // El supervisor no puede avanzar hasta que el técnico ejecute
              // su control de calidad de esta O/Servicio.
              : !q!.tecnicoGuardado
                  ? Column(
                      children: [
                        _SeleccionHeader(order: _order!),
                        const Expanded(
                          child: _LockedPanel(
                            mensaje:
                                'El técnico aún no ha ejecutado el control de '
                                'calidad de esta O/Servicio.\n\n'
                                'No puedes calificar hasta que el técnico '
                                'guarde su chequeo.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      children: [
                        _SeleccionHeader(order: _order!),
                        const SectionHeader('Datos del Producto'),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Orden Servicio ${_order!.os} · ${_order!.producto}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        _ObligatorioHeader(
                            'Datos del Vehículo', q.vehiculoCalificado),
                        for (final p in q.paramsVehiculo)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(p.etiqueta,
                                      style: const TextStyle(fontSize: 12.5)),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: p.calificacion.isEmpty
                                        ? null
                                        : p.calificacion,
                                    isExpanded: true,
                                    isDense: true,
                                    hint: const Text('Calificación',
                                        style: TextStyle(fontSize: 11)),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                    items: [
                                      for (final c
                                          in AppCatalogs.calificaciones)
                                        DropdownMenuItem(
                                            value: c, child: Text(c)),
                                    ],
                                    onChanged: (v) => s.setCalificacionVehiculo(
                                        _order!.os, p, v!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _ObligatorioHeader(
                            'Calificar Productos', q.productoCalificado),
                        for (final p in q.paramsProducto)
                          CheckboxListTile(
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: p.seleccionado,
                            title: Text(p.etiqueta,
                                style: const TextStyle(fontSize: 12.5)),
                            onChanged: (v) =>
                                s.toggleProducto(_order!.os, p, v ?? false),
                          ),
                        if (q.fotosTecnico.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('El técnico aún no ha subido fotos.',
                                  style: TextStyle(color: Colors.black38)),
                            ),
                          )
                        else
                          PhotoCollectionField(
                            items: q.fotosTecnico,
                            onChanged: s.notify,
                            title: 'Fotos del Técnico',
                            readOnly: true,
                          ),
                        if (q.supervisorAprobado != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: StatusPill(
                                q.supervisorAprobado!
                                    ? 'Aprobado'
                                    : 'Rechazado',
                                kind: q.supervisorAprobado!
                                    ? PillKind.success
                                    : PillKind.danger,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _decidir(true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aprobar'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _decidir(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.editable,
                                    side: const BorderSide(
                                        color: AppColors.editable),
                                  ),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
        ),
      ],
    );
  }
}

/// Cabecera de sección obligatoria con indicador de completitud (para que el
/// supervisor vea qué le falta calificar antes de aprobar).
class _ObligatorioHeader extends StatelessWidget {
  const _ObligatorioHeader(this.titulo, this.completo);
  final String titulo;
  final bool completo;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(
      titulo,
      trailing: StatusPill(
        completo ? 'Completo' : 'Obligatorio',
        kind: completo ? PillKind.success : PillKind.warning,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ENTREGA — datos del dispositivo + detalle de servicios (grid)
// ---------------------------------------------------------------------------
class _EntregaTab extends StatefulWidget {
  const _EntregaTab({required this.state});
  final ControlCalidadState state;

  @override
  State<_EntregaTab> createState() => _EntregaTabState();
}

class _EntregaTabState extends State<_EntregaTab> {
  final _osCtrl = TextEditingController();
  final _chasisCtrl = TextEditingController();
  ServiceOrder? _order;

  @override
  void dispose() {
    _osCtrl.dispose();
    _chasisCtrl.dispose();
    super.dispose();
  }

  void _buscar() {
    FocusScope.of(context).unfocus();
    setState(() => _order = null);
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _osCtrl.clear();
    _chasisCtrl.clear();
    setState(() => _order = null);
  }

  void _registrar() {
    final q = widget.state.forOrder(_order!.os);
    widget.state.registrarEntrega(_order!.os);
    final n = q.serviciosEntrega.where((s) => s.selected).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Entrega registrada · $n servicio(s) marcados.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final q = _order == null ? null : s.forOrder(_order!.os);
    return Column(
      children: [
        _ConsultaBar(
            osCtrl: _osCtrl,
            chasisCtrl: _chasisCtrl,
            onSearch: _buscar,
            onClear: _clear,
            showChasis: false),
        Expanded(
          child: _order == null
              ? _OrdenSelector(
                  orders: _buscarOrdenes(_osCtrl.text, _chasisCtrl.text),
                  onSelect: (o) => setState(() => _order = o),
                  state: s,
                )
              // Proceso independiente, pero POR ORDEN CHEQUEADA: requiere el
              // chequeo del técnico; no depende de la aprobación del supervisor.
              : !q!.tecnicoGuardado
                  ? Column(
                      children: [
                        _SeleccionHeader(order: _order!),
                        const Expanded(
                          child: _LockedPanel(
                            mensaje:
                                'La entrega es por orden chequeada.\n\n'
                                'El técnico debe realizar el chequeo de esta '
                                'O/Servicio antes de registrar la entrega.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                  children: [
                    _SeleccionHeader(order: _order!),
                    const SectionHeader('Datos del Dispositivo'),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente: ${_order!.client.name}',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Vehículo: ${_order!.vehicle.resumen}',
                              style:
                                  const TextStyle(fontSize: 12, height: 1.35)),
                        ],
                      ),
                    ),
                    const SectionHeader('Detalle del Servicio'),
                    for (final srv in q.serviciosEntrega)
                      CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: srv.selected,
                        title: Text('Servicio ${srv.name}',
                            style: const TextStyle(fontSize: 12.5)),
                        subtitle: srv.nota == null
                            ? null
                            : Text(srv.nota!,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54)),
                        onChanged: (v) => s.toggleServicioEntrega(
                            _order!.os, srv, v ?? false),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _registrar,
                          icon: Icon(q.entregado
                              ? Icons.check_circle
                              : Icons.exit_to_app),
                          label: Text(q.entregado
                              ? 'Entrega registrada'
                              : 'Registrar entrega'),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
