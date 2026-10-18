import 'package:flutter/material.dart';
import 'vistas/login/pantalla_login.dart';
import 'package:appwrite/appwrite.dart';

void main() {
  // 1. Asegurar que los componentes del navegador estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Appwrite con tus credenciales oficiales
  Client client = Client();
  client
    .setEndpoint('https://appwrite.io') // Servidor global de Appwrite
    .setProject('6ad4567d00058e53668a');          // Tu ID de Proyecto real

  // 3. Arrancar la aplicación
  runApp(const MiAppIndustrial());
}

class MiAppIndustrial extends StatelessWidget {
  const MiAppIndustrial({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión Industrial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // La aplicación arrancará siempre mostrando la pantalla de acceso
      home: const PantallaLogin(),
    );
  }
}

