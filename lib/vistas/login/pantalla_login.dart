import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../cliente/pantalla_cliente.dart';
import '../matriz/pantalla_matriz.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false;

  // Instancias globales utilizando el SDK actualizado de Appwrite
  late Account _account;
  late Databases _databases;

  @override
  void initState() {
    super.initState();
    // Inicialización del cliente enlazado con tu proyecto industrial
    Client client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('6ad4567d00058e53668a');

    _account = Account(client);
    _databases = Databases(client);
  }
  // Función principal para autenticar usuarios en Appwrite
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      // 1. Validar las credenciales creando una sesión de correo en Appwrite
      await _account.createEmailPasswordSession(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Buscar el rol y jerarquía en la base de datos usando la API moderna de Tablas
     // REEMPLÁZALO EXACTAMENTE POR ESTE BLOQUE ESTÁNDAR:
// ignore: deprecated_member_use
final resultado = await _databases.listDocuments(

  databaseId: '6ad45ac6002253571a52',
  collectionId: 'usuarios', // Cambiado de tableId a collectionId
  queries: [
    Query.equal('correo', _emailController.text.trim()),
  ],
);

if (resultado.documents.isNotEmpty) { // Cambiado de rows a documents
  var userDoc = resultado.documents.first; // Cambiado de rows a documents
  String rol = userDoc.data['rol'] ?? 'cliente';


        if (!mounted) return;

        // 3. Redirigir al panel correspondiente según su nivel de jerarquía
        if (rol == 'matriz') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PantallaMatriz()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PantallaCliente()),
          );
        }
      } else {
        throw 'El perfil de usuario no tiene asignado un rol en la base de datos.';
      }
    } on AppwriteException catch (e) {
      String mensaje = 'Ocurrió un error al iniciar sesión.';
      if (e.code == 401 || e.type == 'user_invalid_credentials') {
        mensaje = 'El correo o la contraseña son incorrectos.';
      } else if (e.code == 404) {
        mensaje = 'No se pudo conectar con el servidor de base de datos.';
      }
      _mostrarAlerta(mensaje);
    } catch (e) {
      _mostrarAlerta(e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.domain, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Gestión Industrial',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Text(
                    'Acceso Centralizado Multi-Empresa',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Corporativo',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu correo';
                      if (!value.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      if (value.length < 6) return 'La contraseña debe tener mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _cargando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Ingresar al Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
