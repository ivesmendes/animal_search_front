import 'dart:async'; // Adicionar esta importação
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomMarkerWidget extends StatelessWidget {
  final String imageUrl;
  final String label;

  const CustomMarkerWidget({
    super.key, // Usar super parameter
    required this.imageUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nome da raça acima
          if (label.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Usar withValues
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label.length > 8 ? '${label.substring(0, 8)}...' : label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Imagem do animal
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2), // Usar withValues
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.pets,
                      color: Colors.grey,
                      size: 20,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Versão ainda mais compacta para áreas muito densas
class CompactMarkerWidget extends StatelessWidget {
  final String imageUrl;
  final String label;
  final Color accentColor;

  const CompactMarkerWidget({
    super.key, // Usar super parameter
    required this.imageUrl,
    required this.label,
    this.accentColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nome da raça acima (versão compacta)
          if (label.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // Usar withValues
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label.length > 6 ? '${label.substring(0, 6)}...' : label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 3),
          // Imagem do animal (versão compacta)
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3), // Usar withValues
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Icon(
                      Icons.pets,
                      color: accentColor,
                      size: 15,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Função melhorada para criar marcador com carregamento garantido
Future<Uint8List> createCustomMarker(
  String imageUrl, 
  String label, {
  bool useCompactVersion = false,
  Color accentColor = Colors.blue,
}) async {
  // Primeiro, vamos garantir que a imagem seja carregada
  final imageProvider = NetworkImage(imageUrl);
  final imageStream = imageProvider.resolve(ImageConfiguration.empty);
  final completer = Completer<ui.Image>();
  
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool synchronousCall) {
      completer.complete(info.image);
      imageStream.removeListener(listener);
    },
    onError: (dynamic exception, StackTrace? stackTrace) {
      completer.completeError(exception);
      imageStream.removeListener(listener);
    },
  );
  
  imageStream.addListener(listener);
  
  try {
    // Aguarda a imagem carregar com timeout
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        imageStream.removeListener(listener);
        throw TimeoutException('Timeout ao carregar imagem', const Duration(seconds: 10));
      },
    );
  } catch (e) {
    debugPrint('Erro ao carregar imagem: $e');
    // Continue mesmo se a imagem falhar - o errorBuilder vai lidar com isso
  }

  final repaintBoundary = GlobalKey();

  final markerWidget = RepaintBoundary(
    key: repaintBoundary,
    child: Material(
      color: Colors.transparent,
      child: useCompactVersion
          ? CompactMarkerWidget(
              imageUrl: imageUrl,
              label: label,
              accentColor: accentColor,
            )
          : CustomMarkerWidget(
              imageUrl: imageUrl,
              label: label,
            ),
    ),
  );

  // Tamanho ajustado para comportar o label acima
  final renderBoxSize = useCompactVersion 
      ? const Size(80, 70) 
      : const Size(100, 80);

  // Usar runApp temporariamente para renderizar o widget
  final app = MaterialApp(
    home: Scaffold(
      body: Positioned(
        left: -9999,
        top: -9999,
        width: renderBoxSize.width,
        height: renderBoxSize.height,
        child: markerWidget,
      ),
    ),
  );

  // Aguarda mais tempo para garantir que tudo seja renderizado
  await Future.delayed(const Duration(milliseconds: 1000));

  try {
    final boundary = repaintBoundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    }
  } catch (e) {
    debugPrint('Erro ao gerar marcador: $e');
  }

  throw Exception("Erro ao gerar marcador personalizado");
}

// Função helper para cores dinâmicas baseadas no tipo de animal
Color getAnimalColor(String animalType) {
  switch (animalType.toLowerCase()) {
    case 'cão':
    case 'cachorro':
      return Colors.brown;
    case 'gato':
      return Colors.orange;
    case 'pássaro':
    case 'ave':
      return Colors.blue;
    case 'coelho':
      return Colors.pink;
    default:
      return Colors.green;
  }
}

// Função alternativa mais robusta
Future<Uint8List> createCustomMarkerRobust(
  String imageUrl,
  String label, {
  bool useCompactVersion = false,
  Color accentColor = Colors.blue,
}) async {
  try {
    // Tenta o método principal primeiro
    return await createCustomMarker(
      imageUrl,
      label,
      useCompactVersion: useCompactVersion,
      accentColor: accentColor,
    );
  } catch (e) {
    debugPrint('Método principal falhou, tentando alternativo: $e');
    
    // Método alternativo: cria um marcador simples sem imagem
    return await _createFallbackMarker(label, accentColor);
  }
}

// Marcador de fallback caso a imagem não carregue
Future<Uint8List> _createFallbackMarker(
  String label,
  Color accentColor,
) async {
  final repaintBoundary = GlobalKey();

  final markerWidget = RepaintBoundary(
    key: repaintBoundary,
    child: Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Usar withValues
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                label.length > 8 ? '${label.substring(0, 8)}...' : label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(0.2), // Usar withValues
              border: Border.all(color: accentColor, width: 2),
            ),
            child: Icon(
              Icons.pets,
              color: accentColor,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );

  // Usar runApp temporariamente para renderizar o widget
  final app = MaterialApp(
    home: Scaffold(
      body: Positioned(
        left: -9999,
        top: -9999,
        width: 100,
        height: 80,
        child: markerWidget,
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 300));

  try {
    final boundary = repaintBoundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    }
  } catch (e) {
    debugPrint('Erro ao gerar marcador de fallback: $e');
  }

  throw Exception("Erro ao gerar marcador de fallback");
}
