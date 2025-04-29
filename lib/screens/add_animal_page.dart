import 'package:flutter/material.dart';

class AddAnimalPage extends StatelessWidget {
  const AddAnimalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Animal Perdido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Raça do animal',
              ),
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Endereço',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Depois aqui colocamos a lógica de salvar o animal
              },
              child: const Text('Cadastrar Animal'),
            ),
          ],
        ),
      ),
    );
  }
}
