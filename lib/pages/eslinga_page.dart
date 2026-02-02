import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // Asegúrate que este archivo exista

class EslingaPage extends StatefulWidget {
  const EslingaPage({super.key});

  @override
  _EslingaPageState createState() => _EslingaPageState();
}

class _EslingaPageState extends State<EslingaPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _fechaCtrl = TextEditingController();

  // Variables del formulario
  String serial = "";
  String tipoEslinga = "Eslinga Sintética (Textiles)";
  String fabricante = "";
  String fechaFabricacion = "";
  String longitud = "";
  String ancho = "";
  String estadoEslinga = "CONFORME";

  bool isLoading = false;
  String mensaje = "";

  final List<String> tiposEslinga = [
    "Eslinga Sintética (Textiles)",
    "Eslinga de Cadena",
    "Eslinga de Cable de Acero (Estrobos)",
  ];

  @override
  void dispose() {
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarEslinga() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
      mensaje = "";
    });

    try {
      // 1. Obtener credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioString = prefs.getString('usuario');

      if (token == null || usuarioString == null) {
        throw Exception("Sesión expirada. Por favor inicie sesión nuevamente.");
      }

      final usuario = jsonDecode(usuarioString);
      final int usuarioId = usuario['idusuario'];

      // 2. Preparar datos
      final Map<String, dynamic> datos = {
        "serial": serial,
        "tipo_eslinga": tipoEslinga,
        "fabricante": fabricante,
        "fecha_fabricacion": fechaFabricacion,
        "longitud": longitud,
        "ancho": ancho,
        "estado_eslinga": estadoEslinga,
        "usuario_idusuario": usuarioId
      };

      // 3. Enviar Petición
      final response = await http.post(
        Uri.parse(Config.eslingasUrl()),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token" // <--- SEGURIDAD
        },
        body: jsonEncode(datos),
      );

      final respData = jsonDecode(response.body);

      setState(() {
        isLoading = false;
        mensaje = response.statusCode == 200 || response.statusCode == 201
            ? "✅ ${respData['mensaje'] ?? 'Eslinga creada exitosamente'}"
            : "❌ ${respData['mensaje'] ?? 'Error al crear eslinga'}";
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _formKey.currentState!.reset();
        _fechaCtrl.clear();
        // Opcional: regresar al menú
        // Future.delayed(Duration(seconds: 1), () => Navigator.pop(context));
      }

    } catch (e) {
      setState(() {
        isLoading = false;
        mensaje = "❌ Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Eslinga"), backgroundColor: Colors.blue[900]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Serial", prefixIcon: Icon(Icons.qr_code), border: OutlineInputBorder()),
                onSaved: (v) => serial = v!,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: tipoEslinga,
                decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
                items: tiposEslinga.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => tipoEslinga = v.toString()),
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: "Fabricante", prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                onSaved: (v) => fabricante = v!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _fechaCtrl,
                decoration: const InputDecoration(labelText: "Fecha Fabricación", prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
                  if(picked != null) {
                    final f = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
                    _fechaCtrl.text = f;
                    fechaFabricacion = f;
                  }
                },
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "Longitud (m)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => longitud = v!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: "Ancho (mm)", border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (v) => ancho = v!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                value: estadoEslinga,
                decoration: const InputDecoration(labelText: "Estado Inicial", border: OutlineInputBorder()),
                items: ["CONFORME", "NO CONFORME"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => estadoEslinga = v.toString()),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _guardarEslinga,
                  icon: isLoading ? Container() : const Icon(Icons.save),
                  label: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Guardar Eslinga"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                ),
              ),
              if (mensaje.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(mensaje, style: TextStyle(color: mensaje.startsWith("✅") ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
      ),
    );
  }
}