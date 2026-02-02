import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/menu_screen.dart';
import 'pages/eslinga_page.dart';
import 'pages/inspeccion_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Izaje App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // ===== INICIO EN LOGIN =====
      initialRoute: '/login',

      // ===== RUTAS =====
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/registro': (context) =>  RegistroUsuarioPage(),
        '/menu': (context) => MenuScreen(),
        '/eslinga': (context) => EslingaPage(),
        '/inspeccion': (context) => InspeccionPage(),
      },
    );
  }
}
