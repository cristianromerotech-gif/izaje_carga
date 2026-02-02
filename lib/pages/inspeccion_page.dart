import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // flutter pub add image_picker
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class InspeccionPage extends StatefulWidget {
  const InspeccionPage({super.key});

  @override
  _InspeccionPageState createState() => _InspeccionPageState();
}

class _InspeccionPageState extends State<InspeccionPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String mensaje = "";

  // Listas
  List<dynamic> eslingas = [];
  String? selectedSerial;
  int? selectedEslingaId;

  // Campos
  final TextEditingController _fechaCtrl = TextEditingController();
  final TextEditingController _placaCtrl = TextEditingController();
  final TextEditingController _observacionCtrl = TextEditingController();
  String zonaTrabajo = "BARRANCABERMEJA";

  // Respuestas Checklist
  Map<String, String> checklist = {
    'pregunta_uno': 'CUMPLE', 'pregunta_dos': 'CUMPLE', 'pregunta_tres': 'CUMPLE',
    'pregunta_cuatro': 'CUMPLE', 'pregunta_cinco': 'CUMPLE', 'pregunta_seis': 'CUMPLE',
    'pregunta_siete': 'CUMPLE', 'pregunta_ocho': 'CUMPLE', 'pregunta_nueve': 'CUMPLE',
    'pregunta_diez': 'CUMPLE'
  };

  // Fotos
  final ImagePicker _picker = ImagePicker();
  Map<String, File?> fotos = {'foto_uno': null, 'foto_dos': null, 'foto_tres': null, 'foto_cuatro': null};

  @override
  void initState() {
    super.initState();
    _fechaCtrl.text = DateTime.now().toString().split(' ')[0];
    cargarEslingas();
  }

  Future<void> cargarEslingas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if(token == null) return;

    try {
      final res = await http.get(
          Uri.parse(Config.eslingasUrl()),
          headers: {"Authorization": "Bearer $token"}
      );
      if (res.statusCode == 200) {
        setState(() => eslingas = jsonDecode(res.body));
      }
    } catch (e) {
      print("Error cargando eslingas: $e");
    }
  }

  Future<void> _tomarFoto(String key) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo != null) {
      setState(() => fotos[key] = File(photo.path));
    }
  }

  Future<void> enviarInspeccion() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedSerial == null) {
      setState(() => mensaje = "❌ Seleccione una eslinga");
      return;
    }

    setState(() { isLoading = true; mensaje = ""; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuario = jsonDecode(prefs.getString('usuario') ?? '{}');

      // Calculo automático del estado final
      bool aprobado = checklist.values.every((val) => val == 'CUMPLE' || val == 'NA');

      var request = http.MultipartRequest("POST", Uri.parse(Config.inspeccionesUrl()));
      request.headers['Authorization'] = 'Bearer $token';

      // Campos Texto
      request.fields['fecha'] = _fechaCtrl.text;
      request.fields['serial_eslinga'] = selectedSerial!;
      request.fields['zona_trabajo'] = zonaTrabajo;
      request.fields['placa_grua'] = _placaCtrl.text;
      request.fields['usuario_realiza_inspeccion'] = usuario['idusuario'].toString();
      request.fields['dato_tecnico_eslinga_iddato_tecnico_eslinga'] = selectedEslingaId.toString();
      request.fields['observacion'] = _observacionCtrl.text;
      request.fields['pregunta_once'] = aprobado ? "CONFORME" : "NO CONFORME"; // Resultado auto

      // Preguntas
      checklist.forEach((k, v) => request.fields[k] = v);

      // Archivos
      for (var entry in fotos.entries) {
        if (entry.value != null) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value!.path));
        }
      }

      var response = await request.send();
      final respStr = await response.stream.bytesToString();
      final respJson = jsonDecode(respStr);

      setState(() {
        isLoading = false;
        mensaje = response.statusCode == 200
            ? "✅ ${respJson['mensaje']}"
            : "❌ ${respJson['mensaje']}";
      });

      if(response.statusCode == 200) {
        // Opcional: Navegar atrás
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Inspección guardada"), backgroundColor: Colors.green));
      }

    } catch (e) {
      setState(() { isLoading = false; mensaje = "Error: $e"; });
    }
  }

  Widget _buildPregunta(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          DropdownButton<String>(
            value: checklist[key],
            items: ['CUMPLE', 'NO CUMPLE', 'NA'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: v=='NO CUMPLE'?Colors.red:Colors.black)))).toList(),
            onChanged: (val) => setState(() => checklist[key] = val!),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Inspección"), backgroundColor: Colors.blue[900]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField(
                decoration: const InputDecoration(labelText: "Seleccione Eslinga", border: OutlineInputBorder()),
                items: eslingas.map((e) => DropdownMenuItem(
                  value: e['serial'].toString(),
                  child: Text("${e['serial']} - ${e['tipo_eslinga']}"),
                  onTap: () => selectedEslingaId = e['iddato_tecnico_eslinga'],
                )).toList(),
                onChanged: (val) => setState(() => selectedSerial = val.toString()),
              ),
              const SizedBox(height: 15),
              TextFormField(controller: _fechaCtrl, decoration: const InputDecoration(labelText: "Fecha", border: OutlineInputBorder()), readOnly: true),
              const SizedBox(height: 10),
              TextFormField(controller: _placaCtrl, decoration: const InputDecoration(labelText: "Placa Grúa", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: zonaTrabajo,
                decoration: const InputDecoration(labelText: "Zona Trabajo", border: OutlineInputBorder()),
                items: ["BARRANCABERMEJA", "BUCARAMANGA", "CIMITARRA"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => zonaTrabajo = v.toString()),
              ),
              const Divider(height: 30),
              const Text("Lista de Verificación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              _buildPregunta('pregunta_uno', '1. Etiqueta legible'),
              _buildPregunta('pregunta_dos', '2. Deformidades'),
              _buildPregunta('pregunta_tres', '3. Abrasión'),
              _buildPregunta('pregunta_cuatro', '4. Quemaduras/Químicos'),
              _buildPregunta('pregunta_cinco', '5. Costuras/Fibras rotas'),
              // ... agrega las demás preguntas que necesites

              const Divider(),
              TextFormField(controller: _observacionCtrl, decoration: const InputDecoration(labelText: "Observaciones", border: OutlineInputBorder()), maxLines: 2),

              const SizedBox(height: 20),
              const Text("Evidencias Fotográficas", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: fotos.keys.map((k) => IconButton(
                  icon: Icon(Icons.camera_alt, color: fotos[k] != null ? Colors.green : Colors.grey, size: 30),
                  onPressed: () => _tomarFoto(k),
                )).toList(),
              ),

              const SizedBox(height: 20),
              if (mensaje.isNotEmpty) Text(mensaje, style: TextStyle(color: mensaje.startsWith("✅") ? Colors.green : Colors.red)),

              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: isLoading ? null : enviarInspeccion,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("GUARDAR INSPECCION"),
              ))
            ],
          ),
        ),
      ),
    );
  }
}