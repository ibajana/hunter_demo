import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../repositories/app_repositories.dart';
import '../../../state/reception_form.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common.dart';

/// Pestaña "Datos Vehículos" = pantalla B (datos de la entrega) +
/// pantalla C (observaciones).
class VehicleDataTab extends StatelessWidget {
  const VehicleDataTab({super.key, required this.form});

  final ReceptionForm form;

  static final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate(BuildContext context) async {
    DateTime initial = DateTime.now();
    if (form.fechaEntrega.isNotEmpty) {
      try {
        initial = _dateFmt.parseStrict(form.fechaEntrega);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Fecha de entrega',
    );
    if (picked != null) {
      form.update(() => form.fechaEntrega = _dateFmt.format(picked));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initial = TimeOfDay.now();
    final parts = form.horaEntrega.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Hora de entrega',
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      form.update(() => form.horaEntrega = '$h:$m');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = form.order;
    final c = order.client;
    final v = order.vehicle;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ----- B: Datos de Cliente -----
        _Card(
          children: [
            const SectionHeader('Datos de Cliente'),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ReadOnlyField(label: 'Lugar y Fecha', value: order.lugarFecha),
                  ReadOnlyField(label: 'Cliente', value: c.name),
                  ReadOnlyField(label: 'Cédula/RUC', value: c.ruc),
                  EditableField(
                    label: 'Teléfono',
                    initialValue: form.telefono,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => form.update(() => form.telefono = val),
                  ),
                  EditableField(
                    label: 'Email',
                    initialValue: form.email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (val) => form.update(() => form.email = val),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ----- B: Datos de Vehículo -----
        _Card(
          children: [
            SectionHeader('Datos de Vehículo · C/V ${v.cv}'),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ReadOnlyField(
                    label: 'Placa/Color',
                    value: '${v.placa} / ${v.color}',
                  ),
                  ReadOnlyField(label: 'Serie Chasis', value: v.chasis),
                  ReadOnlyField(label: 'Nro. Motor', value: v.motor),
                  ReadOnlyField(
                    label: 'Marca/Modelo/Versión',
                    value: '${v.marca} / ${v.modelo}',
                  ),
                  ReadOnlyField(label: 'Comentario', value: v.comentario),
                  EditableField(
                    label: 'Recibe Cliente',
                    initialValue: form.recibeCliente,
                    onChanged: (val) =>
                        form.update(() => form.recibeCliente = val),
                  ),
                  EditableField(
                    label: 'Entrega Cliente',
                    initialValue: form.entregaCliente,
                    onChanged: (val) =>
                        form.update(() => form.entregaCliente = val),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ----- C: Observaciones -----
        _Card(
          children: [
            SectionHeader('Trabajos · O/S ${order.osNumber}'),
            Container(
              width: double.infinity,
              color: AppColors.sectionBg,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      order.producto,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    'Producto de la O/Venta',
                    style: TextStyle(
                      color: AppColors.editable,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 130,
                    child: Text('Novedad Comercial',
                        style:
                            TextStyle(color: Colors.black54, fontSize: 13)),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: form.novedadComercial,
                      isExpanded: true,
                      isDense: true,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textStrong),
                      items: [
                        for (final n in AppCatalogs.catalogoNovedadComercial)
                          DropdownMenuItem(value: n, child: Text(n)),
                      ],
                      onChanged: (v) =>
                          form.update(() => form.novedadComercial = v!),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader('Observaciones'),
            Padding(
              padding: const EdgeInsets.all(14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth > 560;
                  final left = [
                    EditableField(
                      label: 'Odómetro',
                      initialValue: form.odometro,
                      keyboardType: TextInputType.number,
                      labelWidth: 130,
                      onChanged: (v) => form.update(() => form.odometro = v),
                    ),
                    EditableField(
                      label: 'Cantidad Llave',
                      initialValue: form.cantidadLlave,
                      keyboardType: TextInputType.number,
                      labelWidth: 130,
                      onChanged: (v) =>
                          form.update(() => form.cantidadLlave = v),
                    ),
                    PickerField(
                      label: 'Fecha Entrega',
                      value: form.fechaEntrega,
                      hint: 'dd/mm/aaaa',
                      icon: Icons.calendar_today,
                      labelWidth: 130,
                      onTap: () => _pickDate(context),
                    ),
                  ];
                  final right = [
                    EditableField(
                      label: 'Combustible %',
                      initialValue: form.combustiblePct,
                      keyboardType: TextInputType.number,
                      labelWidth: 130,
                      onChanged: (v) =>
                          form.update(() => form.combustiblePct = v),
                    ),
                    EditableField(
                      label: 'Cantidad Controles',
                      initialValue: form.cantidadControles,
                      keyboardType: TextInputType.number,
                      labelWidth: 130,
                      onChanged: (v) =>
                          form.update(() => form.cantidadControles = v),
                    ),
                    PickerField(
                      label: 'Hora de Entrega',
                      value: form.horaEntrega,
                      hint: 'hh:mm',
                      icon: Icons.access_time,
                      labelWidth: 130,
                      onTap: () => _pickTime(context),
                    ),
                  ];

                  if (twoCols) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: left)),
                        const SizedBox(width: 20),
                        Expanded(child: Column(children: right)),
                      ],
                    );
                  }
                  return Column(children: [...left, ...right]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: TextFormField(
                initialValue: form.novedadesObservaciones,
                minLines: 2,
                maxLines: 4,
                maxLength: 200,
                onChanged: (v) =>
                    form.update(() => form.novedadesObservaciones = v),
                decoration: const InputDecoration(
                  labelText: 'Novedades',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Los campos son editables, no obligatorios; se incluirán en el '
            'correo de notificación al cliente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
