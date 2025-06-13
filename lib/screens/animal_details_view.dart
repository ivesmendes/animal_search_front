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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32), 
          topRight: Radius.circular(32)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32), 
          topRight: Radius.circular(32)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhanced drag handle
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade300, Colors.blue.shade500],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Enhanced image section
            if (imageUrl != null && imageUrl.isNotEmpty)
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Hero(
                        tag: 'animal_image_$animalId',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: size.height * 0.3,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade100, Colors.blue.shade200],
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade100, Colors.blue.shade200],
                              ),
                            ),
                            child: Icon(Icons.pets, size: 60, color: Colors.blue.shade600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    right: 32,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Icon(Icons.close, color: Colors.blue.shade700, size: 24),
                      ),
                    ),
                  ),
                ],
              ),

            // Enhanced content section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced title and chip section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tipo,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                        _buildConditionChip(condicao),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildInfoSection(mainColor),
                  const SizedBox(height: 20),
                  
                  if ((animalData['descricao'] as String?)?.isNotEmpty ?? false)
                    _buildDescricao(animalData['descricao'] as String),
                  
                  const SizedBox(height: 20),
                  
                  if (animalData['usuario_nome'] != null)
                    _buildUsuarioCard(mainColor),
                  
                  const SizedBox(height: 32),

                  // Enhanced action buttons
                  if (animalData['usuario_uid'] != currentUserUid) ...[
                    _buildActionButton(
                      context,
                      icon: Icons.chat_bubble_rounded,
                      label: 'Abrir Chat',
                      onTap: () => _contactPoster(context),
                      color: Colors.blue.shade600,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (condicao == 'perdido')
                    _buildActionButton(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'Marcar como Achado',
                      onTap: () => _sendFoundProof(context),
                      color: Colors.red.shade500,
                      isPrimary: false,
                    )
                  else if (condicao == 'adoção' || condicao == 'de rua')
                    _buildActionButton(
                      context,
                      icon: Icons.home_rounded,
                      label: 'Marcar como Adotado',
                      onTap: () => _sendFoundProof(context),
                      color: Colors.green.shade500,
                      isPrimary: false,
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

  Widget _buildInfoSection(Color color) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDetailRow(Icons.pets, 'Raça', animalData['raca'] as String? ?? 'Não informada', Colors.blue.shade600),
            const SizedBox(height: 20),
            Divider(color: Colors.blue.shade100, thickness: 1),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.palette, 'Cor', animalData['cor'] as String? ?? 'Não informada', Colors.blue.shade600),
            const SizedBox(height: 20),
            Divider(color: Colors.blue.shade100, thickness: 1),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.straighten, 'Porte', animalData['porte'] as String? ?? 'Não informado', Colors.blue.shade600),
            const SizedBox(height: 20),
            Divider(color: Colors.blue.shade100, thickness: 1),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.calendar_today, 'Visto em', animalData['data-visto'] as String? ?? 'Não informada', Colors.blue.shade600),
          ],
        ),
      );

  Widget _buildDescricao(String texto) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              texto,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildUsuarioCard(Color color) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                animalData['usuario_nome'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildConditionChip(String cond) {
    final color = _getConditionColor(cond);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Text(
        cond.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
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
  }) =>
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  )
                : null,
            color: isPrimary ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: isPrimary ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                blurRadius: isPrimary ? 15 : 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isPrimary ? Colors.white : color,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

  // Keep your existing methods unchanged
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
    if (t.contains('cachorro') || t.contains('cão')) return Colors.blue.shade600;
    if (t.contains('gato')) return Colors.purple.shade600;
    if (t.contains('ave') || t.contains('pássaro')) return Colors.green.shade600;
    if (t.contains('coelho')) return Colors.pink.shade600;
    return Colors.blue.shade600;
  }

  Color _getConditionColor(String? cond) {
    switch ((cond ?? '').toLowerCase()) {
      case 'perdido':
        return Colors.red.shade600;
      case 'adoção':
        return Colors.blue.shade600;
      case 'de rua':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
