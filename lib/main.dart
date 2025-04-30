import 'package:flutter/material.dart';
import 'screens/map_screen.dart'; // Importe a tela do mapa


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Search',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapScreen(), // Defina o MapScreen como a tela inicial
    );
  }
}
