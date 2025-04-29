import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'add_animal_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.moveCamera(
      CameraUpdate.newLatLng(
        const LatLng(-5.0892, -42.8016),
      ),
    );
  }

  void _addMarker(double lat, double lng) {
    final marker = Marker(
      markerId: MarkerId('some_id'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: "Animal perdido"),
      icon: BitmapDescriptor.defaultMarker,
    );
    setState(() {
      _markers.add(marker);
    });
  }

  void _onTap(LatLng location) {
    _addMarker(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Animais Perdidos'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            markers: _markers,
            onTap: _onTap,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-5.0892, -42.8016),
              zoom: 13,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddAnimalPage()),
                );
              },
              backgroundColor: Colors.deepPurple,
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
