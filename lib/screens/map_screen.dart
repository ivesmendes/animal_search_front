import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'add_animal_page.dart';
import 'login_screen.dart';
import 'custom_marker_widget.dart';
import 'animal_details_view.dart';
import 'chat_screen.dart';

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
      final newMarkers = <Marker>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        final imageUrl = data['imagem_url'] as String?;
        final raca = data['raca'] as String? ?? '';

        if (lat == null || lng == null || imageUrl == null) continue;

        final markerIcon = await createCustomMarker(context, imageUrl, raca);
        newMarkers.add(Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.fromBytes(markerIcon), // if using BitmapDescriptor.bytes(markerIcon) replace accordingly
          onTap: () => _showAnimalDetails(doc.id, data),
        ));
      }

      if (mounted) {
        setState(() {
          _markers
            ..clear()
            ..addAll(newMarkers);
        });
      }
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
          child: AnimalDetailsView(animalData: animalData, animalId: animalId),
        ),
      ),
    );
  }

  Future<void> _openAddAnimalPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddAnimalPage()),
    );
    // no need to manually reload—stream listener updates markers
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
              child: Center(child: Image.asset('assets/icons/AnimalSearch.png', width: 120, fit: BoxFit.contain)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: const [
                    Icon(Icons.message, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text('Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ]),
                ),
              ),
            ),
            const Divider(),
            const Spacer(),
            if (user != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.person, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(user.displayName ?? user.email ?? 'Usuário',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
          SvgPicture.asset('assets/icons/plus.svg', width: 20, height: 20, color: Colors.white),
        ]),
        label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
