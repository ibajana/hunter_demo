import 'package:flutter/material.dart';

import '../../models/reception_models.dart';
import '../../state/reception_form.dart';
import '../../theme/app_theme.dart';
import 'tabs/accessories_tab.dart';
import 'tabs/photos_tab.dart';
import 'tabs/vehicle_data_tab.dart';

/// Contenedor del detalle de recepción con las tres pestañas del PDF:
/// Datos Vehículos (B+C), Accesorios (D) y Fotos (E).
class ReceptionDetailScreen extends StatefulWidget {
  const ReceptionDetailScreen({super.key, required this.order});

  final ServiceOrder order;

  @override
  State<ReceptionDetailScreen> createState() => _ReceptionDetailScreenState();
}

class _ReceptionDetailScreenState extends State<ReceptionDetailScreen> {
  late final ReceptionForm _form = ReceptionForm(widget.order);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _finish() {
    if (!_form.cumpleMinimoFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.editable,
          content: Text(
            'Debes registrar al menos ${ReceptionForm.minFotos} fotos '
            '(faltan ${_form.fotosRestantes}).',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recepción registrada'),
        content: Text(
          'OS ${widget.order.os}\n'
          'Accesorios: ${_form.accesoriosSeleccionados} · '
          'Fotos: ${_form.fotos.length}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cierra diálogo
              Navigator.pop(context); // vuelve a la búsqueda
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recepción · ${widget.order.os}'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Datos Vehículos'),
              Tab(text: 'Accesorios'),
              Tab(text: 'Fotos'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: _form,
          builder: (context, _) {
            return TabBarView(
              children: [
                VehicleDataTab(form: _form),
                AccessoriesTab(form: _form),
                PhotosTab(form: _form),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _form,
                    builder: (context, _) => Text(
                      _form.cumpleMinimoFotos
                          ? '✓ ${_form.fotos.length} fotos · '
                              '${_form.accesoriosSeleccionados} accesorios'
                          : 'Faltan ${_form.fotosRestantes} fotos para '
                              'completar la recepción',
                      style: TextStyle(
                        color: _form.cumpleMinimoFotos
                            ? AppColors.accent
                            : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.check),
                  label: const Text('Finalizar recepción'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
