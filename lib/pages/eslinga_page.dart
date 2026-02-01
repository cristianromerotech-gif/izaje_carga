import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:izaje_carga/config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'inspeccion_page.dart';

class EslingaPage extends StatefulWidget {
  const EslingaPage({super.key});

  @override
  _EslingaPageState createState() => _EslingaPageState();
}

class _EslingaPageState extends State<EslingaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaController = TextEditingController();
  bool isLoading = false;

  Map<String, dynamic> formData = {
    "serial": "",
    "tipo_eslinga": "",
    "fabricante": "",
    "fecha_fabricacion": "",
    "longitud": "",
    "ancho": "",
    "estado_eslinga": "",
    "usuario_idusuario": null,
  };

  final List<String> tiposEslinga = [
    "Eslinga Sintética (Textiles)",
    "Eslinga de Cadena",
    "Eslinga de Cable de Acero (Estrobos)",
  ];

  String mensaje = "";
  bool eslingaCreada = false;

  @override
  void initState() {
    super.initState();
    _loadUsuario();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _loadUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? usuarioStr = prefs.getString('usuario');
    if (usuarioStr != null) {
      final usuario = jsonDecode(usuarioStr);
      setState(() {
        formData["usuario_idusuario"] = usuario['idusuario'];
      });
    }
  }

  Future<void> handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
      mensaje = "";
      eslingaCreada = false;
    });

    try {
      final res = await http.post(
        Uri.parse(Config.eslingasUrl()),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          mensaje = "✅ Eslinga creada correctamente";
          eslingaCreada = true;
        });
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          mensaje = data['mensaje'] ?? "❌ Error al crear eslinga";
        });
      }
    } catch (e) {
      setState(() {
        mensaje = "❌ Error al conectar con el servidor";
      });
    }

    setState(() => isLoading = false);
  }

  // ================= Helpers UI =================
  Widget _input({
    required String label,
    required String keyForm,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: (val) => (val == null || val.isEmpty) ? "Campo obligatorio" : null,
        onSaved: (val) => formData[keyForm] = val,
      ),
    );
  }

  Widget _dateInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fechaController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Fecha de fabricación",
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (val) => (val == null || val.isEmpty) ? "Seleccione una fecha" : null,
        onTap: () async {
          FocusScope.of(context).unfocus();
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            final f = picked.toIso8601String().split("T")[0];
            setState(() {
              _fechaController.text = f;
              formData["fecha_fabricacion"] = f;
            });
          }
        },
      ),
    );
  }

  Widget _dropdownTipoEslinga() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true, // ✅ evita overflow
        decoration: InputDecoration(
          labelText: "Tipo de eslinga",
          prefixIcon: const Icon(Icons.category),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: formData["tipo_eslinga"].isEmpty ? null : formData["tipo_eslinga"],
        items: tiposEslinga
            .map((tipo) => DropdownMenuItem<String>(value: tipo, child: Text(tipo)))
            .toList(),
        onChanged: (val) => setState(() => formData["tipo_eslinga"] = val ?? ""),
        validator: (val) => val == null || val.isEmpty ? "Seleccione el tipo de eslinga" : null,
      ),
    );
  }

  Widget _dropdownEstado() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Estado",
          prefixIcon: const Icon(Icons.verified),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        value: formData["estado_eslinga"].isEmpty ? null : formData["estado_eslinga"],
        items: const [
          DropdownMenuItem(value: "CONFORME", child: Text("CONFORME")),
          DropdownMenuItem(value: "NO CONFORME", child: Text("NO CONFORME")),
        ],
        onChanged: (val) => setState(() => formData["estado_eslinga"] = val ?? ""),
        validator: (val) => val == null || val.isEmpty ? "Seleccione un estado" : null,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Eslinga"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _input(
                    label: "Serial",
                    keyForm: "serial",
                    icon: Icons.qr_code,
                    hint: "Ej: SL-2026-0001",
                  ),
                  _dropdownTipoEslinga(),
                  _input(
                    label: "Fabricante",
                    keyForm: "fabricante",
                    icon: Icons.factory,
                  ),
                  _dateInput(),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          label: "Longitud (m)",
                          keyForm: "longitud",
                          icon: Icons.straighten,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _input(
                          label: "Ancho (mm)",
                          keyForm: "ancho",
                          icon: Icons.swap_horiz,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  _dropdownEstado(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : handleSubmit,
                      icon: isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: const Text("Crear Eslinga"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  if (eslingaCreada)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InspeccionPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_turned_in),
                          label: const Text("Ir a Inspección"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                    ),
                  if (mensaje.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Icon(
                            mensaje.startsWith("✅") ? Icons.check_circle : Icons.error,
                            color: mensaje.startsWith("✅") ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensaje,
                              style: TextStyle(
                                color: mensaje.startsWith("✅") ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
