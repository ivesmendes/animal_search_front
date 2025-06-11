import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/map_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './services/message_listener.dart'; // <- novo import

// Instância global do plugin de notificações locais
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix para o erro de type cast no uso do emulador de auth
  try {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  } catch (e) {
    debugPrint('Emulator setup ignored: $e');
  }

  try {
    // Inicializa o Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configura idioma padrão para auth
    await FirebaseAuth.instance.setLanguageCode("pt");

    // Configuração do App Check
    if (kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        webProvider: ReCaptchaV3Provider(
          '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI',
        ),
      );
      debugPrint('🔐 Modo debug ativado para App Check');
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }

    // Inicializa notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    runApp(const MyApp());

    // Inicia escuta global de mensagens após inicialização
    MessageListenerService.startListening();
  } catch (e) {
    debugPrint('🔥 Erro na inicialização: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animal Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const MapScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro na inicialização. Reinicie o aplicativo.'),
        ),
      ),
    );
  }
}
