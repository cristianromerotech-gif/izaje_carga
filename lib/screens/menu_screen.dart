import 'package:flutter/material.dart';
import 'package:izaje_carga/pages/SubirCertificadoPage.dart';
import 'package:izaje_carga/pages/consulta_certificado_page.dart' hide ConsultaCertificadosPage;
import '../pages/consulta_certificado_page.dart';
import '../pages/eslinga_page.dart';
import '../pages/inspeccion_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screens/login_screen.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String nombreUsuario = "";
  String rolUsuario = ""; // 👈 nuevo campo
  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      final usuario = jsonDecode(usuarioJson);
      setState(() {
        nombreUsuario = usuario['nombre'] ?? "";
        rolUsuario = usuario['rol'] ?? ""; // 👈 guardamos el rol
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Está seguro que desea cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (result == true) {
      _logout(context);
    }
  }

  Widget buildCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.jpg',
              height: 50, // ajusta tamaño según tu logo
            ),
            const SizedBox(width: 80),
            const Text("IZAJE PRO"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (nombreUsuario.isNotEmpty)
              Text(
                "👋 Bienvenido, $nombreUsuario",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 10),
            const Text(
              "¿Qué deseas hacer hoy?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // 🔹 Botones del menú
            buildCard(
              icon: Icons.add_circle,
              label: "Crear Eslinga",
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EslingaPage()),
                );
              },
            ),
            buildCard(
              icon: Icons.search,
              label: "Inspección Accesorio",
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InspeccionPage()),
                );
              },
            ),
            buildCard(
              icon: Icons.warning,
              label: "Reportar Daño de Eslinga",
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InspeccionPage()),
                );
              },
            ),
            buildCard(
              icon: Icons.engineering,
              label: "Certificación Trabajador",
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConsultaCertificadosPage(),
                  ),
                );
              },
            ),
            // 🔹 Botón solo visible para administradores
            if (rolUsuario == "administrador")
              buildCard(
                icon: Icons.upload_file,
                label: "Subir Certificado",
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SubirCertificadoPage()),
                  );  },
              ),
            //const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Cerrar sesión"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),


          ],
        ),
      ),
    );
  }
}
