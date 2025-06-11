
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Você precisa estar logado para acessar o chat.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seus Chats'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('chats')
            .where('usuarios', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não entrou em nenhum chat',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final data = chatDoc.data() as Map<String, dynamic>;
              final List usuarios = data['usuarios'];
              final otherUserId = usuarios.firstWhere((uid) => uid != currentUser!.uid);
              final animalId = data['animal_id'] ?? ''; // trata ausência

              return FutureBuilder<DocumentSnapshot>(
                future: firestore.collection('usuarios').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final nome = userData['nome'] ?? 'Usuário';

                  return ListTile(
                    title: Text(nome),
                    subtitle: Text(data['ultimo_msg'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatDoc.id,
                            otherUserId: otherUserId,
                            otherUserName: nome,
                            animalId: animalId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String animalId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.animalId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> mensagensExibidas = [];

  Future<void> enviarMensagem() async {
    final texto = _msgController.text.trim();
    if (texto.isEmpty || currentUser == null) return;

    await firestore.collection('chats').doc(widget.chatId).collection('mensagens').add({
      'texto': texto,
      'remetenteId': currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await firestore.collection('chats').doc(widget.chatId).update({
      'ultimo_msg': texto,
    });

    _msgController.clear();
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Mensagens',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          if (widget.animalId.isNotEmpty)
            FutureBuilder<DocumentSnapshot>(
              future: firestore.collection('animais_perdidos').doc(widget.animalId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                return Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imagem_url'] ?? '',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['tipo'] ?? 'Tipo desconhecido', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Raça: ${data['raca'] ?? 'Não informada'}'),
                            Text('Cor: ${data['cor'] ?? 'Não informada'}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('mensagens')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final mensagens = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final doc = mensagens[index];
                    final msg = doc.data() as Map<String, dynamic>;
                    final isMinhaMsg = msg['remetenteId'] == currentUser!.uid;
                    final msgTexto = msg['texto'] ?? '';

                    if (!isMinhaMsg && !mensagensExibidas.contains(doc.id)) {
                      mensagensExibidas.add(doc.id);
                      showLocalNotification(widget.otherUserName, msgTexto);
                    }

                    return Align(
                      alignment: isMinhaMsg ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMinhaMsg ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msgTexto,
                          style: TextStyle(
                            color: isMinhaMsg ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
