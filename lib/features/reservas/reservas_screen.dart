import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _areas = [];
  List<dynamic> _misReservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final resAreas = await _api.get('/reservas/areas');
      final resReservas = await _api.get('/reservas');
      if (mounted) {
        setState(() {
          _areas = resAreas as List? ?? [];
          _misReservas = resReservas['items'] as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _solicitarReserva(Map<String, dynamic> area) {
    final fechaController = TextEditingController(text: DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10));
    final inicioController = TextEditingController(text: '14:00');
    final finController = TextEditingController(text: '18:00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reservar: ${area['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Capacidad: ${area['capacidad_maxima']} personas • Costo: Bs. ${area['costo_reserva']}'),
            const SizedBox(height: 12),
            TextField(controller: fechaController, decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)')),
            const SizedBox(height: 12),
            TextField(controller: inicioController, decoration: const InputDecoration(labelText: 'Hora Inicio (HH:MM)')),
            const SizedBox(height: 12),
            TextField(controller: finController, decoration: const InputDecoration(labelText: 'Hora Fin (HH:MM)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.post('/reservas', {
                  'area_comun_id': area['id'],
                  'unidad_id': 1, // Unidad por defecto
                  'fecha_reserva': fechaController.text,
                  'hora_inicio': inicioController.text,
                  'hora_fin': finController.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reserva confirmada con éxito'), backgroundColor: Colors.green),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Confirmar Reserva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Áreas Comunes y Reservas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Áreas Disponibles para Reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._areas.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF0D9488), child: Icon(Icons.deck, color: Colors.white)),
                        title: Text(a['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Horario: ${a['hora_inicio']} a ${a['hora_fin']} • Costo: Bs. ${a['costo_reserva']}'),
                        trailing: ElevatedButton(
                          onPressed: () => _solicitarReserva(a),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(80, 36)),
                          child: const Text('Reservar'),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                const Text('Historial de Reservas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_misReservas.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No hay reservas registradas')))
                else
                  ..._misReservas.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${r['area_nombre']} (${r['fecha_reserva']})'),
                          subtitle: Text('Horario: ${r['hora_inicio']} - ${r['hora_fin']} • Estado: ${r['estado']}'),
                          trailing: r['estado'] == 'CONFIRMADA'
                              ? TextButton(
                                  onPressed: () async {
                                    await _api.patch('/reservas/${r['id']}/cancelar', {'motivo': 'Cancelado por usuario'});
                                    _loadData();
                                  },
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                                )
                              : null,
                        ),
                      )),
              ],
            ),
    );
  }
}
