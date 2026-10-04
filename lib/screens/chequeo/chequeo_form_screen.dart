import 'package:flutter/material.dart';

import '../../repositories/app_repositories.dart';
import '../../models/workshop_models.dart';
import '../../state/chequeo_form_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_collection.dart';

/// Formulario de chequeo con panel superior (Datos Generales + Motivos con
/// % de avance) y 7 pestañas: Vehículo, Cliente, Dispositivo, Ordenes,
/// Servicios, Imagen, Motivo.
class ChequeoFormScreen extends StatefulWidget {
  const ChequeoFormScreen({
    super.key,
    required this.workOrder,
    required this.conNovedad,
  });

  final WorkOrder workOrder;
  final bool conNovedad;

  @override
  State<ChequeoFormScreen> createState() => _ChequeoFormScreenState();
}

class _ChequeoFormScreenState extends State<ChequeoFormScreen> {
  late final ChequeoFormState _form = ChequeoFormState(
    workOrder: widget.workOrder,
    conNovedad: widget.conNovedad,
  );
  String _motivoSel = AppCatalogs.catalogoMotivo.first;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _agregarFotos() async {
    final picked = await pickPhotos(context, allowMultiple: true);
    if (picked.isEmpty) return;
    _form.fotos.addAll(picked);
    _form.notify();
  }

  /// "Envía" por correo el motivo seleccionado (simulado) y lo registra.
  void _enviarMotivo() {
    if (_motivoSel == 'Ninguna') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.editable,
          content: Text('Selecciona un motivo para enviar.'),
        ),
      );
      return;
    }
    _form.addMotivo(_motivoSel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Motivo "$_motivoSel" enviado por correo.'),
      ),
    );
  }

  void _finalizar() {
    // No permitir grabar sin confirmar Datos Correctos de Vehículo, Cliente
    // y Productos.
    if (!_form.puedeGrabar) {
      final faltan = <String>[
        if (!_form.vehiculoDatosCorrectos) 'Vehículo',
        if (!_form.clienteDatosCorrectos) 'Cliente',
        if (!_form.productoDatosCorrectos) 'Productos',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.editable,
          content: Text(
              'Confirma "Datos Correctos" en: ${faltan.join(', ')} antes de grabar.'),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chequeo registrado'),
        content: Text(
          'O/Trabajo ${widget.workOrder.ot}\n'
          'Estado: ${_form.estadoOrden}\n'
          'Avance: ${_form.avance}% · Fotos: ${_form.fotos.length} · '
          'Motivos: ${_form.motivos.length}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // diálogo
              Navigator.pop(context); // vuelve al listado de chequeo
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chequeo · ${widget.workOrder.ot}'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Vehículo'),
              Tab(text: 'Cliente'),
              Tab(text: 'Dispositivo'),
              Tab(text: 'Ordenes'),
              Tab(text: 'Servicios'),
              Tab(text: 'Imagen'),
              Tab(text: 'Motivo'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _form,
          builder: (context, _) {
            return Column(
              children: [
                _panelSuperior(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _tabVehiculo(),
                      _tabCliente(),
                      _tabDispositivo(),
                      _tabOrdenes(),
                      _tabServicios(),
                      _tabImagen(),
                      _tabMotivo(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _finalizar,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar chequeo'),
            ),
          ),
        ),
      ),
    );
  }

  // --- Panel superior: Datos Generales + Motivos con % de avance ---
  Widget _panelSuperior() {
    final order = _form.order;
    return Container(
      color: AppColors.sectionBg,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Datos generales',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate,
                              fontSize: 12.5)),
                    ),
                    IconButton(
                      tooltip: 'Agregar fotos',
                      visualDensity: VisualDensity.compact,
                      onPressed: _agregarFotos,
                      icon: const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.steel, size: 20),
                    ),
                  ],
                ),
                _mini('Orden Servicio', order.os),
                _mini('Contacto', order.client.name),
                _mini('Producto', widget.workOrder.productos),
                _mini('Comentario', widget.workOrder.comentario),
                _mini('Concesionario', widget.workOrder.concesionario),
                _mini('Latitud', _form.latitud),
                _mini('Longitud', _form.longitud),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Motivos',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate,
                        fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(
                  _form.motivos.isEmpty ? 'Ninguna' : _form.motivos.join(', '),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _form.avance / 100,
                  minHeight: 14,
                  backgroundColor: AppColors.inactive,
                  color: AppColors.steel,
                ),
                const SizedBox(height: 2),
                Text('${_form.avance}%',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text('$k: $v',
            style: const TextStyle(fontSize: 11, color: Colors.black87)),
      );

  // --- Pestaña Vehículo ---
  Widget _tabVehiculo() {
    final v = _form.order.vehicle;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Vehículo'),
        ReadOnlyField(label: 'Id Vehículo', value: v.resumen),
        ReadOnlyField(label: 'Motor', value: v.motor),
        ReadOnlyField(label: 'Placa', value: v.placa),
        ReadOnlyField(label: 'Chasis', value: v.chasis),
        ReadOnlyField(label: 'Marca', value: v.marca),
        ReadOnlyField(label: 'Modelo', value: v.modelo),
        ReadOnlyField(label: 'Color', value: v.color),
        _toggle('Datos Correctos', _form.vehiculoDatosCorrectos,
            _form.setVehiculoCorrecto),
      ],
    );
  }

  // --- Pestaña Cliente ---
  Widget _tabCliente() {
    final c = _form.order.client;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Cliente'),
        ReadOnlyField(label: 'Cliente', value: c.ruc),
        ReadOnlyField(label: 'Nombre', value: c.name),
        ReadOnlyField(label: 'Dirección', value: c.direccion),
        ReadOnlyField(label: 'Teléfono', value: c.telefono),
        _toggle('Datos Correctos', _form.clienteDatosCorrectos,
            _form.setClienteCorrecto),
      ],
    );
  }

  // --- Pestaña Dispositivo ---
  Widget _tabDispositivo() {
    final d = _form.dispositivo;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Dispositivo'),
        ReadOnlyField(label: 'Dispositivo', value: d.dispositivo),
        _dropdown('Estado', _form.estadoDispositivo,
            AppCatalogs.estadosDispositivo, _form.setEstadoDispositivo),
        ReadOnlyField(label: 'Orden', value: widget.workOrder.ot),
        ReadOnlyField(label: 'Serie', value: d.serie),
        ReadOnlyField(label: 'Unidad', value: d.unidad),
        ReadOnlyField(label: 'Modelo', value: d.modelo),
        ReadOnlyField(label: 'Vid', value: d.vid),
        ReadOnlyField(label: 'Ip', value: d.ip),
        ReadOnlyField(label: 'Sim Card', value: d.simCard),
        ReadOnlyField(label: 'Ubicación', value: d.ubicacion),
        ReadOnlyField(label: 'Servidor', value: d.servidor),
        ReadOnlyField(label: 'Firmware', value: d.firmware),
        ReadOnlyField(label: 'Script', value: d.script),
        ReadOnlyField(label: 'APN', value: d.apn),
      ],
    );
  }

  // --- Pestaña Ordenes ---
  Widget _tabOrdenes() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Chequeo de Ordenes'),
        ReadOnlyField(label: 'Orden Trabajo', value: widget.workOrder.ot),
        ReadOnlyField(label: 'Producto', value: widget.workOrder.productos),
        ReadOnlyField(label: 'Tipo Trabajo', value: widget.workOrder.tipoTrabajo),
        ReadOnlyField(
            label: 'Concesionario', value: widget.workOrder.concesionario),
        ReadOnlyField(label: 'Comentario O/T', value: widget.workOrder.comentario),
        _toggle('Datos Correctos', _form.productoDatosCorrectos,
            _form.setProductoCorrecto),
        ReadOnlyField(label: 'Dispositivo', value: _form.dispositivo.serie),
        _dropdown('Estado', _form.estadoOrden, AppCatalogs.estadosOrden,
            _form.setEstadoOrden),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextFormField(
            initialValue: _form.comentarioOrden,
            maxLines: 2,
            maxLength: 200,
            onChanged: (v) => _form.comentarioOrden = v,
            decoration: const InputDecoration(labelText: 'Comentario'),
          ),
        ),
      ],
    );
  }

  // --- Pestaña Servicios (grid Sí/No) ---
  Widget _tabServicios() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Servicios'),
        for (final s in _form.servicios)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  RadioGroup<bool>(
                    groupValue: s.selected,
                    onChanged: (v) => _form.toggleServicio(s, v ?? false),
                    child: const Row(
                      children: [
                        Radio<bool>(value: true),
                        Text('Sí'),
                        Radio<bool>(value: false),
                        Text('No'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.name,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- Pestaña Imagen ---
  Widget _tabImagen() {
    return ListView(
      children: [
        PhotoCollectionField(
          items: _form.fotos,
          onChanged: _form.notify,
          title: 'Imagen',
          captionLabel: 'Comentario',
        ),
      ],
    );
  }

  // --- Pestaña Motivo (grid) ---
  Widget _tabMotivo() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionHeader('Motivo'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _motivoSel,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Motivo'),
                items: [
                  for (final m in AppCatalogs.catalogoMotivo)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (v) => setState(() => _motivoSel = v!),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _enviarMotivo,
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Enviar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_form.motivos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sin motivos registrados.',
                style: TextStyle(color: Colors.black38)),
          )
        else
          for (final m in _form.motivos)
            Card(
              child: ListTile(
                dense: true,
                title: Text(m, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.editable),
                  onPressed: () => _form.removeMotivo(m),
                ),
              ),
            ),
      ],
    );
  }

  // --- Helpers ---
  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Switch(value: value, onChanged: onChanged),
          Text(value ? 'SÍ' : 'NO',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: [
                for (final i in items)
                  DropdownMenuItem(value: i, child: Text(i)),
              ],
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ],
      ),
    );
  }
}
