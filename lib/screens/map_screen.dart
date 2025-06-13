import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'add_animal_page.dart';
import 'login_screen.dart';
import 'custom_marker_widget.dart' as marker_utils;
import 'animal_details_view.dart';
import 'chat_screen.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

/// Cria um BitmapDescriptor com foto do animal, indicador de localização preciso e rótulo
Future<BitmapDescriptor> _styledMarkerFromUrl(
  String imageUrl, {
  String label = '',
  int size = 60,
  Color borderColor = Colors.blue,
  double borderWidth = 3,
}) async {
  try {
    // 1) Baixa e decodifica a imagem remota
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) throw Exception('Erro ao baixar imagem (${response.statusCode})');
    
    final codec = await ui.instantiateImageCodec(
      response.bodyBytes,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final img = frame.image;

    // 2) Dimensões do marcador
    final recorder = ui.PictureRecorder();
    final labelHeight = label.isNotEmpty ? 18.0 : 0.0;
    final labelSpace = label.isNotEmpty ? 4.0 : 0.0;
    final pinHeight = 12.0; // Altura do indicador de localização
    final totalHeight = labelHeight + labelSpace + size + pinHeight + 8.0; // Margem extra
    final totalWidth = size.toDouble();
    
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth, totalHeight));
    final paint = Paint()..isAntiAlias = true;

    // 3) Desenha o rótulo acima (se existir)
    if (label.isNotEmpty) {
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ))
        ..pushStyle(ui.TextStyle(color: ui.Color(0xFF333333)))
        ..addText(label.length > 12 ? '${label.substring(0, 12)}…' : label);
      
      final paragraph = pb.build()..layout(ui.ParagraphConstraints(width: totalWidth));
      
      // Fundo do rótulo
      paint.color = ui.Color(0xFFFFFFFF);
      paint.style = PaintingStyle.fill;
      final labelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 0, totalWidth - 4, labelHeight),
        Radius.circular(8),
      );
      canvas.drawRRect(labelRect, paint);
      
      // Borda do rótulo
      paint.color = borderColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.5;
      canvas.drawRRect(labelRect, paint);
      
      // Texto do rótulo
      canvas.drawParagraph(paragraph, Offset((totalWidth - paragraph.width) / 2, 1));
    }

    // 4) Posição da foto
    final photoY = labelHeight + labelSpace;
    final photoCenter = Offset(totalWidth / 2, photoY + size / 2);

    // 5) Sombra da foto
    paint
      ..color = ui.Color(0x40000000)
      ..style = PaintingStyle.fill
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawCircle(
      Offset(photoCenter.dx + 1, photoCenter.dy + 1),
      (size / 2) + 2,
      paint,
    );
    paint.maskFilter = null;

    // 6) Desenha a foto em círculo
    final clipPath = Path()..addOval(
      Rect.fromCircle(center: photoCenter, radius: size / 2)
    );
    canvas.save();
    canvas.clipPath(clipPath);
    
    // Fundo branco para a foto
    paint.color = ui.Color(0xFFFFFFFF);
    canvas.drawCircle(photoCenter, size / 2, paint);
    
    // Desenha a imagem
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCircle(center: photoCenter, radius: size / 2),
      Paint(),
    );
    canvas.restore();

    // 7) Borda da foto
    paint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(photoCenter, size / 2, paint);

    // 8) Indicador de localização preciso (pin/seta apontando para baixo)
    final pinTop = photoY + size + 2;
    final pinCenter = totalWidth / 2;
    
    // Sombra do pin
    paint
      ..color = ui.Color(0x30000000)
      ..style = PaintingStyle.fill
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
    
    final shadowPath = Path();
    shadowPath.moveTo(pinCenter + 1, pinTop + 1);
    shadowPath.lineTo(pinCenter - 4 + 1, pinTop + 8 + 1);
    shadowPath.lineTo(pinCenter + 4 + 1, pinTop + 8 + 1);
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);
    paint.maskFilter = null;
    
    // Pin principal
    paint
      ..color = borderColor
      ..style = PaintingStyle.fill;
    
    final pinPath = Path();
    pinPath.moveTo(pinCenter, pinTop);
    pinPath.lineTo(pinCenter - 4, pinTop + 8);
    pinPath.lineTo(pinCenter + 4, pinTop + 8);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    
    // Borda do pin
    paint
      ..color = ui.Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(pinPath, paint);

    // 9) Gera o bitmap
    final picture = recorder.endRecording();
    final outImage = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
    final byteData = await outImage.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  } catch (e) {
    debugPrint('Erro ao criar marcador personalizado: $e');
    // Retorna um marcador padrão em caso de erro
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _requestLocationPermission();
    _listenToAnimals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    if (!await Permission.location.isGranted) {
      await Permission.location.request();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.moveCamera(
      CameraUpdate.newLatLng(const LatLng(-5.0892, -42.8016)),
    );
  }

  void _listenToAnimals() {
    FirebaseFirestore.instance
        .collection('animais_perdidos')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      final newMarkers = <Marker>{};

      for (final doc in snapshot.docs) {
        if (!mounted) break;
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final imageUrl = data['imagem_url'] as String?;
        final raca = data['raca'] as String? ?? '';

        if (lat == null || lng == null || imageUrl == null) continue;

        try {
          final icon = await _styledMarkerFromUrl(
            imageUrl,
            label: raca,
            size: 60, // Tamanho reduzido para não cobrir muito
            borderColor: marker_utils.getAnimalColor(raca),
            borderWidth: 3,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              icon: icon,
              onTap: () => _showAnimalDetails(doc.id, data),
              // Anchor ajustado para que o pin aponte exatamente para a localização
              anchor: const Offset(0.5, 1.0),
            ),
          );
        } catch (e) {
          debugPrint('Erro ao criar marcador para ${doc.id}: $e');
          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              onTap: () => _showAnimalDetails(doc.id, data),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _markers
          ..clear()
          ..addAll(newMarkers);
      });
    });
  }

  void _showAnimalDetails(String animalId, Map<String, dynamic> animalData) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: AnimalDetailsView(
            animalData: animalData,
            animalId: animalId,
          ),
        ),
      ),
    );
  }

  Future<void> _openAddAnimalPage() async {
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAnimalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Animais Perdidos'),
        backgroundColor: Colors.lightBlue,
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Center(
                child: Image.asset(
                  'assets/icons/AnimalSearch.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.message, color: Colors.blueAccent),
                      SizedBox(width: 12),
                      Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            const Spacer(),
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.displayName ?? user.email ?? 'Usuário',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(target: LatLng(-5.0892, -42.8016), zoom: 13),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para adicionar um animal.')));
          } else {
            _openAddAnimalPage();
          }
        },
        backgroundColor: Colors.blue,
        icon: Row(children: [
          SvgPicture.asset('assets/icons/animal.svg', width: 24, height: 24, color: Colors.white),
          const SizedBox(width: 6),
          SvgPicture.asset('assets/icons/plus.svg', width: 20, height: 20, color: Colors.white)
        ]),
        label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
