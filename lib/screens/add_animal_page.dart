import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AddAnimalPage extends StatefulWidget {
  const AddAnimalPage({Key? key}) : super(key: key);

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  String _animalType = 'Cachorro';
  String? _otherAnimalType;
  LatLng? _pickedLocation;
  File? _image;

  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  String _selectedSize = 'Pequeno';
  String _animalCondition = 'Perdido';
  GoogleMapController? _mapController;

  // Cores do tema azul
  static const Color primaryBlue = Color(0xFF2563eb);
  static const Color lightBlue = Color(0xFF3b82f6);
  static const Color accentBlue = Color(0xFF60a5fa);
  static const Color backgroundBlue = Color(0xFFf0f9ff);
  static const Color cardBlue = Color(0xFFfafbff);

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _pickedLocation = location;
    });
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dny9nwscu';
    final uploadPreset = 'animal_upload';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
        filename: path.basename(imageFile.path),
      ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final imageUrl = RegExp(r'"secure_url":"(.*?)"')
          .firstMatch(responseData)
          ?.group(1)
          ?.replaceAll(r'\/', '/');
      return imageUrl;
    } else {
      return null;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _pickedLocation != null && _image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cadastrando animal...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Usuário não autenticado');

        final imageUrl = await uploadImageToCloudinary(_image!);
        if (imageUrl == null) throw Exception("Erro ao fazer upload da imagem.");

        final animalData = {
          'tipo': _animalType == 'Outro' ? _otherAnimalType : _animalType,
          'raca': _breedController.text,
          'cor': _colorController.text,
          'porte': _selectedSize,
          'condicao': _animalCondition,
          'data-visto': _dateController.text,
          'descricao': _descriptionController.text,
          'latitude': _pickedLocation!.latitude,
          'longitude': _pickedLocation!.longitude,
          'imagem_url': imageUrl,
          'usuario_uid': user.uid,
          'usuario_email': user.email,
          'usuario_nome': user.displayName ?? 'Anônimo',
        };

        await FirebaseFirestore.instance.collection('animais_perdidos').add(animalData);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Animal cadastrado com sucesso!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao cadastrar: $e',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Preencha todos os campos, selecione uma localização e uma foto.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Cadastrar Animal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildSectionTitle('Informações do Animal', Icons.pets),
              const SizedBox(height: 16),
              _buildCard([
                _buildDropdownTipoAnimal(),
                const SizedBox(height: 20),
                if (_animalType == 'Outro') ...[
                  _buildTextField(_otherAnimalType, 'Informe o tipo', (v) => _otherAnimalType = v),
                  const SizedBox(height: 20),
                ],
                _buildTextFieldController(_breedController, 'Raça'),
                const SizedBox(height: 20),
                _buildTextFieldController(_colorController, 'Cor predominante'),
                const SizedBox(height: 20),
                _buildDropdownPorte(),
                const SizedBox(height: 20),
                _buildDropdownCondicao(),
                const SizedBox(height: 20),
                _buildDataField(),
                const SizedBox(height: 20),
                _buildDescricaoField(),
              ]),
              
              const SizedBox(height: 28),
              _buildSectionTitle('Localização', Icons.location_on),
              const SizedBox(height: 16),
              _buildMapCard(),
              
              const SizedBox(height: 28),
              _buildSectionTitle('Foto do Animal', Icons.camera_alt),
              const SizedBox(height: 16),
              _buildImageSection(),
              
              const SizedBox(height: 36),
              _buildActionButton(
                context,
                icon: Icons.pets,
                label: 'Cadastrar Animal',
                onTap: _submit,
                color: primaryBlue,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: accentBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: accentBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.touch_app, color: primaryBlue, size: 20),
                const SizedBox(width: 10),
                const Text(
                  "Toque no mapa para marcar a localização:",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentBlue.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      onTap: _onMapTap,
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(-5.0892, -42.8016),
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer()),
                      },
                      markers: _pickedLocation != null
                          ? {
                              Marker(
                                markerId: const MarkerId('picked'),
                                position: _pickedLocation!,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                              )
                            }
                          : {},
                    ),
                    if (_pickedLocation != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'Localização marcada',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: accentBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _image != null
            ? Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _image!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.edit, color: primaryBlue, size: 20),
                    label: Text(
                      'Alterar foto',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: accentBlue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentBlue.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Selecionar foto do animal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toque para escolher uma imagem',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryBlue.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDropdownTipoAnimal() {
    return DropdownButtonFormField<String>(
      value: _animalType,
      decoration: _buildInputDecoration('Tipo de animal'),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'Cachorro', child: Text('Cachorro')),
        DropdownMenuItem(value: 'Gato', child: Text('Gato')),
        DropdownMenuItem(value: 'Outro', child: Text('Outro')),
      ],
      onChanged: (value) {
        setState(() {
          _animalType = value!;
          if (_animalType != 'Outro') _otherAnimalType = null;
        });
      },
    );
  }

  Widget _buildDropdownCondicao() {
    return DropdownButtonFormField<String>(
      value: _animalCondition,
      decoration: _buildInputDecoration('Condição do animal'),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'Perdido', child: Text('Perdido')),
        DropdownMenuItem(value: 'Adoção', child: Text('Adoção')),
        DropdownMenuItem(value: 'De rua', child: Text('De rua')),
      ],
      onChanged: (value) {
        setState(() {
          _animalCondition = value!;
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDropdownPorte() {
    return DropdownButtonFormField<String>(
      value: _selectedSize,
      decoration: _buildInputDecoration('Porte'),
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'Pequeno', child: Text('Pequeno')),
        DropdownMenuItem(value: 'Médio', child: Text('Médio')),
        DropdownMenuItem(value: 'Grande', child: Text('Grande')),
      ],
      onChanged: (value) => setState(() => _selectedSize = value!),
    );
  }

  Widget _buildTextFieldController(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(label),
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildTextField(String? value, String label, void Function(String)? onChanged) {
    return TextFormField(
      decoration: _buildInputDecoration(label),
      onChanged: onChanged,
      validator: (v) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDataField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: _buildInputDecoration('Data em que foi visto').copyWith(
        hintText: 'DD/MM/AAAA',
        suffixIcon: Icon(Icons.calendar_today, color: primaryBlue, size: 20),
      ),
      onTap: _pickDate,
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDescricaoField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: _buildInputDecoration('Descrição adicional'),
      maxLines: 3,
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: primaryBlue.withOpacity(0.8),
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentBlue.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentBlue.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, lightBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
