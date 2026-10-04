import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Panel de filtros colapsable y adaptativo.
///
/// - En **portrait** con altura suficiente arranca **expandido** (como antes).
/// - En **landscape** o pantallas de poca altura arranca **colapsado** en una
///   barra compacta, para que la lista de resultados sea la protagonista.
/// - Colapsado muestra un resumen de los filtros activos en *chips* + la lupa +
///   un chevron para expandir. Siempre se puede alternar manualmente.
/// - Los [fields] se distribuyen en 1–3 columnas según el ancho disponible.
class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.fields,
    required this.onSearch,
    this.onClear,
    this.activeChips = const [],
    this.extra,
    this.minFieldWidth = 220,
  });

  /// Inputs de filtro ya construidos (FilterField/FilterDropdown/PickerField…).
  final List<Widget> fields;
  final VoidCallback onSearch;
  final VoidCallback? onClear;

  /// Resumen de filtros aplicados que se ve cuando está colapsado.
  final List<String> activeChips;

  /// Fila extra opcional (checkbox, acción de selección, leyenda…).
  final Widget? extra;

  final double minFieldWidth;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  // Por defecto los filtros arrancan CONTRAÍDOS; el usuario los expande.
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  void _search() {
    widget.onSearch();
    // Tras buscar desde el estado expandido, colapsar para dejar ver los
    // resultados.
    if (_expanded) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _expanded;
    return Material(
      color: AppColors.sectionBg,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        curve: Curves.easeOut,
        child: expanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  // --- Barra compacta (colapsado) ---
  Widget _buildCollapsed() {
    final chips = widget.activeChips;
    return InkWell(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 20, color: AppColors.slate),
            const SizedBox(width: 8),
            Expanded(
              child: chips.isEmpty
                  ? const Text(
                      'Filtros',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in chips)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _Chip(c),
                            ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            _toggleButton(),
          ],
        ),
      ),
    );
  }

  /// Único control de expandir/colapsar: mismo botón y posición en ambos
  /// estados, solo cambia la dirección del chevron.
  Widget _toggleButton() {
    final expanded = _expanded;
    return IconButton(
      tooltip: expanded ? 'Ocultar filtros' : 'Mostrar filtros',
      visualDensity: VisualDensity.compact,
      icon: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: AppColors.slate,
      ),
      onPressed: _toggle,
    );
  }

  // --- Panel completo (expandido) ---
  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.slate),
              const SizedBox(width: 6),
              const Text(
                'Filtros',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _toggleButton(),
            ],
          ),
          const SizedBox(height: 4),
          _ResponsiveFields(
            minFieldWidth: widget.minFieldWidth,
            fields: widget.fields,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (widget.onClear != null) ...[
                OutlinedButton.icon(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ),
            ],
          ),
          if (widget.extra != null) ...[
            const SizedBox(height: 4),
            widget.extra!,
          ],
        ],
      ),
    );
  }
}

/// Distribuye los campos de filtro en columnas según el ancho disponible.
class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.fields, required this.minFieldWidth});

  final List<Widget> fields;
  final double minFieldWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cols = (maxW / minFieldWidth).floor().clamp(1, fields.length);
        if (cols <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                fields[i],
              ],
            ],
          );
        }
        const spacing = 10.0;
        final itemW = (maxW - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: 8,
          children: [
            for (final f in fields) SizedBox(width: itemW, child: f),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.primary,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
