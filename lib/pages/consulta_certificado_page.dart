import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:izaje_carga/config.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // solo se usa en web


class ConsultaCertificadosPage extends StatefulWidget {
  const ConsultaCertificadosPage({super.key});

  @override
  State<ConsultaCertificadosPage> createState() =>
      _ConsultaCertificadosPageState();
}

class _ConsultaCertificadosPageState extends State<ConsultaCertificadosPage> {
  final TextEditingController _cedulaController = TextEditingController();
  List<dynamic> certificados = [];
  bool isLoading = false;


// Función para descargar archivo
  Future<void> descargarCertificado(String idAsistencia) async {
    final url = Uri.parse("${Config.baseUrl}/certificados/certificado/$idAsistencia");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      if (kIsWeb) {
        // ✅ Caso navegador: forzar descarga
        final blob = html.Blob([bytes]);
        final urlBlob = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: urlBlob)
          ..setAttribute("download", "certificado_$idAsistencia.pdf")
          ..click();
        html.Url.revokeObjectUrl(urlBlob);
      } else {
        // ✅ Caso móvil/escritorio: guardar y abrir
        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/certificado_$idAsistencia.pdf");
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al descargar certificado")),
      );
    }
  }




  Future<void> buscarCertificados() async {
    final cedula = _cedulaController.text.trim();
    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Ingrese una cédula")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(Config.certificadoUrl(cedula));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          certificados = data;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al obtener certificados")));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error de conexión")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return fecha;
    }
  }

  Widget buildCertCard(Map<String, dynamic> cert) {
    final estado = cert['estado_calculado'];
    final esVigente = estado == "VIGENTE";

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nombre: ${cert['nombre']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Cédula: ${cert['cedula_certificado']}"),
            Text("Rol: ${cert['rol_certificado'] ?? cert['rol_usuario']}"),
            Text("Vigencia: ${formatFecha(cert['vigente_desde'])} - ${formatFecha(cert['vigente_hasta'])}"),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  esVigente ? Icons.check_circle : Icons.cancel,
                  color: esVigente ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  esVigente ? "Certificado vigente" : "No vigente",
                  style: TextStyle(
                    fontSize: 16,
                    color: esVigente ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => descargarCertificado(cert['id_asistencia'].toString()),
              icon: const Icon(Icons.download),
              label: const Text("Descargar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
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
        title: const Text("Certificación de Trabajador"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Número de cédula",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Ingrese número de cédula",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : buscarCertificados,
              icon: const Icon(Icons.search),
              label: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text("Consultar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: certificados.isEmpty
                  ? const Center(child: Text("No hay certificados para mostrar"))
                  : ListView.builder(
                itemCount: certificados.length,
                itemBuilder: (context, index) =>
                    buildCertCard(certificados[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
