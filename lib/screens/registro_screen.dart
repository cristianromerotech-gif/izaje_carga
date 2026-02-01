import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:izaje_carga/config.dart';

class RegistroUsuarioPage extends StatefulWidget {
  @override
  _RegistroUsuarioPageState createState() => _RegistroUsuarioPageState();
}

class _RegistroUsuarioPageState extends State<RegistroUsuarioPage> {
  final _formKey = GlobalKey<FormState>();

  // Datos del formulario
  Map<String, String> formData = {
    "correo": "",
    "nombre": "",
    "contrasena": "",
    "cedula": "",
    "celular": "",
    "direccion": "",
    "equipo": "",
    "area": "",
    "rol": ""
  };

  String mensaje = "";

  // Manejo del submit
  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      final res = await http.post(

        Uri.parse(Config.loginUrl()),
        headers: {"Content-Type": "application/json"},
        body: json.encode(formData),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          mensaje = "✅ Usuario creado con ID: ${data['idusuario']}";
          // Limpiar el formulario
          formData.updateAll((key, value) => "");
        });
        _formKey.currentState!.reset();
      } else {
        setState(() {
          mensaje = data['mensaje'] ?? "❌ Error al crear usuario";
        });
      }
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al conectar con el servidor";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear Usuario")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ...formData.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    initialValue: formData[key],
                    obscureText: key == "contrasena",
                    decoration: InputDecoration(
                      labelText: key[0].toUpperCase() + key.substring(1),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((key == "correo" || key == "nombre" || key == "contrasena") &&
                          (value == null || value.isEmpty)) {
                        return "Campo obligatorio";
                      }
                      return null;
                    },
                    onSaved: (value) {
                      formData[key] = value ?? "";
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: handleSubmit,
                child: Text("Crear Usuario"),
              ),
              SizedBox(height: 20),
              if (mensaje.isNotEmpty)
                Text(
                  mensaje,
                  style: TextStyle(
                    color: mensaje.startsWith("✅") ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
