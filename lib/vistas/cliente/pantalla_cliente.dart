import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../login/pantalla_login.dart';
import 'formulario_requerimiento.dart';

class PantallaCliente extends StatefulWidget {
  const PantallaCliente({super.key});

  @override
  State<PantallaCliente> createState() => _PantallaClienteState();
}

class _PantallaClienteState extends State<PantallaCliente> {
  late Account _account;
  late TablesDB _databases;
  bool _cargandoUsuario = true;
  String? _correoUsuario;

  @override
  void initState() {
    super.initState();
    // Conexión idéntica con tu proyecto industrial
    Client client = Client()
      ..setEndpoint('https://appwrite.io')
      ..setProject('6ad4567d00058e53668a');

    _account = Account(client);
    _databases = TablesDB(client);
    _obtenerDatosUsuario();
  }

  // Obtiene el perfil activo desde el servicio de cuentas de Appwrite
  Future<void> _obtenerDatosUsuario() async {
    try {
      final user = await _account.get();
      setState(() {
        _correoUsuario = user.email;
        _cargandoUsuario = false;
      });
    } catch (e) {
      setState(() {
        _cargandoUsuario = false;
      });
    }
  }
  // Cierra la sesión de forma segura destruyendo el token del navegador
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Empresa Cliente'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _cargandoUsuario
          ? const Center(child: CircularProgressIndicator())
          : _correoUsuario == null
              ? const Center(child: Text('Usuario no identificado'))
              : FutureBuilder(
                  // Consume la API moderna de tablas filtrando por el correo del cliente
                  future: _databases.listRows(
                    databaseId: '6ad45ac6002253571a52',
                    tableId: 'requerimientos',
                    queries: [
                      Query.equal('correo', _correoUsuario!),
                    ],
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
                          'No tienes requerimientos registrados.\n¡Crea uno nuevo abajo!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final data = rows[index].data;
                        final titulo = data['titulo'] ?? 'Sin título';
                        final ubicacion = data['ubicacion'] ?? 'No especificada';
                        final prioridad = data['prioridad'] ?? 'Media';
                        final estado = data['estado'] ?? 'Pendiente';
                        final comentario = data['comentarioMatriz'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ExpansionTile(
                            leading: Chip(
                              label: Text(estado, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: _obtenerColorEstado(estado),
                            ),
                            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Ubicación: $ubicacion | Prioridad: $prioridad'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Descripción del trabajo:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(data['descripcion'] ?? ''),
                                    const SizedBox(height: 12),
                                    if (data['enlaceDrive'] != null && data['enlaceDrive'].toString().isNotEmpty) ...[
                                      const Text('Documentación adjunta (Drive):', style: TextStyle(fontWeight: FontWeight.bold)),
                                      SelectableText(
                                        data['enlaceDrive'],
                                        style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (comentario.toString().isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Respuesta de la Matriz:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                            const SizedBox(height: 4),
                                            Text(comentario),
                                          ],
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormularioRequerimiento()),
          );
        },
        label: const Text('Nuevo Requerimiento'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
