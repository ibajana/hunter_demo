import 'dart:convert';
import 'dart:typed_data';

/// Imagen capturada/seleccionada con un comentario (caption) opcional.
/// Modelo único compartido por Recepción, Chequeo y Control de Calidad.
class PhotoItem {
  PhotoItem({required this.bytes, this.caption = ''});

  final Uint8List bytes;
  String caption;

  /// Base64 de la imagen (para un eventual envío al backend).
  String get base64 => base64Encode(bytes);
}
