import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'formulario_requerimiento.dart';

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  
  final String _correoCliente = 'operario@empresa.com';
  
  // URL base de tu backend seguro en la capa free de Vercel para listar
  final String _apiUrlListar = 'https://vercel.app';

  // Future que controlará la carga de datos en el FutureBuilder
  late Future<List<dynamic>> _futureRequerimientos;

  @override
  void initState() {
    super.initState();
    _futureRequerimientos = _obtenerMisRequerimientos();
  }
  // Función optimizada de Senior para traer datos filtrados desde el servidor
  Future<List<dynamic>> _obtenerMisRequerimientos() async {
    try {
      final urlConFiltros = Uri.parse('$_apiUrlListar?rol=cliente&correo=$_correoCliente');
      final respuesta = await http.get(urlConFiltros);

      if (respuesta.statusCode == 200) {
        final datosMapa = jsonDecode(respuesta.body);
        if (datosMapa['success'] == true) {
          return datosMapa['datos'] as List<dynamic>;
        }
      }
      throw 'No se pudieron recuperar las solicitudes del servidor.';
    } catch (e) {
      throw 'Error de conexión: $e';
    }
  }

  // Función rápida para refrescar la lista haciendo scroll hacia abajo
  Future<void> _refrescarLista() async {
    setState(() {
      _futureRequerimientos = _obtenerMisRequerimientos();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Requerimientos Industriales'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refrescarLista,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarLista,
        child: FutureBuilder<List<dynamic>>(
          future: _futureRequerimientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tienes requerimientos registrados.'));
            }

            final listaRequerimientos = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listaRequerimientos.length,
              itemBuilder: (context, indice) {
                final item = listaRequerimientos[indice];
                final String urlFoto = item['url_imagen'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.build_circle,
                      color: item['prioridad'] == 'Alta' ? Colors.red : Colors.orange,
                    ),
                    title: Text(item['titulo'] ?? 'Sin Título', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Estado: ${item['estado'] ?? 'Pendiente'} - Área: ${item['ubicacion'] ?? 'N/A'}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Descripción:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(item['descripcion'] ?? 'Sin descripción detallada.'),
                            const SizedBox(height: 12),
                            if (item['comentario_matriz'] != null && item['comentario_matriz'].toString().isNotEmpty) ...[
                              Text('Respuesta de Matriz:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text(item['comentario_matriz'], style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 12),
                            ],
                            
                            // COMPONENTE MULTIMEDIA DE SENIOR: Lazy loading directo desde Cloudinary optimizado
                            if (urlFoto.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: 
                                  Image.network(
                                    urlFoto,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text('No se pudo cargar la evidencia visual.'),
                                  ),
                                ),
                              ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: () async {
          // Si regresa del formulario, refresca automáticamente la lista SQL
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormularioRequerimiento()),
          );
          _refrescarLista();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
