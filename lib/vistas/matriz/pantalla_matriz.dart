import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PantallaMatriz extends StatefulWidget {
  const PantallaMatriz({super.key});

  @override
  State<PantallaMatriz> createState() => _PantallaMatrizState();
}

class _PantallaMatrizState extends State<PantallaMatriz> {
  // URLs de tus microservicios seguros en Vercel
  final String _urlListar = 'https://sistema-gestion-industrial.vercel.app';
  final String _urlActualizar = 'https://sistema-gestion-industrial.vercel.app';

  late Future<List<dynamic>> _futureTodosRequerimientos;
  final _comentarioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureTodosRequerimientos = _obtenerRequerimientosGlobales();
  }
  // Consulta general sin filtros para el perfil de administración central
  Future<List<dynamic>> _obtenerRequerimientosGlobales() async {
    try {
      final respuesta = await http.get(Uri.parse(_urlListar));
      if (respuesta.statusCode == 200) {
        final datosMapa = jsonDecode(respuesta.body);
        if (datosMapa['success'] == true) {
          return datosMapa['datos'] as List<dynamic>;
        }
      }
      throw 'Error al recuperar el inventario de solicitudes.';
    } catch (e) {
      throw 'Fallo de red: $e';
    }
  }

  // Envío seguro de resolución técnica hacia Vercel y Turso SQL
  Future<void> _actualizarEstatus(String id, String nuevoEstado) async {
    try {
      final respuesta = await http.post(
        Uri.parse(_urlActualizar),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'estado': nuevoEstado,
          'comentario_matiz': _comentarioController.text.trim(),
        }),
      );

      final datosRespuesta = jsonDecode(respuesta.body);

      if (respuesta.statusCode == 200 && datosRespuesta['success'] == true) {
        _comentarioController.clear();
        _mostrarAlerta('Registro actualizado con éxito en la base de datos.', Colors.green);
        _refrescarPanel();
      } else {
        throw datosRespuesta['error'] ?? 'No se pudo guardar la actualización.';
      }
    } catch (e) {
      _mostrarAlerta('Error operativo: $e', Colors.redAccent);
    }
  }

  void _refrescarPanel() {
    setState(() {
      _futureTodosRequerimientos = _obtenerRequerimientosGlobales();
    });
  }
  void _mostrarAlerta(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consola de Control Matriz (Soporte Industrial)'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.sync), onPressed: _refrescarPanel)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refrescarPanel(),
        child: FutureBuilder<List<dynamic>>(
          future: _futureTodosRequerimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No existen requerimientos en el sistema de gestión.'));
            }

            final requerimientos = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requerimientos.length,
              itemBuilder: (context, indice) {
                final item = requerimientos[indice];
                final String urlFoto = item['url_imagen'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: item['prioridad'] == 'Alta' ? Colors.red[100] : Colors.orange[100],
                      child: Icon(Icons.warning_amber_rounded, color: item['prioridad'] == 'Alta' ? Colors.red : Colors.orange),
                    ),
                    title: Text(item['titulo'] ?? 'Reporte sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('De: ${item['correo_cliente']} | Estado: ${item['estado']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Ubicación / Área: ${item['ubicacion']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Descripción del Problema:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(item['descripcion'] ?? 'Sin detalles adicionales.'),
                            const SizedBox(height: 12),
                            if (urlFoto.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    urlFoto,
                                    height: 250,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text('Evidencia fotográfica inaccesible.'),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (item['estado'] == 'Pendiente' || item['estado'] == 'En Revisión') ...[
                              TextFormField(
                                controller: _comentarioController,
                                decoration: InputDecoration(
                                  labelText: 'Dictamen Técnico / Comentario de Matriz',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _actualizarEstatus(item['id'], 'Rechazado'),
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _actualizarEstatus(item['id'], 'Atendido'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Marcar como Atendido'),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Text('Resolución de Matriz:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text(item['comentario_matriz'] ?? 'Sin comentarios registrados.', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
