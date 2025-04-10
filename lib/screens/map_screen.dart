import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  MapScreen({Key? key}) : super(key: key);  // Parâmetro 'key' já está correto

  @override
  MapScreenState createState() => MapScreenState();  // Nome da classe corrigido
}

class MapScreenState extends State<MapScreen> {  // Alterado para tornar público
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};  // Tornando _markers final

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

  // Método para adicionar marcador ao tocar no mapa
  void _onTap(LatLng location) {
    _addMarker(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Animais Perdidos'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        markers: _markers,
        onTap: _onTap,  // Chama _addMarker ao tocar no mapa
        initialCameraPosition: const CameraPosition(
          target: LatLng(-23.5505, -46.6333),  // São Paulo como exemplo
          zoom: 12,
        ),
      ),
    );
  }
}
