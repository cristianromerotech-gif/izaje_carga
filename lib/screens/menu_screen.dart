import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Importa tus páginas ORIGINALES
import '../pages/eslinga_page.dart';
import '../pages/inspeccion_page.dart';
import '../pages/SubirCertificadoPage.dart';
import '../pages/consulta_certificado_page.dart';
import 'login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String nombreUsuario = "Cargando...";
  String rolUsuario = "";

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  Future<void> cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioString = prefs.getString('usuario');
    if (usuarioString != null) {
      final usuario = jsonDecode(usuarioString);
      setState(() {
        nombreUsuario = usuario['nombre'];
        rolUsuario = usuario['rol'];
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra todo
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menú Principal"),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: logout)
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue[900],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bienvenido:", style: TextStyle(color: Colors.white70)),
                Text(nombreUsuario, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(rolUsuario, style: const TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              children: [
                botonMenu("Crear Eslinga", Icons.add, Colors.blue, const EslingaPage()),
                botonMenu("Inspección", Icons.check_circle, Colors.green, const InspeccionPage()),
                botonMenu("Subir Cert.", Icons.upload_file, Colors.orange, const SubirCertificadoPage()),
                botonMenu("Consultar", Icons.search, Colors.purple, const ConsultaCertificadosPage()),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget botonMenu(String titulo, IconData icono, Color color, Widget pagina) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => pagina)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 50, color: color),
            const SizedBox(height: 10),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}