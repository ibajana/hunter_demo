import 'package:flutter/material.dart';

import '../../repositories/app_repositories.dart';
import '../../models/workshop_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'chequeo_form_screen.dart';

/// Paso intermedio tras aceptar trabajar la O/Trabajo: valida la recepción
/// realizada previamente marcándola Con Novedad / Sin Novedad y registrando un
/// comentario. "Grabar" levanta el formulario de chequeo.
class ChequeoRecepcionScreen extends StatefulWidget {
  const ChequeoRecepcionScreen({super.key, required this.workOrder});

  final WorkOrder workOrder;

  @override
  State<ChequeoRecepcionScreen> createState() => _ChequeoRecepcionScreenState();
}

class _ChequeoRecepcionScreenState extends State<ChequeoRecepcionScreen> {
  bool? _conNovedad; // null = sin elegir
  final _recepcionCtrl = TextEditingController();

  @override
  void dispose() {
    _recepcionCtrl.dispose();
    super.dispose();
  }

  void _limpiar() {
    setState(() {
      _conNovedad = null;
      _recepcionCtrl.clear();
    });
  }

  void _grabar() {
    if (_conNovedad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.editable,
          content: Text('Selecciona Con Novedad o Sin Novedad.'),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChequeoFormScreen(
          workOrder: widget.workOrder,
          conNovedad: _conNovedad!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = AppCatalogs.orderFor(widget.workOrder.os);
    return Scaffold(
      appBar: AppBar(
        title: Text('Recepción de Taller · ${widget.workOrder.ot}'),
      ),
      body: ListView(
        children: [
          const SectionHeader('Recepción de Taller (PDF)'),
          Container(
            height: 180,
            color: Colors.black87,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo_hunter.png',
                    width: 120, fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white54,
                        size: 64)),
                const SizedBox(height: 8),
                Text('PDF de recepción — ${order.os}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RadioGroup<bool>(
                  groupValue: _conNovedad,
                  onChanged: (v) => setState(() => _conNovedad = v),
                  child: const Row(
                    children: [
                      Radio<bool>(value: true),
                      Text('Con Novedades'),
                      SizedBox(width: 16),
                      Radio<bool>(value: false),
                      Text('Sin Novedades'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _recepcionCtrl,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Recepción',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _limpiar,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _grabar,
                icon: const Icon(Icons.save),
                label: const Text('Grabar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
