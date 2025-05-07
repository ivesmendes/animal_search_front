import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomMarkerWidget extends StatelessWidget {
  final String imageUrl;
  final String label;

  const CustomMarkerWidget({
    Key? key,
    required this.imageUrl,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent, width: 2),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Uint8List> createCustomMarker(BuildContext context, String imageUrl, String label) async {
  final repaintBoundary = GlobalKey();

  final markerWidget = RepaintBoundary(
    key: repaintBoundary,
    child: Material(
      color: Colors.transparent,
      child: CustomMarkerWidget(
        imageUrl: imageUrl,
        label: label,
      ),
    ),
  );

  final logicalSize = MediaQuery.of(context).size;
  final renderBoxSize = const Size(150, 150);

  final overlay = OverlayEntry(
    builder: (context) => Positioned(
      left: -9999,
      top: -9999,
      width: renderBoxSize.width,
      height: renderBoxSize.height,
      child: markerWidget,
    ),
  );

  Overlay.of(context).insert(overlay);
  await Future.delayed(const Duration(milliseconds: 50)); // espera renderizar

  try {
    final boundary = repaintBoundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }
  } finally {
    overlay.remove();
  }

  throw Exception("Erro ao gerar marcador");
}
