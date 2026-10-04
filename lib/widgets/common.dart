import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Píldora de estado suave (mockup): fondo tenue, texto de color y borde.
/// Usa una variante semántica ([kind]) o un color de acento ([StatusPill.tint]).
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.kind = PillKind.neutral})
      : _tint = null;

  /// Píldora suave derivada de un color arbitrario (p. ej. fase de Salida).
  const StatusPill.tint(this.label, {super.key, required Color color})
      : _tint = color,
        kind = PillKind.neutral;

  final String label;
  final PillKind kind;
  final Color? _tint;

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, border;
    if (_tint != null) {
      bg = _tint.withValues(alpha: 0.12);
      fg = _tint;
      border = _tint.withValues(alpha: 0.35);
    } else {
      final s = AppColors.semantic(kind);
      bg = s.bg;
      fg = s.fg;
      border = s.border;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Barra de sub-pestañas (Chequeos/Novedad, Técnico/Supervisor/Entrega).
/// Estilo mockup: fondo blanco, activa con borde inferior + texto en primary.
class SubTabBar extends StatelessWidget {
  const SubTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == activeIndex
                            ? AppColors.primary
                            : AppColors.border,
                        width: i == activeIndex ? 2.5 : 1,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == activeIndex
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontWeight:
                          i == activeIndex ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cabecera de sección (mockup): título en negrita con ícono opcional, sin
/// fondo oscuro. Encabeza bloques de datos dentro de las tarjetas/listas.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.icon});

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Fila etiqueta + valor de solo lectura (datos precargados no editables).
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: highlight ? AppColors.editable : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo editable etiquetado. Usa el borde por defecto del tema (igual que
/// los inputs del login).
class EditableField extends StatelessWidget {
  const EditableField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType,
    this.hint,
    this.labelWidth = 140,
    this.maxLength = 50,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? hint;
  final double labelWidth;

  /// Longitud máxima; por defecto 50 (campos tipo dato).
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              keyboardType: keyboardType,
              onChanged: onChanged,
              maxLength: maxLength,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector al tocarlo (fecha, hora…).
/// Garantiza que el valor solo provenga del selector, sin texto libre.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.icon,
    this.labelWidth = 140,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? hint;
  final IconData? icon;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: InputDecorator(
                decoration: InputDecoration(
                  suffixIcon: Icon(icon, size: 20, color: Colors.black54),
                ),
                child: Text(
                  hasValue ? value : (hint ?? ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue ? Colors.black87 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de filtro compacto: etiqueta en azul arriba y un input debajo.
/// Usado en las barras de búsqueda de todas las secciones.
class FilterField extends StatelessWidget {
  const FilterField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.onSubmit,
    this.keyboardType,
    this.numeric = false,
    this.maxLength = 50,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final VoidCallback? onSubmit;
  final TextInputType? keyboardType;

  /// Si es true, solo permite dígitos (p. ej. Orden Servicio).
  final bool numeric;

  /// Longitud máxima; por defecto 50.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType:
              numeric ? TextInputType.number : keyboardType,
          inputFormatters:
              numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          maxLength: maxLength,
          textInputAction:
              onSubmit != null ? TextInputAction.search : TextInputAction.next,
          onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
          decoration: InputDecoration(
            hintText: hint ?? label,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Campo de filtro de **fecha**: abre un date picker y muestra `dd/MM/yyyy`.
/// Mismo estilo (etiqueta arriba) que [FilterField]; nunca acepta texto libre.
/// Formato estándar de fecha de los filtros.
final DateFormat kFilterDateFmt = DateFormat('dd/MM/yyyy');

/// Convierte el texto de un filtro de fecha a [DateTime] (o null si no es válido).
DateTime? parseFilterDate(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  try {
    return kFilterDateFmt.parseStrict(t);
  } catch (_) {
    return null;
  }
}

class FilterDateField extends StatelessWidget {
  const FilterDateField({
    super.key,
    required this.label,
    required this.controller,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Se llama cuando el usuario elige una fecha nueva (para re-consultar).
  final ValueChanged<DateTime>? onChanged;

  /// Si es false, el campo se muestra en gris y no abre el selector
  /// (p. ej. la fecha final cuando el filtro es de un solo día).
  final bool enabled;

  static final DateFormat _fmt = kFilterDateFmt;

  Future<void> _pick(BuildContext context) async {
    final fd = firstDate ?? DateTime(2020);
    final ld = lastDate ?? DateTime(2035);
    DateTime initial = DateTime.now();
    final txt = controller.text.trim();
    if (txt.isNotEmpty) {
      try {
        initial = _fmt.parseStrict(txt);
      } catch (_) {}
    }
    // Mantener la fecha inicial dentro del rango permitido (evita el error del
    // date picker cuando firstDate/lastDate restringen el rango).
    if (initial.isBefore(fd)) initial = fd;
    if (initial.isAfter(ld)) initial = ld;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: fd,
      lastDate: ld,
      helpText: label,
    );
    if (picked != null) {
      controller.text = _fmt.format(picked);
      onChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterLabel(label),
        const SizedBox(height: 4),
        InkWell(
          onTap: enabled ? () => _pick(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF1F3F5),
              suffixIcon: Icon(
                enabled ? Icons.calendar_today : Icons.lock_outline,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            // Se reconstruye cuando cambia el controller para reflejar siempre
            // la fecha seleccionada, incluso si el resto de la pantalla no
            // llama a setState.
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final hasValue = controller.text.trim().isNotEmpty;
                return Text(
                  hasValue ? controller.text : 'dd/mm/aaaa',
                  style: TextStyle(
                    fontSize: 14,
                    color: !enabled
                        ? AppColors.textMuted
                        : (hasValue
                            ? AppColors.textStrong
                            : AppColors.iconMuted),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Etiqueta azul reutilizada por los campos de filtro.
class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.label,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

/// Dropdown de filtro con etiqueta azul arriba, mismo estilo que [FilterField].
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.label,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: const InputDecoration(filled: true, fillColor: Colors.white),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Botón redondo de lupa para ejecutar una consulta (como en el PDF).
class SearchIconButton extends StatelessWidget {
  const SearchIconButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.steel,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.search, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
