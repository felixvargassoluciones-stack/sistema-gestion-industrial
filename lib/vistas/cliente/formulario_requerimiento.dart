import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';

class FormularioRequerimiento extends StatefulWidget {
  const FormularioRequerimiento({super.key});

  @override
  State<FormularioRequerimiento> createState() => _FormularioRequerimientoState();
}

class _FormularioRequerimientoState extends State<FormularioRequerimiento> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _driveController = TextEditingController();
  
  String _prioridad = 'Media';
  bool _guardando = false;

  // Instancias para comunicarse de forma segura con Appwrite
  late Account _account;
  late TablesDB _databases;

  @override
  void initState() {
    super.initState();
    // Enlace idéntico al resto de tus componentes
    Client client = Client()
      ..setEndpoint('https://appwrite.io')
      ..setProject('6ad4567d00058e53668a');

    _account = Account(client);
    _databases = TablesDB(client);
  }
  // Función para guardar el requerimiento en la Base de Datos de Appwrite
  Future<void> _guardarRequerimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      // 1. Obtener la información del usuario autenticado en la sesión web
      final usuarioActual = await _account.get();

      // 2. Inyectar la nueva fila con los campos exactos mapeados en el servidor
      await _databases.createRow(
        databaseId: '6ad45ac6002253571a52', // ID de tu Base de Datos
        tableId: 'requerimientos',          // Tu tabla de soporte industrial
        rowId: ID.unique(),                 // Genera un identificador único aleatorio
        data: {
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'enlaceDrive': _driveController.text.trim(),
          'prioridad': _prioridad,
          'estado': 'Pendiente',
          'correo': usuarioActual.email,     // Identificador de cuenta asociada
          'comentarioMatriz': '',
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requerimiento enviado con éxito a la Matriz'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Regresar al panel anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _driveController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Requerimiento'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: InputDecoration(
                      labelText: 'Título del Soporte / Servicio',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: InputDecoration(
                      labelText: 'Nave / Área específica',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _prioridad,

                    decoration: InputDecoration(
                      labelText: 'Nivel de Prioridad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                      DropdownMenuItem(value: 'Media', child: Text('Media')),
                      DropdownMenuItem(value: 'Alta', child: Text('Alta (Crítico)')),
                    ],
                    onChanged: (val) => setState(() => _prioridad = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Descripción detallada del trabajo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _driveController,
                    decoration: InputDecoration(
                      labelText: 'Enlace de Google Drive (Imágenes / PDFs)',
                      prefixIcon: const Icon(Icons.link),
                      helperText: 'Pega la URL pública compartida con tus fotos o especificaciones.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardarRequerimiento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar Solicitud', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
