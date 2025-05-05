import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'dart:async';


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

  void _submit() async {
  if (_formKey.currentState!.validate() && _pickedLocation != null && _image != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print("Iniciando upload da imagem...");
      final fileName = path.basename(_image!.path);
      final storageRef = FirebaseStorage.instance.ref().child('animal_images/$fileName');

      await storageRef.putFile(_image!).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("Upload demorou muito");
        },
      );


      final imageUrl = await storageRef.getDownloadURL();
      print("URL da imagem obtida: $imageUrl");

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
      };

      print("Salvando no Firestore...");
      await FirebaseFirestore.instance.collection('animais_perdidos').add(animalData);
      print("Salvo com sucesso.");

      Navigator.of(context).pop(); // Fecha o loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal cadastrado com sucesso!')),
      );
      Navigator.pop(context);

    } catch (e) {
      Navigator.of(context).pop();
      print("Erro durante cadastro: $e");
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
      appBar: AppBar(
        title: const Text('Cadastrar Animal Perdido'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
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
              ),
              if (_animalType == 'Outro')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Informe o tipo'),
                  onChanged: (value) {
                    _otherAnimalType = value;
                  },
                  validator: (value) {
                    if (_animalType == 'Outro' && (value == null || value.isEmpty)) {
                      return 'Informe o tipo de animal';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Raça'),
                validator: (value) => value!.isEmpty ? 'Informe a raça' : null,
              ),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Cor predominante'),
                validator: (value) => value!.isEmpty ? 'Informe a cor' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedSize,
                decoration: const InputDecoration(labelText: 'Porte'),
                items: const [
                  DropdownMenuItem(value: 'Pequeno', child: Text('Pequeno')),
                  DropdownMenuItem(value: 'Médio', child: Text('Médio')),
                  DropdownMenuItem(value: 'Grande', child: Text('Grande')),
                ],
                onChanged: (value) {
                  setState(() => _selectedSize = value!);
                },
              ),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data em que foi visto',
                  hintText: 'DD/MM/AAAA',
                ),
                onTap: _pickDate,
                validator: (value) => value!.isEmpty ? 'Informe a data' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição adicional'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text("Toque no mapa para marcar a localização:"),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  onTap: _onMapTap,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-5.0892, -42.8016),
                    zoom: 13,
                  ),
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
              const SizedBox(height: 16),
              if (_image != null)
                Image.file(_image!, height: 100)
              else
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Selecionar foto do animal'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Cadastrar Animal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
