import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo_item.dart';
import '../theme/app_theme.dart';

final ImagePicker _picker = ImagePicker();

/// Abre un bottom sheet para elegir Cámara o Galería y devuelve las fotos
/// seleccionadas (la galería permite multi-selección).
Future<List<PhotoItem>> pickPhotos(
  BuildContext context, {
  bool allowMultiple = true,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Agregar fotos',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: AppColors.steel),
            title: const Text('Cámara'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.steel),
            title: Text(allowMultiple ? 'Galería (varias)' : 'Galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return const [];

  try {
    if (source == ImageSource.camera) {
      final file = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 70, maxWidth: 1600);
      if (file == null) return const [];
      return [PhotoItem(bytes: await file.readAsBytes())];
    } else {
      if (allowMultiple) {
        final files =
            await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1600);
        return [
          for (final f in files) PhotoItem(bytes: await f.readAsBytes()),
        ];
      } else {
        final file = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 70, maxWidth: 1600);
        if (file == null) return const [];
        return [PhotoItem(bytes: await file.readAsBytes())];
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron obtener las fotos: $e')),
      );
    }
    return const [];
  }
}

/// Colección de fotos moderna (estilo WhatsApp/Meta): grilla de miniaturas con
/// una celda "Agregar" que captura de cámara o selecciona varias de galería;
/// las fotos aparecen al instante y se ven/editan en un visor a pantalla
/// completa. Muta [items] en sitio y llama a [onChanged].
class PhotoCollectionField extends StatefulWidget {
  const PhotoCollectionField({
    super.key,
    required this.items,
    required this.onChanged,
    this.title = 'Fotos',
    this.minPhotos,
    this.maxPhotos,
    this.captions = true,
    this.captionLabel = 'Comentario',
    this.readOnly = false,
  });

  final List<PhotoItem> items;
  final VoidCallback onChanged;
  final String title;
  final int? minPhotos;
  final int? maxPhotos;
  final bool captions;
  final String captionLabel;
  final bool readOnly;

  @override
  State<PhotoCollectionField> createState() => _PhotoCollectionFieldState();
}

class _PhotoCollectionFieldState extends State<PhotoCollectionField> {
  bool get _cumpleMin =>
      widget.minPhotos == null || widget.items.length >= widget.minPhotos!;

  bool get _hayEspacio =>
      widget.maxPhotos == null || widget.items.length < widget.maxPhotos!;

  Future<void> _add() async {
    final picked = await pickPhotos(context, allowMultiple: true);
    if (picked.isEmpty) return;
    final room = widget.maxPhotos == null
        ? picked.length
        : widget.maxPhotos! - widget.items.length;
    if (room <= 0) return;
    widget.items.addAll(picked.take(room));
    widget.onChanged();
    setState(() {});
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          items: widget.items,
          initialIndex: index,
          captions: widget.captions,
          captionLabel: widget.captionLabel,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _remove(int index) {
    widget.items.removeAt(index);
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              Text('${widget.title} ($count)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                      fontSize: 13)),
              const SizedBox(width: 8),
              if (widget.minPhotos != null)
                _cumpleMin
                    ? const Icon(Icons.check_circle,
                        color: AppColors.accent, size: 18)
                    : Text('mínimo ${widget.minPhotos}',
                        style: const TextStyle(
                            color: AppColors.editable, fontSize: 11.5)),
              const Spacer(),
              if (widget.maxPhotos != null)
                Text('$count/${widget.maxPhotos}',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 11.5)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!widget.readOnly && _hayEspacio) _addTile(),
              for (var i = 0; i < widget.items.length; i++) _thumb(i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addTile() {
    return InkWell(
      onTap: _add,
      borderRadius: BorderRadius.circular(12),
      child: DottedTile(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, color: AppColors.steel, size: 26),
            SizedBox(height: 4),
            Text('Agregar',
                style: TextStyle(color: AppColors.steel, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _thumb(int index) {
    final item = widget.items[index];
    return Stack(
      children: [
        InkWell(
          onTap: () => _openViewer(index),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(item.bytes,
                width: 92, height: 92, fit: BoxFit.cover),
          ),
        ),
        if (item.caption.trim().isNotEmpty)
          const Positioned(
            left: 4,
            bottom: 4,
            child: Icon(Icons.chat_bubble, size: 13, color: Colors.white),
          ),
        if (!widget.readOnly)
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => _remove(index),
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.editable,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Celda punteada de "Agregar".
class DottedTile extends StatelessWidget {
  const DottedTile({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.sectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.steel.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

/// Visor a pantalla completa: swipe entre fotos, caption editable, eliminar y
/// agregar más. En [readOnly] solo permite ver y hacer swipe.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onChanged,
    this.captions = true,
    this.captionLabel = 'Comentario',
    this.readOnly = false,
  });

  final List<PhotoItem> items;
  final int initialIndex;
  final VoidCallback onChanged;
  final bool captions;
  final String captionLabel;
  final bool readOnly;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  final _captionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncCaption();
  }

  @override
  void dispose() {
    _page.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  void _syncCaption() {
    if (_index >= 0 && _index < widget.items.length) {
      _captionCtrl.text = widget.items[_index].caption;
    }
  }

  Future<void> _addMore() async {
    final picked = await pickPhotos(context, allowMultiple: true);
    if (picked.isEmpty) return;
    widget.items.addAll(picked);
    widget.onChanged();
    setState(() {
      _index = widget.items.length - picked.length;
      _syncCaption();
    });
    _page.jumpToPage(_index);
  }

  void _delete() {
    if (widget.items.isEmpty) return;
    widget.items.removeAt(_index);
    widget.onChanged();
    if (widget.items.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index = _index.clamp(0, widget.items.length - 1);
      _syncCaption();
    });
    _page.jumpToPage(_index);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / $total'),
        actions: [
          if (!widget.readOnly) ...[
            IconButton(
              tooltip: 'Agregar más',
              onPressed: _addMore,
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: total,
              onPageChanged: (i) => setState(() {
                _index = i;
                _syncCaption();
              }),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.memory(widget.items[i].bytes,
                      fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          if (widget.captions) _captionBar(),
        ],
      ),
    );
  }

  Widget _captionBar() {
    if (widget.readOnly) {
      final cap = widget.items[_index].caption.trim();
      if (cap.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Text(cap, style: const TextStyle(color: Colors.white)),
      );
    }
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SafeArea(
        top: false,
        child: TextField(
          controller: _captionCtrl,
          style: const TextStyle(color: Colors.white),
          minLines: 1,
          maxLines: 3,
          maxLength: 200,
          onChanged: (v) {
            widget.items[_index].caption = v;
            widget.onChanged();
          },
          decoration: InputDecoration(
            hintText: '${widget.captionLabel}…',
            hintStyle: const TextStyle(color: Colors.white54),
            counterStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white12,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.steel),
            ),
          ),
        ),
      ),
    );
  }
}
