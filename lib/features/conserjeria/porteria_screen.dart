import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/offline/offline_sync_service.dart';

class PorteriaScreen extends StatefulWidget {
  final int condominioId;
  const PorteriaScreen({super.key, required this.condominioId});

  @override
  State<PorteriaScreen> createState() => _PorteriaScreenState();
}

class _PorteriaScreenState extends State<PorteriaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  late final OfflineSyncService _offlineSync;

  List<dynamic> _visitas = [];
  List<dynamic> _paquetes = [];
  bool _isLoading = false;
  bool _isOffline = false;
  int _pendingSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _offlineSync = OfflineSyncService(apiClient: _api);
    _loadData();
    _checkPendingSync();
  }

  Future<void> _checkPendingSync() async {
    final count = await _offlineSync.getPendingCount(widget.condominioId);
    if (mounted) {
      setState(() {
        _pendingSyncCount = count;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final resVisitas = await _api.get('/conserjeria/visitas?activas=true');
      final resPaquetes = await _api.get('/conserjeria/paqueteria?estado=RECIBIDO');
      if (mounted) {
        setState(() {
          _visitas = resVisitas['items'] as List? ?? [];
          _paquetes = resPaquetes['items'] as List? ?? [];
          _isOffline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronizando operaciones pendientes con el servidor...')),
    );
    final count = await _offlineSync.syncPending(widget.condominioId);
    await _checkPendingSync();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronización finalizada. $count registros actualizados.')),
      );
    }
  }

  Future<void> _registrarVisitaDialog() async {
    final docController = TextEditingController();
    final nombreController = TextEditingController();
    final unidadController = TextEditingController(text: '1'); // Unidad ID
    final placaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Ingreso de Visita'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: docController,
                decoration: const InputDecoration(labelText: 'Documento / CI Visita'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unidadController,
                decoration: const InputDecoration(labelText: 'ID Unidad Destino'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: placaController,
                decoration: const InputDecoration(labelText: 'Placa Vehículo (Opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'visitante_documento': docController.text,
                'visitante_nombre': nombreController.text,
                'unidad_id': int.tryParse(unidadController.text) ?? 1,
                'vehiculo_placa': placaController.text.isNotEmpty ? placaController.text : null,
                'fecha_entrada': DateTime.now().toIso8601String(),
              };

              Navigator.pop(ctx);

              // Guardar en cola offline (idempotente)
              await _offlineSync.enqueueOperation(
                tipo: 'REGISTRAR_VISITA',
                condominioId: widget.condominioId,
                payload: payload,
              );

              await _checkPendingSync();
              await _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isOffline ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isOffline ? Colors.red : Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOffline ? Icons.cloud_off : Icons.cloud_done,
            size: 14,
            color: _isOffline ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            _isOffline ? 'OFFLINE' : 'ONLINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _isOffline ? Colors.red[800] : Colors.green[800],
            ),
          ),
          if (_pendingSyncCount > 0) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 9,
              backgroundColor: Colors.amber[800],
              child: Text(
                '$_pendingSyncCount',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conserjería y Control de Acceso'),
        actions: [
          Center(child: _buildConnectivityBadge()),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar ahora',
            onPressed: _syncNow,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Visitas'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Paquetes'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear QR'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registrarVisitaDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar Entrada'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Visitas
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _visitas.isEmpty
                      ? const Center(child: Text('No hay visitas activas en el edificio'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _visitas.length,
                          itemBuilder: (ctx, i) {
                            final v = _visitas[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFDBEAFE),
                                  child: Icon(Icons.person, color: Color(0xFF1E3A8A)),
                                ),
                                title: Text(v['visitante_nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('CI: ${v['visitante_documento']} • Destino: ${v['unidad_codigo'] ?? 'Unidad'}'),
                                trailing: TextButton(
                                  onPressed: () async {
                                    await _api.patch('/conserjeria/visitas/${v['id']}/salida', {});
                                    _loadData();
                                  },
                                  child: const Text('Salida', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // 2. Paquetes
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _paquetes.isEmpty
                      ? const Center(child: Text('No hay paquetes pendientes de entrega'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _paquetes.length,
                          itemBuilder: (ctx, i) {
                            final p = _paquetes[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.markunread_mailbox, color: Colors.teal),
                                title: Text('Para: ${p['destinatario_nombre']}'),
                                subtitle: Text('Unidad: ${p['unidad_codigo']} • Remitente: ${p['remitente'] ?? 'N/A'}'),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    await _api.patch('/conserjeria/paqueteria/${p['id']}/entregar', {'entregado_a': 'Destinatario'});
                                    _loadData();
                                  },
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                                  child: const Text('Entregar'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // 3. Validador QR
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF1E3A8A)),
                      const SizedBox(height: 16),
                      const Text('Validación de Pase QR Temporal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Ingrese el código seguro del pase o escanee la cámara:', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Código seguro (Hexadecimal)',
                          prefixIcon: Icon(Icons.security),
                        ),
                        onSubmitted: (code) async {
                          try {
                            final res = await _api.post('/conserjeria/qr/validar', {'codigo_seguro': code.trim()});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Acceso Autorizado: ${res['mensaje']}'), backgroundColor: Colors.green),
                            );
                            _loadData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
