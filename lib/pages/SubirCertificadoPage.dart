import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Para File (móvil)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:izaje_carga/config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubirCertificadoPage extends StatefulWidget {
  const SubirCertificadoPage({super.key});

  @override
  State<SubirCertificadoPage> createState() => _SubirCertificadoPageState();
}

class _SubirCertificadoPageState extends State<SubirCertificadoPage> {
  final _formKey = GlobalKey<FormState>();

  // Variable para controlar la animación de carga
  bool _isLoading = false;

  String cedula = '';
  String organismo = '';
  DateTime? vigenteDesde;
  DateTime? vigenteHasta;
  String observaciones = '';
  String rol = '';
  PlatformFile? archivoPDF;

  // Controladores para poder limpiar los campos de texto explícitamente si es necesario
  // (Aunque form.reset() ayuda, a veces es mejor tener controladores para un reset total)
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _organismoController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  @override
  void dispose() {
    _cedulaController.dispose();
    _organismoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return "No seleccionada";
    return "${fecha.day}/${fecha.month}/${fecha.year}";
  }

  Future<void> _seleccionarPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        archivoPDF = result.files.single;
      });
    }
  }

  void _limpiarFormulario() {
    _formKey.currentState!.reset(); // Limpia visualmente los campos con validadores
    _cedulaController.clear();
    _organismoController.clear();
    _observacionesController.clear();

    setState(() {
      cedula = '';
      organismo = '';
      vigenteDesde = null;
      vigenteHasta = null;
      observaciones = '';
      rol = '';
      archivoPDF = null;
    });
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate() || archivoPDF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos y adjunta el PDF')),
      );
      return;
    }

    // Activar carga
    setState(() {
      _isLoading = true;
    });

    try {

      final uri = Uri.parse(Config.subirCertificadoUrl());
      final request = http.MultipartRequest("POST", uri);
      // --- CAMBIO AQUÍ ---
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      // Usamos los controladores o las variables, asegurando que tengan el valor
      request.fields['cedula'] = cedula;
      request.fields['organismo_acreditador'] = organismo;
      request.fields['vigente_desde'] = vigenteDesde!.toIso8601String();
      request.fields['vigente_hasta'] = vigenteHasta!.toIso8601String();
      request.fields['observaciones'] = observaciones;
      request.fields['rol'] = rol;

      if (kIsWeb) {
        final bytes = archivoPDF!.bytes!;
        request.files.add(http.MultipartFile.fromBytes(
          'archivo_pdf',
          bytes,
          filename: archivoPDF!.name,
          contentType: MediaType('application', 'pdf'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'archivo_pdf',
          archivoPDF!.path!,
          contentType: MediaType('application', 'pdf'),
        ));
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ÉXITO
        _limpiarFormulario(); // Dejar en blanco

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Certificado cargado'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // ERROR DEL SERVIDOR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al subir: $body')),
          );
        }
      }
    } catch (e) {
      // ERROR DE CONEXIÓN
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error de conexión: $e')),
        );
      }
    } finally {
      // Desactivar carga siempre, sea éxito o error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subir Certificado"),
        backgroundColor: Colors.blue.shade800,
      ),
      // Usamos un Stack para poner la animación de carga encima del formulario
      body: Stack(
        children: [
          // CAPA 1: El Formulario
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cedulaController,
                    decoration: const InputDecoration(labelText: 'Cédula'),
                    onChanged: (val) => cedula = val,
                    validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                  ),
                  TextFormField(
                    controller: _organismoController,
                    decoration: const InputDecoration(labelText: 'Organismo Acreditador'),
                    onChanged: (val) => organismo = val,
                    validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  // Fechas
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range, color: Colors.blue),
                      title: Text("Vigente desde: ${_formatearFecha(vigenteDesde)}"),
                      trailing: TextButton(
                        child: const Text("Seleccionar"),
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (fecha != null) {
                            setState(() {
                              vigenteDesde = fecha;
                              vigenteHasta = DateTime(fecha.year + 1, fecha.month, fecha.day);
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.date_range, color: Colors.red),
                      title: Text("Vigente hasta: ${_formatearFecha(vigenteHasta)}"),
                      trailing: TextButton(
                        child: const Text("Seleccionar"),
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: vigenteHasta ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (fecha != null) {
                            setState(() => vigenteHasta = fecha);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _observacionesController,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    onChanged: (val) => observaciones = val,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: rol.isEmpty ? null : rol,
                    decoration: const InputDecoration(
                      labelText: "Rol",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      "APAREJADOR",
                      "MONTACARGA",
                      "OPERADOR GRÚA STINGER",
                      "OPERADOR GRÚA BRAZO ARTICULADO",
                      "CARRO CANASTA",
                      "SUPERVISOR IZAJE"
                    ]
                        .map((opcion) => DropdownMenuItem(
                      value: opcion,
                      child: Text(opcion),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => rol = val ?? "");
                    },
                    validator: (val) =>
                    val == null || val.isEmpty ? "Seleccione un rol" : null,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _seleccionarPDF,
                    icon: const Icon(Icons.attach_file),
                    label: Text(archivoPDF == null
                        ? 'Adjuntar PDF'
                        : 'PDF seleccionado: ${archivoPDF!.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _enviarFormulario, // Deshabilitar si carga
                    icon: const Icon(Icons.upload),
                    label: const Text('Subir Certificado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CAPA 2: Animación de carga (Overlay)
          if (_isLoading)
            Container(
              color: Colors.black54, // Fondo semitransparente oscuro
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}