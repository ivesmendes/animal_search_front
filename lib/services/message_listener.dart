import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class MessageListenerService {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseAuth auth = FirebaseAuth.instance;

  static Stream<QuerySnapshot>? _messageStream;
  static final Set<String> _notifiedMessages = {};

  static void startListening() {
    final user = auth.currentUser;
    if (user == null) return;

    firestore
        .collection('chats')
        .where('usuarios', arrayContains: user.uid)
        .get()
        .then((snapshot) {
      for (var chatDoc in snapshot.docs) {
        final chatId = chatDoc.id;

        _messageStream = firestore
            .collection('chats')
            .doc(chatId)
            .collection('mensagens')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots();

        _messageStream!.listen((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            final msg = doc.data() as Map<String, dynamic>;
            final remetenteId = msg['remetenteId'];
            final texto = msg['texto'] ?? '';

            if (remetenteId != user.uid && !_notifiedMessages.contains(doc.id)) {
              _notifiedMessages.add(doc.id);
              showLocalNotification("Nova mensagem", texto);
            }
          }
        });
      }
    });
  }

  static Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Mensagens',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }
}
