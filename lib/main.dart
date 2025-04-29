import 'package:flutter/material.dart';
import 'screens/map_screen.dart'; // Importe a tela do mapa
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Search',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // Defina o MapScreen como a tela inicial
    );
  }
}
