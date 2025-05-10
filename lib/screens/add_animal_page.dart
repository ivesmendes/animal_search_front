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
  GoogleMapController? _mapController;

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
        builder: (_) => const Center(child: CircularProgressIndicator()),
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
          const SnackBar(content: Text('Animal cadastrado com sucesso!')),
        );
        Navigator.pop(context);
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos, selecione uma localização e uma foto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cadastrar Animal Perdido'),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard([
                _buildDropdownTipoAnimal(),
                if (_animalType == 'Outro') _buildTextField(_otherAnimalType, 'Informe o tipo', (v) => _otherAnimalType = v),
                _buildTextFieldController(_breedController, 'Raça'),
                _buildTextFieldController(_colorController, 'Cor predominante'),
                _buildDropdownPorte(),
                _buildDataField(),
                _buildDescricaoField(),
              ]),
              const SizedBox(height: 16),
              _buildCard([
                const Text("Toque no mapa para marcar a localização:"),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Listener(
                      onPointerDown: (_) => _mapController?.setMapStyle(null),
                      child: GoogleMap(
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
                                )
                              }
                            : {},
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 160),
                )
              else
                _buildActionButton(
                  context,
                  icon: Icons.image,
                  label: 'Selecionar foto do animal',
                  onTap: _pickImage,
                  color: Colors.blueAccent,
                ),
              const SizedBox(height: 24),
              _buildActionButton(
                context,
                icon: Icons.pets,
                label: 'Cadastrar Animal',
                onTap: _submit,
                color: Colors.lightBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildDropdownTipoAnimal() {
    return DropdownButtonFormField<String>(
      value: _animalType,
      decoration: const InputDecoration(labelText: 'Tipo de animal'),
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

  Widget _buildTextFieldController(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildTextField(String? value, String label, void Function(String)? onChanged) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: (v) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDropdownPorte() {
    return DropdownButtonFormField<String>(
      value: _selectedSize,
      decoration: const InputDecoration(labelText: 'Porte'),
      items: const [
        DropdownMenuItem(value: 'Pequeno', child: Text('Pequeno')),
        DropdownMenuItem(value: 'Médio', child: Text('Médio')),
        DropdownMenuItem(value: 'Grande', child: Text('Grande')),
      ],
      onChanged: (value) => setState(() => _selectedSize = value!),
    );
  }

  Widget _buildDataField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: const InputDecoration(labelText: 'Data em que foi visto', hintText: 'DD/MM/AAAA'),
      onTap: _pickDate,
      validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDescricaoField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(labelText: 'Descrição adicional'),
      maxLines: 3,
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}
