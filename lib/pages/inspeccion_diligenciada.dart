import 'package:flutter/material.dart';
import 'package:izaje_carga/pages/inspeccion_page.dart';

class InspeccionDiligenciadaPage extends StatelessWidget {
  const InspeccionDiligenciadaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inspección"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Inspección diligenciada correctamente",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Botón volver al menú
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // volver al menú principal
              },
              child: const Text("Volver al menú"),
            ),

            const SizedBox(height: 20),

            // 🔹 Nuevo texto y botón para diligenciar otra inspección
            const Text(
              "¿Desea diligenciar otra inspección?",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a una nueva inspección con formulario en blanco
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InspeccionPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("Nueva inspección"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
