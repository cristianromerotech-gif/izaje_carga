import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config.dart'; // Importa tu config

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String correo = '';
  String contrasena = '';
  bool isLoading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(Config.loginUrl()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": correo,
          "contrasena": contrasena
        }),
      );

      final data = jsonDecode(response.body);

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        // ✅ GUARDAR TOKEN Y USUARIO
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('usuario', jsonEncode(data['usuario']));

        // Ir al menú
        Navigator.pushReplacementNamed(context, '/menu');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? 'Error al ingresar'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión con el servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tu logo
                Image.asset('lib/assets/images/logo.jpg', height: 100),
                const SizedBox(height: 20),
                const Text("IZAJE PRO", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Correo", prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (val) => correo = val!,
                  validator: (val) => val!.isEmpty ? 'Ingrese correo' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                  obscureText: true,
                  onSaved: (val) => contrasena = val!,
                  validator: (val) => val!.isEmpty ? 'Ingrese contraseña' : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("INGRESAR", style: TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/registro'),
                  child: const Text("Registrarse"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}