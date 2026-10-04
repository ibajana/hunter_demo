/// Cliente asociado a la orden de servicio.
class Client {
  final String name;
  final String ruc;
  final String direccion;
  final String telefono;
  final String email;

  const Client({
    required this.name,
    required this.ruc,
    required this.direccion,
    required this.telefono,
    required this.email,
  });
}

/// Datos del vehículo. [resumen] concatena la info como en el PDF.
class Vehicle {
  final String placa;
  final String motor;
  final String chasis;
  final String marca;
  final String tipo;
  final String modelo;
  final String color;
  final String comentario;
  final String cv; // C/V

  const Vehicle({
    required this.placa,
    required this.motor,
    required this.chasis,
    required this.marca,
    required this.tipo,
    required this.modelo,
    required this.color,
    required this.comentario,
    required this.cv,
  });

  String get resumen =>
      'PLC.:$placa MOT.:$motor CHA.:$chasis MAR.:$marca '
      'TIP:$tipo MOD.:$modelo COL.:$color';

  String get marcaModelo => '$marca / $modelo';
}

/// Orden de servicio: une cliente, vehículo y producto de la O/Venta.
class ServiceOrder {
  final String os; // OS1025175792
  final String producto; // CAD - ALQU HM CORPORATIVO EQUIPO ALQUILER
  final String lugarFecha; // Guayaquil, 3 MARZO 2026
  final DateTime fecha; // fecha de la O/Servicio (para filtros por rango)
  final Client client;
  final Vehicle vehicle;

  const ServiceOrder({
    required this.os,
    required this.producto,
    required this.lugarFecha,
    required this.fecha,
    required this.client,
    required this.vehicle,
  });

  /// Número sin el prefijo "OS" para la búsqueda.
  String get osNumber => os.replaceAll(RegExp(r'[^0-9]'), '');

  /// True si la fecha de la O/Servicio está dentro del rango (inclusive).
  bool enRango(DateTime? desde, DateTime? hasta) {
    final d = DateTime(fecha.year, fecha.month, fecha.day);
    if (desde != null && d.isBefore(desde)) return false;
    if (hasta != null && d.isAfter(hasta)) return false;
    return true;
  }
}

/// Accesorio con el que cuenta el vehículo (pantalla D).
class Accessory {
  final String name;
  bool selected;

  Accessory(this.name, {this.selected = false});
}
