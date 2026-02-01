import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:izaje_carga/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:izaje_carga/pages/inspeccion_diligenciada.dart';

class InspeccionPage extends StatefulWidget {
  const InspeccionPage({super.key});

  @override
  State<InspeccionPage> createState() => _InspeccionPageState();
}

class _InspeccionPageState extends State<InspeccionPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController fechaController = TextEditingController();
  String? zonaSeleccionada;

  String mensaje = "";
  bool cargandoEslingas = true;

  List<Map<String, dynamic>> eslingas = [];
  int? eslingaSeleccionadaId;

  bool mostrarErrores = false;
  String? errorGeneral;

  // Control de paginación
  int currentPage = 0;

  // --- DEFINICIÓN DE LAS 4 PÁGINAS ---
  List<Widget> pages() {
    return [
      // ---------------------------------------
      // PÁGINA 0: Datos generales
      // ---------------------------------------
      Column(
        children: [
          const SizedBox(height: 10),
          const Text("Datos Generales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 15),

          // Serial eslinga
          DropdownButtonFormField<int>(
            value: eslingaSeleccionadaId,
            decoration: InputDecoration(
              labelText: "Serial eslinga",
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: eslingas.map((e) {
              final id = int.parse(e["iddato_tecnico_eslinga"].toString());
              return DropdownMenuItem<int>(
                value: id,
                child: Text(e["serial"].toString()),
              );
            }).toList(),
            onChanged: (v) {
              setState(() {
                eslingaSeleccionadaId = v;
                formData["dato_tecnico_eslinga_iddato_tecnico_eslinga"] = v;
              });
            },
            validator: (v) => v == null ? "Seleccione una eslinga" : null,
          ),

          const SizedBox(height: 12),

          // Fecha
          _styledDateInput(),

          // Zona de trabajo
          DropdownButtonFormField<String>(
            value: zonaSeleccionada,
            decoration: InputDecoration(
              labelText: "Zona de trabajo",
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: zonasTrabajo
                .map((zona) => DropdownMenuItem(
              value: zona,
              child: Text(zona),
            ))
                .toList(),
            onChanged: (v) {
              setState(() {
                zonaSeleccionada = v;
                formData["zona_trabajo"] = v;
              });
            },
            validator: (v) => v == null ? "Seleccione una zona de trabajo" : null,
          ),

          const SizedBox(height: 12),

          // Placa grúa
          _styledInput("Placa grúa", "placa_grua", icon: Icons.precision_manufacturing),

          // Cédula inspector
          _inputCedula(),
        ],
      ),

      // ---------------------------------------
      // PÁGINA 1: Primeras 6 preguntas
      // ---------------------------------------
      Column(
        children: [
          const SizedBox(height: 10),
          const Text("Inspección Visual (Parte 1)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),

          _preguntaCard(
            titulo: "1. La etiqueta cuenta con la información de la eslinga y es legible",
            keyForm: "pregunta_uno",
          ),
          _preguntaCard(
            titulo: "2. Deformidad por torceduras o distorsiones (jaula de pájaro)",
            keyForm: "pregunta_dos",
          ),
          _preguntaCard(
            titulo: "3. Daños por abrasión en la eslinga",
            keyForm: "pregunta_tres",
          ),
          _preguntaCard(
            titulo: "4. Decoloración excesiva, fibras frágiles o rigidez",
            keyForm: "pregunta_cuatro",
          ),
          _preguntaCard(
            titulo: "5. Rupturas en las fibras (por cortes o aplastamiento)",
            keyForm: "pregunta_cinco",
          ),
          _preguntaCard(
            titulo: "6. Reducción en el diámetro de la eslinga (más de un 10%)",
            keyForm: "pregunta_seis",
          ),
        ],
      ),

      // ---------------------------------------
      // PÁGINA 2: Preguntas restantes (7-11)
      // ---------------------------------------
      Column(
        children: [
          const SizedBox(height: 10),
          const Text("Inspección Visual (Parte 2)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),

          _preguntaCard(
            titulo: "7. Fibras quemadas por abrasión en la eslinga",
            keyForm: "pregunta_siete",
          ),
          _preguntaCard(
            titulo: "8. Manchas por sustancias químicas",
            keyForm: "pregunta_ocho",
          ),
          _preguntaCard(
            titulo: "9. Existen salpicaduras de soldadura",
            keyForm: "pregunta_nueve",
          ),

          // Pregunta 10 con observación condicional
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "10. Se evidencia algún otro daño visible de la eslinga inspeccionada",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text("Sí"),
                    value: "Sí",
                    groupValue: formData["pregunta_diez"],
                    onChanged: (v) => setState(() => formData["pregunta_diez"] = v),
                  ),
                  RadioListTile<String>(
                    title: const Text("No"),
                    value: "No",
                    groupValue: formData["pregunta_diez"],
                    onChanged: (v) => setState(() => formData["pregunta_diez"] = v),
                  ),
                  if (formData["pregunta_diez"] == "Sí")
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Observaciones",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) {
                          if (formData["pregunta_diez"] == "Sí") {
                            if (v == null || v.isEmpty) return "Ingrese observaciones";
                          }
                          return null;
                        },
                        onChanged: (v) => formData["observacion"] = v,
                      ),
                    ),
                  if (formData["pregunta_diez"] == null || formData["pregunta_diez"] == "")
                    if (mostrarErrores)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          "Debe seleccionar una opción",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                ],
              ),
            ),
          ),

          _preguntaCard(
            titulo: "11. El resultado final del estado de la eslinga es",
            keyForm: "pregunta_once",
            opciones: ["Conforme", "No conforme"],
          ),
        ],
      ),

      // ---------------------------------------
      // PÁGINA 3: Fotos y Botón Enviar
      // ---------------------------------------
      Column(
        children: [
          const SizedBox(height: 10),
          const Text("Evidencia Fotográfica", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),

          // Fotos
          _fotoInput("foto_uno"),
          _fotoInput("foto_dos"),
          _fotoInput("foto_tres"),
          _fotoInput("foto_cuatro"),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Botón enviar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : handleSubmit, // null deshabilita el botón visualmente también
              icon: const Icon(Icons.send),
              label: const Text("Enviar inspección"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          if (mensaje.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
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
    ];
  }

  // Lógica de validación por página
  bool validatePage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Datos generales
        if (eslingaSeleccionadaId == null) {
          setState(() => mensaje = "❌ Debe seleccionar una eslinga");
          return false;
        }
        if (formData["fecha"] == null || formData["fecha"].toString().isEmpty) {
          setState(() => mensaje = "❌ Debe seleccionar la fecha");
          return false;
        }
        if (zonaSeleccionada == null || zonaSeleccionada!.isEmpty) {
          setState(() => mensaje = "❌ Debe seleccionar una zona de trabajo");
          return false;
        }
        if (formData["placa_grua"].toString().isEmpty) {
          setState(() => mensaje = "❌ Debe ingresar la placa de la grúa");
          return false;
        }
        if (formData["cedula_inspector"].toString().isEmpty) {
          setState(() => mensaje = "❌ Debe ingresar la cédula del inspector");
          return false;
        }
        break;

      case 1: // Primeras 6 preguntas
        List<String> preguntasP1 = [
          "pregunta_uno", "pregunta_dos", "pregunta_tres",
          "pregunta_cuatro", "pregunta_cinco", "pregunta_seis"
        ];
        for (var k in preguntasP1) {
          if (formData[k] == null || formData[k] == "") {
            setState(() => mensaje = "❌ Debe responder las preguntas 1 a 6");
            return false;
          }
        }
        break;

      case 2: // Preguntas restantes (7-11)
        List<String> preguntasP2 = [
          "pregunta_siete", "pregunta_ocho", "pregunta_nueve",
          "pregunta_diez", "pregunta_once"
        ];

        for (var k in preguntasP2) {
          if (formData[k] == null || formData[k] == "") {
            setState(() => mensaje = "❌ Debe responder las preguntas 7 a 11");
            return false;
          }
        }
        if (formData["pregunta_diez"] == "Sí" &&
            (formData["observacion"] == null || formData["observacion"].toString().isEmpty)) {
          setState(() => mensaje = "❌ Falta observación en pregunta 10");
          return false;
        }
        break;
    }
    return true;
  }

  final List<String> zonasTrabajo = [
    "Barrancabermeja",
    "Bucaramanga",
    "San Gil",
    "Barbosa",
    "Málaga",
  ];

  final Map<String, dynamic> formData = {
    "dato_tecnico_eslinga_iddato_tecnico_eslinga": null,
    "fecha": "",
    "zona_trabajo": "",
    "placa_grua": "",
    "usuario_realiza_inspeccion": null,
    "pregunta_uno": "",
    "pregunta_dos": "",
    "pregunta_tres": "",
    "pregunta_cuatro": "",
    "pregunta_cinco": "",
    "pregunta_seis": "",
    "pregunta_siete": "",
    "pregunta_ocho": "",
    "pregunta_nueve": "",
    "pregunta_diez": "",
    "pregunta_once": "",
    "observacion": "",
    "cedula_inspector": "",
    "foto_uno": null,
    "foto_dos": null,
    "foto_tres": null,
    "foto_cuatro": null,
  };

  @override
  void initState() {
    super.initState();
    cargarEslingas();
    cargarUsuario();
  }

  @override
  void dispose() {
    fechaController.dispose();
    super.dispose();
  }

  // ================= CARGAR ESLINGAS =================
  Future<void> cargarEslingas() async {
    try {
      final res = await http.get(Uri.parse(Config.eslingasUrl()));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          eslingas = data.cast<Map<String, dynamic>>();
          cargandoEslingas = false;
        });
      } else {
        throw Exception("Error al cargar eslingas");
      }
    } catch (e) {
      setState(() {
        mensaje = "❌ Error cargando eslingas\n$e";
        cargandoEslingas = false;
      });
    }
  }

  // ================= CARGAR USUARIO =================
  Future<void> cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      final Map<String, dynamic> usuario = jsonDecode(usuarioJson);
      final int idUsuario = usuario['idusuario'];
      setState(() {
        formData["usuario_realiza_inspeccion"] = idUsuario;
      });
    }
  }

  // ================= IMÁGENES =================
  Future<void> pickImage(String campo) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          formData[campo] = bytes;
        });
      } else {
        setState(() {
          formData[campo] = File(image.path);
        });
      }
    }
  }

  Widget mostrarImagen(String campo) {
    final data = formData[campo];
    if (data == null) return const SizedBox();

    if (kIsWeb && data is Uint8List) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(data, height: 140, fit: BoxFit.cover),
      );
    } else if (data is File) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(data, height: 140, fit: BoxFit.cover),
      );
    } else {
      return const SizedBox();
    }
  }

  // ================= POST INSPECCIÓN =================
  Future<bool> enviarInspeccion() async {
    try {
      final uri = Uri.parse(Config.inspeccionesUrl());
      final request = http.MultipartRequest("POST", uri);

      // Campos de texto
      formData.forEach((key, value) {
        if (!key.startsWith("foto") && value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      // Archivos
      for (final k in ["foto_uno", "foto_dos", "foto_tres", "foto_cuatro"]) {
        final file = formData[k];
        if (file != null) {
          if (kIsWeb && file is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(k, file, filename: "$k.jpg"),
            );
          } else if (file is File) {
            request.files.add(await http.MultipartFile.fromPath(k, file.path));
          }
        }
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          mensaje = "✅ Inspección enviada correctamente";
        });
        return true;
      } else {
        setState(() {
          mensaje = "❌ Error ${response.statusCode}\n$body";
        });
        return false;
      }
    } catch (e) {
      setState(() {
        mensaje = "❌ Error de conexión\n$e";
      });
      return false;
    }
  }

  // ================= SUBMIT =================
  bool isSubmitting = false;

  void handleSubmit() async {
    // Primero: Validaciones
    setState(() {
      mostrarErrores = true;
      errorGeneral = null;
      mensaje = "";
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => mensaje = "❌ Revise los campos obligatorios");
      return;
    }

    for (var k in formData.keys.where((k) => k.startsWith("pregunta"))) {
      if (formData[k] == null || formData[k] == "") {
        setState(() => mensaje = "❌ Falta responder preguntas");
        return;
      }
    }

    if (formData["pregunta_diez"] == "Sí") {
      final obs = formData["observacion"];
      if (obs == null || obs.toString().isEmpty) {
        setState(() => mensaje = "❌ Falta observación en pregunta 10");
        return;
      }
    }

    if (["foto_uno", "foto_dos", "foto_tres", "foto_cuatro"].any((k) => formData[k] == null)) {
      setState(() => mensaje = "❌ Faltan fotografías");
      return;
    }

    // Si pasa validaciones, activamos el Overlay de carga
    setState(() {
      isSubmitting = true;
    });

    // Enviar
    final bool ok = await enviarInspeccion();

    // Desactivamos el Overlay
    setState(() => isSubmitting = false);

    if (ok) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InspeccionDiligenciadaPage()),
      );
    }
  }

  // ================= Helpers UI =================
  Widget _styledInput(String label, String key, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Campo requerido" : null,
        onChanged: (v) => formData[key] = v,
      ),
    );
  }

  Widget _styledDateInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: fechaController,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Fecha",
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Seleccione fecha" : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            final f = picked.toIso8601String().split("T")[0];
            setState(() {
              fechaController.text = f;
              formData["fecha"] = f;
            });
          }
        },
      ),
    );
  }

  Widget _inputCedula() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: "Cédula del inspector",
          prefixIcon: Icon(Icons.badge),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.isEmpty) return "Campo requerido";
          if (v.length < 6) return "Cédula inválida";
          return null;
        },
        onChanged: (v) => formData["cedula_inspector"] = v,
      ),
    );
  }

  Widget _preguntaCard({
    required String titulo,
    required String keyForm,
    List<String>? opciones,
  }) {
    final opcionesFinal = opciones ?? ["Cumple", "No cumple", "No aplica"];
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...opcionesFinal.map((opcion) => RadioListTile<String>(
              title: Text(opcion),
              value: opcion,
              dense: true,
              contentPadding: EdgeInsets.zero,
              groupValue: formData[keyForm],
              onChanged: (v) => setState(() => formData[keyForm] = v),
            )),
            if (mostrarErrores && (formData[keyForm] == null || formData[keyForm] == ""))
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  "Debe seleccionar una opción",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fotoInput(String campo) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  "Tomar ${campo.replaceAll('_', ' ')}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => pickImage(campo),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Abrir cámara"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            mostrarImagen(campo),

            if (mostrarErrores && formData[campo] == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text("Debe tomar esta foto", style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI CON OVERLAY DE CARGA =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Inspección"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Stack(
        children: [
          // 1. CAPA INFERIOR: El contenido del formulario
          cargandoEslingas
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Contenido paginado con scroll
                  Expanded(
                    child: IndexedStack(
                      index: currentPage,
                      children: pages().map((page) => SingleChildScrollView(child: page)).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones de navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: (currentPage > 0 && !isSubmitting)
                            ? () => setState(() => currentPage--)
                            : null,
                        child: const Text("Atrás"),
                      ),

                      if (currentPage < pages().length - 1)
                        ElevatedButton(
                          onPressed: isSubmitting ? null : () {
                            setState(() => mostrarErrores = true);
                            final formOk = _formKey.currentState!.validate();

                            if (formOk && validatePage(currentPage)) {
                              setState(() {
                                mostrarErrores = false;
                                currentPage++;
                                mensaje = "";
                              });
                            }
                          },
                          child: const Text("Siguiente"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. CAPA SUPERIOR: Overlay de carga (Pantalla completa)
          if (isSubmitting)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.5), // Fondo semitransparente oscuro
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "Enviando inspección...",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Por favor espere",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}