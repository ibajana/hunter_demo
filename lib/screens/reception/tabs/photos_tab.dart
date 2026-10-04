import 'package:flutter/material.dart';

import '../../../state/reception_form.dart';
import '../../../widgets/photo_collection.dart';

/// Pestaña "Fotos" = pantalla E. Captura/gestiona fotos del vehículo (mínimo 3)
/// con el componente moderno de colección de fotos: agregar desde cámara o
/// galería (multi-selección), verlas juntas y abrir un visor a pantalla
/// completa con comentario por foto.
class PhotosTab extends StatelessWidget {
  const PhotosTab({super.key, required this.form});

  final ReceptionForm form;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PhotoCollectionField(
          items: form.fotos,
          onChanged: form.notify,
          title: 'Fotos del vehículo',
          minPhotos: ReceptionForm.minFotos,
          captionLabel: 'Novedades',
        ),
      ],
    );
  }
}
