import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';


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
  
  String _prioridad = 'Media';
  bool _guardando = false;

  // Estados locales para la gestión de imágenes de móviles en Flutter Web
  XFile? _imagenSeleccionada;
  Uint8List? _bytesImagen;
  bool _subiendoImagen = false;

  // Credenciales e hilos de conexión de tus plataformas gratuitas
  final String _urlCrearVercel = 'https://sistema-gestion-industrial.vercel.app';
  // ignore: unused_field
  final String _cloudNameCloudinary = 'tu_cloud_name_real'; 
  final String _uploadPresetCloudinary = 'preset_industrial';
  // Función para abrir la galería o cámara del dispositivo móvil
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920, // Pre-renderizado básico del lado del cliente
        maxHeight: 1080,
      );

      if (imagen != null) {
        final bytes = await imagen.readAsBytes();
        setState(() {
          _imagenSeleccionada = imagen;
          _bytesImagen = bytes;
        });
      }
    } catch (e) {
      _mostrarAlerta('Error al seleccionar la imagen: $e', Colors.redAccent);
    }
  }
  // Proceso para subir la foto a Cloudinary de forma asíncrona sin backend intermedio
  Future<String?> _subirACloudinary() async {
    if (_bytesImagen == null) return null;

    setState(() => _subiendoImagen = true);

    try {
      final url = Uri.parse('https://cloudinary.com');
      final peticion = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPresetCloudinary
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _bytesImagen!,
          filename: _imagenSeleccionada?.name ?? 'foto_movil.jpg',
        ));

      final respuestaStream = await peticion.send();
      final respuesta = await http.Response.fromStream(respuestaStream);

      if (respuesta.statusCode == 200) {
        final datosMapa = jsonDecode(respuesta.body);
        return datosMapa['secure_url']; // Nos retorna la URL ultra-ligera en la nube
      } else {
        throw 'Error en la respuesta del servidor de imágenes.';
      }
    } catch (e) {
      _mostrarAlerta('No se pudo optimizar la imagen en Cloudinary: $e', Colors.redAccent);
      return null;
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }
  // Función que unifica el texto y el enlace de imagen para guardarlo en Turso
  Future<void> _guardarRequerimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      String urlImagenFinal = '';

      // Si el usuario capturó una foto desde su móvil, la subimos primero
      if (_bytesImagen != null) {
        final urlSubida = await _subirACloudinary();
        if (urlSubida != null) {
          urlImagenFinal = urlSubida;
        }
      }

      
      String correoUsuarioActual = 'operario@empresa.com';
      String idUnicoRequerimiento = const Uuid().v4();

      final respuesta = await http.post(
        Uri.parse(_urlCrearVercel),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': idUnicoRequerimiento,
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'prioridad': _prioridad,
          'correo_cliente': correoUsuarioActual,
          'url_imagen': urlImagenFinal,
        }),
      );

      final datosRespuesta = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 201 && datosRespuesta['success'] == true) {
        if (!mounted) return;
        _mostrarAlerta('Requerimiento industrial registrado con éxito en la base de datos.', Colors.green);
        Navigator.pop(context);
      } else {
        throw datosRespuesta['error'] ?? 'Fallo interno al registrar en Turso.';
      }
    } catch (e) {
      _mostrarAlerta('Error al guardar: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarAlerta(String mensaje, Color colorFondo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: colorFondo),
    );
  }
  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Requerimiento Industrial'),
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
                      labelText: 'Descripción detallada del trabajo o falla',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // COMPONENTE MULTIMEDIA DE SENIOR: Reemplaza a Google Drive Manual
                  Card(
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          if (_bytesImagen != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Image.memory(_bytesImagen!, height: 150, fit: BoxFit.cover),
                            ),
                          ElevatedButton.icon(
                            onPressed: _guardando || _subiendoImagen ? null : _seleccionarImagen,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(_bytesImagen == null ? 'Capturar Imagen de Móvil' : 'Cambiar Imagen'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _guardando || _subiendoImagen ? null : _guardarRequerimiento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: (_guardando || _subiendoImagen)
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar Solicitud a Matriz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
