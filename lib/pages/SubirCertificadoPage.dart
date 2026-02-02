import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // flutter pub add file_picker
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config.dart';

class SubirCertificadoPage extends StatefulWidget {
  const SubirCertificadoPage({super.key});

  @override
  _SubirCertificadoPageState createState() => _SubirCertificadoPageState();
}

class _SubirCertificadoPageState extends State<SubirCertificadoPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? pdfFile;

  // Datos
  String cedula = "";
  String organismo = "";
  String rol = "Operador";
  final TextEditingController _fechaDesde = TextEditingController();
  final TextEditingController _fechaHasta = TextEditingController();

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      setState(() => pdfFile = File(result.files.single.path!));
    }
  }

  Future<void> subir() async {
    if (!_formKey.currentState!.validate()) return;
    if (pdfFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione un PDF")));
      return;
    }
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest("POST", Uri.parse(Config.subirCertificadoUrl()));
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['cedula'] = cedula;
      request.fields['organismo_acreditador'] = organismo;
      request.fields['vigente_desde'] = _fechaDesde.text;
      request.fields['vigente_hasta'] = _fechaHasta.text;
      request.fields['rol'] = rol;
      request.fields['estado'] = "VIGENTE";

      request.files.add(await http.MultipartFile.fromPath('archivo_pdf', pdfFile!.path));

      var response = await request.send();

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Certificado Subido"), backgroundColor: Colors.green));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error al subir"), backgroundColor: Colors.red));
      }

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subir Certificado"), backgroundColor: Colors.blue[900]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Cédula Usuario", border: OutlineInputBorder()),
                onSaved: (v) => cedula = v!,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                decoration: const InputDecoration(labelText: "Organismo Acreditador", border: OutlineInputBorder()),
                onSaved: (v) => organismo = v!,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _fechaDesde,
                decoration: const InputDecoration(labelText: "Vigente Desde", icon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2030));
                  if(t!=null) _fechaDesde.text = t.toString().split(" ")[0];
                },
              ),
              TextFormField(
                controller: _fechaHasta,
                decoration: const InputDecoration(labelText: "Vigente Hasta", icon: Icon(Icons.calendar_today)),
                onTap: () async {
                  DateTime? t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2030));
                  if(t!=null) _fechaHasta.text = t.toString().split(" ")[0];
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                value: rol,
                items: ["Operador", "Aparejador", "Inspector"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => rol = v.toString()),
                decoration: const InputDecoration(labelText: "Rol Certificado"),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(pdfFile == null ? "Seleccionar PDF" : "PDF Seleccionado"),
                subtitle: pdfFile != null ? Text(pdfFile!.path.split('/').last) : null,
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onTap: pickFile,
                tileColor: Colors.grey[200],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : subir,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBIR CERTIFICADO"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}