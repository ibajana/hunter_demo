import 'package:flutter/material.dart';

/// Utilidades de diseño adaptativo para que la app funcione bien en teléfonos
/// (portrait/landscape) y tablets, mostrando mucha información sin desperdiciar
/// altura.
class Breakpoints {
  Breakpoints._();

  /// Ancho por debajo del cual se considera pantalla "compacta" (una columna).
  static const double compact = 600;

  /// A partir de este ancho se muestran dos columnas de resultados.
  static const double wide = 720;

  /// Ancho objetivo máximo de cada tarjeta en el grid de resultados.
  static const double cardMaxExtent = 480;

  /// Alto por debajo del cual conviene colapsar los filtros (p. ej. teléfono
  /// en horizontal).
  static const double shortHeight = 500;
}

extension ResponsiveContext on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);

  bool get isLandscape => MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Alto reducido: teléfono en horizontal o ventana baja.
  bool get isShortHeight => _size.height < Breakpoints.shortHeight;

  /// Conviene colapsar filtros por defecto.
  bool get shouldCollapseFilters => isLandscape || isShortHeight;

  bool get isWide => _size.width >= Breakpoints.wide;
}

/// Distribuye [children] en N columnas según el ancho disponible: una columna en
/// pantallas angostas, dos o más en pantallas anchas. Cada celda se ajusta al
/// ancho de columna. Pensado para listas de tarjetas de resultados.
class AutoGrid extends StatelessWidget {
  const AutoGrid({
    super.key,
    required this.children,
    this.maxColumnExtent = Breakpoints.cardMaxExtent,
    this.spacing = 8,
    this.runSpacing = 8,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 12),
  });

  final List<Widget> children;
  final double maxColumnExtent;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          // Número de columnas objetivo según el ancho.
          final cols = (maxW / maxColumnExtent).floor().clamp(1, 4);
          if (cols <= 1) {
            // Una columna: apilar con separación.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: runSpacing),
                  children[i],
                ],
              ],
            );
          }
          final itemW = (maxW - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: [
              for (final child in children)
                SizedBox(width: itemW, child: child),
            ],
          );
        },
      ),
    );
  }
}
