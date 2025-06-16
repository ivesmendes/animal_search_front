// lib/services/geofire_services.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class GeoFireService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de documentos dentro de [radiusKm] km de (lat, lng)
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> queryNearby(
    double lat,
    double lng,
    double radiusKm,
  ) {
    // Ponto central
    final center = GeoFirePoint(GeoPoint(lat, lng));

    // Consulta geoespacial usando geoflutterfire_plus
    return GeoCollectionReference<Map<String, dynamic>>(
      _firestore.collection('animais_perdidos'),
    ).subscribeWithin(
      center: center,
      radiusInKm: radiusKm,
      field: 'geo',
      // o parâmetro `data` aqui já é o Map<String, dynamic> do documento
      geopointFrom: (data) =>
          (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      strictMode: true,
    );
  }

  /// Adiciona um novo animal, salvando o campo 'geo' com geopoint e geohash
  Future<void> addAnimal(Map<String, dynamic> data) async {
    // Cria o GeoFirePoint a partir de latitude/longitude
    final point = GeoFirePoint(
      GeoPoint(
        data['latitude'] as double,
        data['longitude'] as double,
      ),
    );

    // Monta o mapa final incluindo `geo: point.data`
    final docData = <String, dynamic>{
      ...data,
      'geo': point.data,  // point.data é Map<String, dynamic> com geopoint e geohash
    };

    await _firestore.collection('animais_perdidos').add(docData);
  }
}
