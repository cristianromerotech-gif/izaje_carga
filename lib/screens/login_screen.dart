import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:izaje_carga/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String correo = '';
  String contrasena = '';
  String mensaje = '';
  bool isLoading = false;
  bool loginExitoso = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      mensaje = '';
      loginExitoso = false;
    });

    final url = Uri.parse(Config.loginUrl());
    final body = jsonEncode({'correo': correo, 'contrasena': contrasena});

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          mensaje = '✅ Login exitoso. Bienvenido ${data['usuario']['nombre']}';
          loginExitoso = true;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('usuario', jsonEncode(data['usuario']));

        Future.delayed(Duration(milliseconds: 800), () {
          Navigator.pushReplacementNamed(context, '/menu');
        });
      } else {
        setState(() {
          mensaje = data['mensaje'] ?? '❌ Correo o contraseña incorrectos';
          loginExitoso = false;
        });
      }
    } catch (e) {
      setState(() {
        mensaje = '❌ Error al conectar con el servidor';
        loginExitoso = false;
      });
      print(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blue.shade800),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800)),
                  child,
                ],
              ),
            ),
          ],
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                "Inicia sesión para continuar",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // 🔹 Campo correo
              buildCard(
                icon: Icons.email,
                label: "Correo",
                child: TextFormField(
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: 'Ingrese su correo'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => correo = val,
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Ingrese su correo' : null,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Campo contraseña
              buildCard(
                icon: Icons.lock,
                label: "Contraseña",
                child: TextFormField(
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: 'Ingrese su contraseña'),
                  obscureText: true,
                  onChanged: (val) => contrasena = val,
                  validator: (val) => val == null || val.isEmpty
                      ? 'Ingrese su contraseña'
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: isLoading ? null : login,
                icon: const Icon(Icons.login),
                label: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Text("Ingresar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),

              const SizedBox(height: 20),

              if (mensaje.isNotEmpty)
                Text(
                  mensaje,
                  style: TextStyle(
                      color: loginExitoso ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),

              const Spacer(),

              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/registro'),
                child: Text(
                  '¿No tienes cuenta? Regístrate aquí',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
