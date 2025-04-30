import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/map_screen.dart'; // Tela principal do mapa
import 'screens/login_screen.dart'; // (se quiser usar futuramente)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa o Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MapScreen(), // Tela inicial
    );
  }
}
