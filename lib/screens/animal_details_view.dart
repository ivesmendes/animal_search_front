import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart'; // Importa a tela de chat

class AnimalDetailsView extends StatelessWidget {
  final Map<String, dynamic> animalData;
  final String animalId;

  const AnimalDetailsView({
    Key? key,
    required this.animalData,
    required this.animalId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tipo = animalData['tipo'] ?? 'Animal';
    final imageUrl = animalData['imagem_url'];
    final Color mainColor = _getColorForAnimalType(tipo);
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Stack(
                children: [
                  Hero(
                    tag: 'animal_image_$animalId',
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: size.height * 0.3,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.pets, size: 60, color: mainColor),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.black87, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tipo,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusChip(animalData),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(icon: Icons.pets, label: 'Raça', value: animalData['raca'] ?? 'Não informada', color: mainColor),
                        const Divider(height: 24),
                        _buildDetailRow(icon: Icons.palette, label: 'Cor', value: animalData['cor'] ?? 'Não informada', color: mainColor),
                        const Divider(height: 24),
                        _buildDetailRow(icon: Icons.straighten, label: 'Porte', value: animalData['porte'] ?? 'Não informado', color: mainColor),
                        const Divider(height: 24),
                        _buildDetailRow(icon: Icons.calendar_today, label: 'Visto em', value: animalData['data-visto'] ?? 'Não informada', color: mainColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (animalData['descricao'] != null && animalData['descricao'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            animalData['descricao'] ?? '',
                            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (animalData['usuario_nome'] != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: mainColor,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Adicionado por', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  animalData['usuario_nome'] ?? 'Usuário desconhecido',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (animalData['usuario_uid'] != currentUserUid)
                    Center(
                      child: SizedBox(
                        width: size.width * 0.6,
                        child: _buildActionButton(
                          context,
                          icon: Icons.chat,
                          label: 'Abrir Chat',
                          onTap: () => _contactPoster(context, animalData),
                          color: mainColor,
                          isPrimary: true,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> animalData) {
    String status = animalData['status'] ?? 'perdido';
    Color statusColor = status.toLowerCase() == 'encontrado' ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isPrimary ? null : Border.all(color: color),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactPoster(BuildContext context, Map<String, dynamic> animalData) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final String? otherUserId = animalData['usuario_uid'];
    if (currentUser == null || otherUserId == null || currentUser.uid == otherUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível iniciar chat.')),
      );
      return;
    }

    final chatQuery = await firestore
        .collection('chats')
        .where('usuarios', arrayContains: currentUser.uid)
        .get();

    DocumentSnapshot? existingChat;
    for (var doc in chatQuery.docs) {
      final usuarios = doc['usuarios'] as List;
      if (usuarios.contains(otherUserId)) {
        existingChat = doc;
        break;
      }
    }

    String chatId;
    if (existingChat == null) {
      final newChat = await firestore.collection('chats').add({
        'usuarios': [currentUser.uid, otherUserId],
        'ultimo_msg': '',
      });
      chatId = newChat.id;
    } else {
      chatId = existingChat.id;
    }

    final otherUserDoc =
        await firestore.collection('usuarios').doc(otherUserId).get();
    final otherUserName = (otherUserDoc.data() as Map?)?['nome'] ?? 'Usuário';

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      ));
    }
  }

  Color _getColorForAnimalType(String tipo) {
    tipo = tipo.toLowerCase();
    if (tipo.contains('cachorro') || tipo.contains('cão')) return Colors.blue;
    if (tipo.contains('gato')) return Colors.purple;
    if (tipo.contains('ave') || tipo.contains('pássaro')) return Colors.green;
    if (tipo.contains('coelho')) return Colors.pink;
    return Colors.lightBlue;
  }
}
