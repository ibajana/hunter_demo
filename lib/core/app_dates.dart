/// Utilidades de fecha del cliente (no provienen del backend): el día actual
/// y el formato dd/MM/yyyy usado por los filtros. Los filtros son de un solo
/// día y cargan hoy por defecto.
class AppDates {
  AppDates._();

  /// Día actual sin hora.
  static final DateTime hoy = () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }();

  static String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime get defaultDesde => hoy;
  static DateTime get defaultHasta => hoy;
  static String get defaultDesdeStr => fmt(hoy);
  static String get defaultHastaStr => fmt(hoy);
}
