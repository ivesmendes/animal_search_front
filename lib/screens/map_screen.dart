
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_animal_page.dart';
import 'login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _solicitarPermissaoLocalizacao();
    _carregarAnimaisDoFirestore();
  }

  Future<void> _solicitarPermissaoLocalizacao() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.moveCamera(
      CameraUpdate.newLatLng(
        const LatLng(-5.0892, -42.8016),
      ),
    );
  }

  Future<void> _carregarAnimaisDoFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('animais_perdidos').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];
      final imageUrl = data['imagem_url'];
      final tipo = data['tipo'];
      final raca = data['raca'];

      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: '$tipo - $raca',
          onTap: () {
            _mostrarDetalhesAnimal(data);
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );

      setState(() {
        _markers.add(marker);
      });
    }
  }

  void _mostrarDetalhesAnimal(Map<String, dynamic> animalData) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(animalData['tipo'] ?? 'Animal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (animalData['imagem_url'] != null)
                Image.network(animalData['imagem_url'], height: 120),
              const SizedBox(height: 10),
              Text('Raça: ${animalData['raca'] ?? ''}'),
              Text('Cor: ${animalData['cor'] ?? ''}'),
              Text('Porte: ${animalData['porte'] ?? ''}'),
              Text('Data visto: ${animalData['data-visto'] ?? ''}'),
              Text('Descrição: ${animalData['descricao'] ?? ''}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
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
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Center(
                child: Image.asset(
                  'assets/icons/AnimalSearch.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Spacer(),
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.displayName ?? user.email ?? 'Usuário',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (user != null) const SizedBox(height: 12),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              markers: _markers,
              initialCameraPosition: const CameraPosition(
                target: LatLng(-5.0892, -42.8016),
                zoom: 13,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddAnimalPage(),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              icon: Row(
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
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
