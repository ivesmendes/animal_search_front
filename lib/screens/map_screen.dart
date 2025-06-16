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
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

/// Cria um BitmapDescriptor com foto do animal otimizado e compacto
Future<BitmapDescriptor> _styledMarkerFromUrl(
  String imageUrl, {
  String label = '',
  int size = 50,
  Color borderColor = const Color(0xFF3B82F6),
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

    // 2) Dimensões do marcador compacto
    final pinHeight = 8.0; // Pin menor
    final totalHeight = size + pinHeight + 4.0; // Mais compacto
    final totalWidth = size.toDouble() + 4.0; // Margem mínima
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth, totalHeight));
    final paint = Paint()..isAntiAlias = true;

    // 3) Centro da foto
    final photoCenter = Offset(totalWidth / 2, size / 2 + 2);

    // 4) Sombra suave
    paint
      ..color = const ui.Color(0x30000000)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(photoCenter.dx + 1, photoCenter.dy + 2),
      (size / 2) + 2,
      paint,
    );
    paint.maskFilter = null;

    // 5) Anel branco externo
    paint
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(photoCenter, (size / 2) + 2, paint);

    // 6) Desenha a foto em círculo
    final clipPath = Path()..addOval(
      Rect.fromCircle(center: photoCenter, radius: size / 2)
    );
    canvas.save();
    canvas.clipPath(clipPath);
    
    // Fundo branco para a foto
    paint.color = const ui.Color(0xFFFFFFFF);
    canvas.drawCircle(photoCenter, size / 2, paint);
    
    // Desenha a imagem
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCircle(center: photoCenter, radius: size / 2),
      Paint(),
    );
    canvas.restore();

    // 7) Borda colorida principal
    paint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawCircle(photoCenter, (size / 2) + 1, paint);

    // 8) Pin indicador compacto
    final pinTop = size + 2.0;
    final pinCenter = totalWidth / 2;
    
    // Sombra do pin
    paint
      ..color = const ui.Color(0x40000000)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
    
    final shadowPath = Path();
    shadowPath.moveTo(pinCenter + 0.5, pinTop + 0.5);
    shadowPath.lineTo(pinCenter - 4 + 0.5, pinTop + 8.0 + 0.5);
    shadowPath.lineTo(pinCenter + 4 + 0.5, pinTop + 8.0 + 0.5);
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);
    paint.maskFilter = null;
    
    // Pin principal
    paint
      ..color = borderColor
      ..style = PaintingStyle.fill;
    
    final pinPath = Path();
    pinPath.moveTo(pinCenter, pinTop);
    pinPath.lineTo(pinCenter - 4, pinTop + 8.0);
    pinPath.lineTo(pinCenter + 4, pinTop + 8.0);
    pinPath.close();
    canvas.drawPath(pinPath, paint);
    
    // Borda do pin
    paint
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(pinPath, paint);

    // 9) Ponto central do pin
    paint
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pinCenter, pinTop + 3), 1.5, paint);

    // 10) Badge com tipo do animal (opcional, apenas se label for curto)
    if (label.isNotEmpty && label.length <= 8) {
      final badgeSize = 16.0;
      final badgeCenter = Offset(
        photoCenter.dx + (size / 2) - 2,
        photoCenter.dy - (size / 2) + 2,
      );
      
      // Sombra do badge
      paint
        ..color = const ui.Color(0x40000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(badgeCenter.dx + 0.5, badgeCenter.dy + 0.5),
        badgeSize / 2,
        paint,
      );
      paint.maskFilter = null;
      
      // Badge background
      paint
        ..color = borderColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeCenter, badgeSize / 2, paint);
      
      // Badge border
      paint
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(badgeCenter, badgeSize / 2, paint);
      
      // Texto do badge
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText(label.substring(0, 1).toUpperCase());
      
      final paragraph = pb.build()..layout(ui.ParagraphConstraints(width: badgeSize));
      canvas.drawParagraph(
        paragraph, 
        Offset(
          badgeCenter.dx - paragraph.width / 2,
          badgeCenter.dy - paragraph.height / 2,
        ),
      );
    }

    // 11) Gera o bitmap
    final picture = recorder.endRecording();
    final outImage = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
    final byteData = await outImage.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
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

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  late AnimationController _fabAnimationController;
  late AnimationController _drawerAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  bool _isLoading = true;

  // Estilo personalizado do mapa
  static const String _mapStyle = '''
  [
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#e9f4ff"
        }
      ]
    },
    {
      "featureType": "landscape",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "lightness": 100
        },
        {
          "visibility": "simplified"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _requestLocationPermission();
    _listenToAnimals();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _drawerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    if (!await Permission.location.isGranted) {
      await Permission.location.request();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(-5.0892, -42.8016), 13),
    );
  }

  void _listenToAnimals() {
    FirebaseFirestore.instance
        .collection('animais_perdidos')
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      final newMarkers = <Marker>{};

      for (final doc in snapshot.docs) {
        if (!mounted) break;
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final imageUrl = data['imagem_url'] as String?;
        final raca = data['raca'] as String? ?? '';
        final tipo = data['tipo'] as String? ?? '';

        if (lat == null || lng == null || imageUrl == null) continue;

        try {
          final icon = await _styledMarkerFromUrl(
            imageUrl,
            label: raca.isNotEmpty ? raca : tipo,
            size: 50, // Tamanho reduzido para melhor visualização
            borderColor: marker_utils.getAnimalColor(raca.isNotEmpty ? raca : tipo),
            borderWidth: 3,
          );

          newMarkers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(lat, lng),
              icon: icon,
              onTap: () => _showAnimalDetails(doc.id, data),
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
        _isLoading = false;
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
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F9FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: AnimalDetailsView(
              animalData: animalData,
              animalId: animalId,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddAnimalPage() async {
    if (!mounted) return;
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddAnimalPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Mapa de Animais Perdidos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Drawer(
          backgroundColor: const Color(0xFFF6F9FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/icons/AnimalSearch.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Animal Search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Encontre seu melhor amigo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DrawerItem(
                  icon: Icons.message_rounded,
                  title: 'Chat',
                  subtitle: 'Converse com outros usuários',
                  onTap: () {
                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              if (user != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? 'Usuário',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Sair',
                    subtitle: 'Fazer logout da conta',
                    isDestructive: true,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _DrawerItem(
                    icon: Icons.login_rounded,
                    title: 'Login',
                    subtitle: 'Entre na sua conta',
                    onTap: () {
                      if (!mounted) return;
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            style: _mapStyle,
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-5.0892, -42.8016),
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),
          
          // Botão de localização personalizado
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        const LatLng(-5.0892, -42.8016),
                        13,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Transform.rotate(
              angle: _fabRotationAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.warning_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Faça login para adicionar um animal.'),
                            ],
                          ),
                          backgroundColor: const Color(0xFFEF4444),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    } else {
                      _openAddAnimalPage();
                    }
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/animal.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      SvgPicture.asset(
                        'assets/icons/plus.svg',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  label: const Text(
                    'Adicionar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDestructive 
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF1E3A8A),
                                ),
                              ),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}