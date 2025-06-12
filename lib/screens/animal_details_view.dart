import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'chat_screen.dart';

class AnimalDetailsView extends StatelessWidget {
  final Map<String, dynamic> animalData;
  final String animalId;

  const AnimalDetailsView({
    super.key,
    required this.animalData,
    required this.animalId,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tipo = animalData['tipo'] as String? ?? 'Animal';
    final condicao = (animalData['condicao'] as String? ?? '').toLowerCase();
    final imageUrl = animalData['imagem_url'] as String?;
    final mainColor = _getColorForAnimalType(tipo);
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),

            // imagem
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
                      placeholder: (_, __) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: Icon(Icons.pets, size: 60, color: mainColor)),
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
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.black87, size: 20),
                      ),
                    ),
                  ),
                ],
              ),

            // conteúdo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // título e chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(tipo, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    _buildConditionChip(condicao),
                  ],
                ),

                const SizedBox(height: 16),
                _buildInfoSection(mainColor),
                const SizedBox(height: 20),
                if ((animalData['descricao'] as String?)?.isNotEmpty ?? false)
                  _buildDescricao(animalData['descricao'] as String),
                const SizedBox(height: 24),
                if (animalData['usuario_nome'] != null)
                  _buildUsuarioCard(mainColor),
                const SizedBox(height: 24),

                // 1) Botão de Chat: somente para outros usuários
                if (animalData['usuario_uid'] != currentUserUid) ...[
                  Center(
                    child: SizedBox(
                      width: size.width * 0.6,
                      child: _buildActionButton(
                        context,
                        icon: Icons.chat,
                        label: 'Abrir Chat',
                        onTap: () => _contactPoster(context),
                        color: mainColor,
                        isPrimary: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2) Botão Achado/Adotado: sempre que a condição for aplicável
                if (condicao == 'perdido')
                  Center(
                    child: SizedBox(
                      width: size.width * 0.6,
                      child: _buildActionButton(
                        context,
                        icon: Icons.check_circle,
                        label: 'Achado',
                        onTap: () => _sendFoundProof(context),
                        color: Colors.red,
                        isPrimary: false,
                      ),
                    ),
                  )
                else if (condicao == 'adoção' || condicao == 'de rua')
                  Center(
                    child: SizedBox(
                      width: size.width * 0.6,
                      child: _buildActionButton(
                        context,
                        icon: Icons.home,
                        label: 'Adotado',
                        onTap: () => _sendFoundProof(context),
                        color: Colors.blue,
                        isPrimary: false,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Color color) => Container(
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildDetailRow(Icons.pets, 'Raça', animalData['raca'] as String? ?? 'Não informada', color),
          const Divider(height: 24),
          _buildDetailRow(Icons.palette, 'Cor', animalData['cor'] as String? ?? 'Não informada', color),
          const Divider(height: 24),
          _buildDetailRow(Icons.straighten, 'Porte', animalData['porte'] as String? ?? 'Não informado', color),
          const Divider(height: 24),
          _buildDetailRow(Icons.calendar_today, 'Visto em', animalData['data-visto'] as String? ?? 'Não informada', color),
        ]),
      );

  Widget _buildDescricao(String texto) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(texto, style: TextStyle(color: Colors.grey.shade800, height: 1.5)),
          ),
        ],
      );

  Widget _buildUsuarioCard(Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          CircleAvatar(backgroundColor: color, child: const Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(child: Text(animalData['usuario_nome'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) => Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ])),
      ]);

  Widget _buildConditionChip(String cond) {
    final color = _getConditionColor(cond);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(cond.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isPrimary,
  }) =>
      GestureDetector(
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
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: isPrimary ? Colors.white : color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isPrimary ? Colors.white : color, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  Future<void> _sendFoundProof(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageUrl = await uploadImageToCloudinary(File(picked.path));
    if (imageUrl == null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar imagem ao Cloudinary.')));
      return;
    }

    await FirebaseFirestore.instance.collection('achados_pendentes').add({
      'animal_id': animalId,
      'condicao': animalData['condicao'],
      'imagem_url_nova': imageUrl,
      'imagem_url_antiga': animalData['imagem_url'],
      'data_envio': FieldValue.serverTimestamp(),
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada ao administrador.')));
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dny9nwscu';
    final uploadPreset = 'animal_upload';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path, filename: path.basename(imageFile.path)));
    final res = await req.send();
    if (res.statusCode == 200) {
      final body = await res.stream.bytesToString();
      return RegExp(r'"secure_url":"(.*?)"').firstMatch(body)?.group(1)?.replaceAll(r'\/', '/');
    }
    return null;
  }

  void _contactPoster(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final otherUid = animalData['usuario_uid'] as String?;
    if (otherUid == null || otherUid == user.uid) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não é possível iniciar chat.')));
      return;
    }

    final fs = FirebaseFirestore.instance;
    final query = await fs.collection('chats').where('usuarios', arrayContains: user.uid).get();
    DocumentSnapshot? chatDoc;
    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['usuarios'] as List).contains(otherUid) && data['animal_id'] == animalId) {
        chatDoc = doc;
        break;
      }
    }

    String chatId;
    if (chatDoc == null) {
      final newChat = await fs.collection('chats').add({'usuarios': [user.uid, otherUid], 'animal_id': animalId, 'ultimo_msg': ''});
      chatId = newChat.id;
    } else {
      chatId = chatDoc.id;
    }

    final otherUserDoc = await fs.collection('usuarios').doc(otherUid).get();
    final otherName = (otherUserDoc.data()?['nome'] as String?) ?? 'Usuário';
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, otherUserId: otherUid, otherUserName: otherName, animalId: animalId)));
    }
  }

  Color _getColorForAnimalType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('cachorro') || t.contains('cão')) return Colors.blue;
    if (t.contains('gato')) return Colors.purple;
    if (t.contains('ave') || t.contains('pássaro')) return Colors.green;
    if (t.contains('coelho')) return Colors.pink;
    return Colors.lightBlue;
  }

  Color _getConditionColor(String? cond) {
    switch ((cond ?? '').toLowerCase()) {
      case 'perdido':
        return Colors.red;
      case 'adoção':
        return Colors.blue;
      case 'de rua':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
