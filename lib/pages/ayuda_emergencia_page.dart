import 'package:flutter/material.dart';

class AyudaEmergenciaPage extends StatelessWidget {
  const AyudaEmergenciaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayuda / Emergencia"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Seleccione el tipo de ayuda requerida",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text("Emergencia en operación de izaje"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Aquí luego puedes:
                // - Enviar alerta al backend
                // - Enviar correo
                // - Registrar evento
              },
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              icon: const Icon(Icons.help_outline),
              label: const Text("Solicitar apoyo técnico"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Aquí puedes navegar a un formulario
              },
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("Contacto inmediato"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Luego puedes integrar llamada o WhatsApp
              },
            ),
          ],
        ),
      ),
    );
  }
}
