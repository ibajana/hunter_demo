import 'package:flutter/material.dart';

import '../../models/reception_models.dart';
import '../../repositories/app_repositories.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/filter_panel.dart';
import '../../widgets/responsive.dart';
import 'reception_detail_screen.dart';

/// Sección Recepción de Vehículos (index 0 del shell).
/// Permite buscar por Placa/Serie, Identificación de cliente u OS y muestra
/// la información del vehículo y cliente que coincida. El [AppBar] y la barra
/// de etapas los provee el [MainShell]; aquí solo va el cuerpo.
class ReceptionSection extends StatefulWidget {
  const ReceptionSection({super.key});

  @override
  State<ReceptionSection> createState() => _ReceptionSectionState();
}

class _ReceptionSectionState extends State<ReceptionSection> {
  final _placaCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _osCtrl = TextEditingController();

  // Por defecto se muestran todos los registros; la búsqueda filtra.
  List<ServiceOrder> _results = const [];
  bool _filtered = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarTodos();
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _idCtrl.dispose();
    _osCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTodos() async {
    setState(() => _loading = true);
    final r = await Repositories.taller.fetchAllOrders();
    if (!mounted) return;
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final hasCriteria = _placaCtrl.text.trim().isNotEmpty ||
        _idCtrl.text.trim().isNotEmpty ||
        _osCtrl.text.trim().isNotEmpty;
    if (!hasCriteria) {
      _filtered = false;
      await _cargarTodos();
      return;
    }
    setState(() => _loading = true);
    final r = await Repositories.taller.searchOrders(
      placa: _placaCtrl.text,
      identificacion: _idCtrl.text,
      os: _osCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _filtered = true;
      _results = r;
      _loading = false;
    });
  }

  void _clear() {
    FocusScope.of(context).unfocus();
    _placaCtrl.clear();
    _idCtrl.clear();
    _osCtrl.clear();
    _filtered = false;
    _cargarTodos();
  }

  void _open(ServiceOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceptionDetailScreen(order: order)),
    );
  }

  List<String> _chips() => [
        if (_placaCtrl.text.trim().isNotEmpty) 'Placa: ${_placaCtrl.text.trim()}',
        if (_idCtrl.text.trim().isNotEmpty) 'ID: ${_idCtrl.text.trim()}',
        if (_osCtrl.text.trim().isNotEmpty) 'OS: ${_osCtrl.text.trim()}',
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterPanel(
          onSearch: _search,
          onClear: _clear,
          activeChips: _chips(),
          fields: [
            FilterField(
                label: 'Placa/Serie',
                controller: _placaCtrl,
                hint: 'Placa',
                maxLength: 10),
            FilterField(
                label: 'Identificación',
                controller: _idCtrl,
                hint: 'Identificación',
                numeric: true,
                maxLength: 13),
            FilterField(
                label: 'OS',
                controller: _osCtrl,
                hint: 'OS',
                numeric: true,
                maxLength: 12,
                onSubmit: _search),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: _buildResults(),
                ),
        ),
      ],
    );
  }

  List<Widget> _buildResults() {
    if (_results.isEmpty) {
      return const [
        _Hint(
          icon: Icons.search_off,
          text: 'No se encontraron coincidencias con el criterio de búsqueda.',
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          _filtered
              ? '${_results.length} resultado(s) de la búsqueda'
              : 'Mostrando todos los registros (${_results.length})',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      AutoGrid(
        children: [
          for (final order in _results)
            _OrderCard(order: order, onTap: () => _open(order)),
        ],
      ),
    ];
  }
}

/// Tarjeta de resultado: datos del cliente + resumen del vehículo.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = order.client;
    final v = order.vehicle;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Datos de cliente
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('Cliente', c.name),
                  _line('Dirección', c.direccion),
                  _line('Teléfono', c.telefono),
                  _line('Email', c.email),
                ],
              ),
            ),
            const Divider(height: 1),
            // Datos del vehículo
            Container(
              color: AppColors.sectionBg,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Icon(Icons.directions_car,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.os,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.steel,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'C/V ${v.cv}',
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          v.resumen,
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.comentario,
                          style: const TextStyle(
                            color: AppColors.label,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.label,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
