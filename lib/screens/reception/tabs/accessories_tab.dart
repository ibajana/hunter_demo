import 'package:flutter/material.dart';

import '../../../state/reception_form.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common.dart';

/// Pestaña "Accesorios" = pantalla D. Registra los accesorios con los que
/// cuenta el vehículo, con seleccionar/deseleccionar todo y novedades.
class AccessoriesTab extends StatelessWidget {
  const AccessoriesTab({super.key, required this.form});

  final ReceptionForm form;

  @override
  Widget build(BuildContext context) {
    final allSelected = form.accesorios.every((a) => a.selected);
    final noneSelected = form.accesorios.every((a) => !a.selected);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                'Accesorios',
                trailing: Text(
                  '${form.accesoriosSeleccionados}/${form.accesorios.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextFormField(
                  initialValue: form.novedadesAccesorios,
                  maxLength: 200,
                  onChanged: (v) =>
                      form.update(() => form.novedadesAccesorios = v),
                  decoration: const InputDecoration(labelText: 'Novedades'),
                ),
              ),
              // Seleccionar / deseleccionar todo (Wrap evita el desborde
              // horizontal cuando no hay espacio suficiente).
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RadioOption(
                      label: 'Seleccionar Todo',
                      selected: allSelected,
                      onTap: () => form.setAllAccessories(true),
                    ),
                    _RadioOption(
                      label: 'Deseleccionar Todo',
                      selected: noneSelected,
                      onTap: () => form.setAllAccessories(false),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Lista de accesorios
              for (final a in form.accesorios)
                CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.steel,
                  value: a.selected,
                  onChanged: (val) => form.toggleAccessory(a, val ?? false),
                  title: Text(a.name),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.steel : Colors.black45,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
