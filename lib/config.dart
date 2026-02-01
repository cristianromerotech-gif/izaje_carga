// config.dart
class Config {
  // Cambia aquí según el entorno
  //static const String baseUrl = "http://10.0.2.2:5000"; // Android emulator
  static const String baseUrl = "http://127.0.0.1:5000"; // Web o local
  //static const String baseUrl = "http://158.23.161.238:5000"; // VPS Azure
  //static const String baseUrl = "https://izajecargas.lat/api";
  static String loginUrl() => "$baseUrl/api/auth";
  static String registroUrl() => "$baseUrl/api/usuarios";
  static String eslingasUrl() => "$baseUrl/api/eslingas";
  static String inspeccionesUrl() => "$baseUrl/api/inspecciones";
  static String certificadoUrl(cedula) => "$baseUrl/api/certificados?cedula=$cedula";
  static String descargarCertificadoUrl(cedula) => "$baseUrl/api/certificado?cedula=$cedula";

}
