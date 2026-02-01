// lib/config.dart
class Config {
  // 1. CAMBIO DE PUERTO: Node.js suele usar el 3000.
  // Asegúrate de que tu IP sea la correcta.
  // static const String baseUrl = "http://10.0.2.2:3000"; // Android emulator
  static const String baseUrl = "http://127.0.0.1:3000"; // Web o local
  // static const String baseUrl = "http://TU_IP_PUBLICA:3000"; // Dispositivo físico

  // 2. RUTAS: Coinciden con tu app.js
  static String loginUrl() => "$baseUrl/api/auth";
  static String registroUrl() => "$baseUrl/api/usuarios";
  static String eslingasUrl() => "$baseUrl/api/eslingas";
  static String inspeccionesUrl() => "$baseUrl/api/inspecciones";

  // En el backend: router.get("/", obtenerCertificados) dentro de /api/certificados
  static String certificadoUrl(String cedula) => "$baseUrl/api/certificados?cedula=$cedula";

  // En el backend: router.post("/upload", ...) dentro de /api/certificados
  static String subirCertificadoUrl() => "$baseUrl/api/certificados/upload";
}