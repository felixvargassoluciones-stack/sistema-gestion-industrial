import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../login/pantalla_login.dart';

class PantallaMatriz extends StatefulWidget {
  const PantallaMatriz({super.key});

  @override
  State<PantallaMatriz> createState() => _PantallaMatrizState();
}

class _PantallaMatrizState extends State<PantallaMatriz> {
  final _comentarioControllers = <String, TextEditingController>{};
  
  // Instancias globales para conectar los servicios de Appwrite
  late Account _account;
  late TablesDB _databases;

  @override
  void initState() {
    super.initState();
    // Enlace idéntico con las credenciales de tu proyecto industrial
    Client client = Client()
      ..setEndpoint('https://appwrite.io')
      ..setProject('6ad4567d00058e53668a');

    _account = Account(client);
    _databases = TablesDB(client);
  }
  // Cierra la sesión activa destruyendo el token del navegador
  Future<void> _cerrarSesion() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Función para actualizar el estado y comentario del requerimiento en Appwrite
  Future<void> _actualizarRequerimiento(String rowId, String nuevoEstado) async {
    final comentario = _comentarioControllers[rowId]?.text.trim() ?? '';

    try {
      // Modifica la fila seleccionada usando la API moderna de Tablas
      await _databases.updateRow(
        databaseId: '6ad45ac6002253571a52',
        tableId: 'requerimientos',
        rowId: rowId,
        data: {
          'estado': nuevoEstado,
          'comentarioMatriz': comentario,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estatus actualizado a: $nuevoEstado'), backgroundColor: Colors.green),
      );
      // Fuerza el rediseño de la pantalla para refrescar el FutureBuilder
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Pendiente': return Colors.orange;
      case 'En Revisión': return Colors.blue;
      case 'Atendido': return Colors.green;
      case 'Rechazado': return Colors.red;
      default: return Colors.grey;
    }
  }
  @override
  void dispose() {
    for (var controller in _comentarioControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador Matriz'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      // Lectura global de todas las solicitudes del parque industrial
      body: FutureBuilder(
        future: _databases.listRows(
          databaseId: '6ad45ac6002253571a52',
          tableId: 'requerimientos',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data?.rows ?? [];

          if (rows.isEmpty) {
            return const Center(
              child: Text(
                'No hay requerimientos pendientes en el parque industrial.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final rowId = rows[index].$id;

              final data = rows[index].data;
              final titulo = data['titulo'] ?? 'Sin título';
              final ubicacion = data['ubicacion'] ?? 'No especificada';
              final prioridad = data['prioridad'] ?? 'Media';
              final estado = data['estado'] ?? 'Pendiente';
              final correo = data['correo'] ?? 'Anónimo';
              // Inicializar el controlador de texto para el comentario si no existe
              _comentarioControllers.putIfAbsent(rowId, () => TextEditingController(text: data['comentarioMatriz'] ?? ''));

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: Chip(
                    label: Text(estado, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: _obtenerColorEstado(estado),
                  ),
                  title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Solicita: $correo\nÁrea: $ubicacion | Prioridad: $prioridad'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Descripción detallada:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(data['descripcion'] ?? ''),
                          const SizedBox(height: 12),
                          if (data['enlaceDrive'] != null && data['enlaceDrive'].toString().isNotEmpty) ...[
                            const Text('Enlace a Evidencia / Planos (Google Drive):', style: TextStyle(fontWeight: FontWeight.bold)),
                            SelectableText(
                              data['enlaceDrive'],
                              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                            const SizedBox(height: 16),
                          ],
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text('Dictamen / Respuesta de la Matriz:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _comentarioControllers[rowId],
                            decoration: InputDecoration(
                              hintText: 'Escribe las instrucciones de seguridad, motivos de rechazo o comentarios...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Rechazar'),
                                onPressed: () => _actualizarRequerimiento(rowId, 'Rechazado'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                icon: const Icon(Icons.assignment_late),
                                label: const Text('En Revisión'),
                                onPressed: () => _actualizarRequerimiento(rowId, 'En Revisión'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Atender'),
                                onPressed: () => _actualizarRequerimiento(rowId, 'Atendido'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
