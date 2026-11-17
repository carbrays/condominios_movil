import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _incidencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidencias();
  }

  Future<void> _loadIncidencias() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/incidencias');
      if (mounted) {
        setState(() {
          _incidencias = res['items'] as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dialogoNuevaIncidencia() {
    final tituloController = TextEditingController();
    final descController = TextEditingController();
    final ubicacionController = TextEditingController();
    String categoria = 'FONTANERIA';
    String prioridad = 'MEDIA';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reportar Avería o Incidencia'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: tituloController, decoration: const InputDecoration(labelText: 'Título corto')),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Descripción detallada'), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: ubicacionController, decoration: const InputDecoration(labelText: 'Ubicación (ej. Pasillo Piso 2)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: const [
                    DropdownMenuItem(value: 'FONTANERIA', child: Text('Fontanería / Fugas')),
                    DropdownMenuItem(value: 'ELECTRICIDAD', child: Text('Electricidad')),
                    DropdownMenuItem(value: 'ASCENSOR', child: Text('Ascensor')),
                    DropdownMenuItem(value: 'LIMPIEZA', child: Text('Limpieza')),
                    DropdownMenuItem(value: 'SEGURIDAD', child: Text('Seguridad')),
                    DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                  ],
                  onChanged: (val) => setDialogState(() => categoria = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: prioridad,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: const [
                    DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                    DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                    DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                    DropdownMenuItem(value: 'URGENTE', child: Text('Urgente')),
                  ],
                  onChanged: (val) => setDialogState(() => prioridad = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.post('/incidencias', {
                    'titulo': tituloController.text,
                    'descripcion': descController.text,
                    'ubicacion': ubicacionController.text,
                    'categoria': categoria,
                    'prioridad': prioridad,
                    'unidad_id': 1,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incidencia enviada al equipo de administración'), backgroundColor: Colors.green),
                  );
                  _loadIncidencias();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de Incidencias')),
      floatingActionButton: FloatingActionButton(
        onPressed: _dialogoNuevaIncidencia,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_alert_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncidencias,
              child: _incidencias.isEmpty
                  ? const Center(child: Text('No hay incidencias reportadas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _incidencias.length,
                      itemBuilder: (ctx, i) {
                        final inc = _incidencias[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: inc['prioridad'] == 'URGENTE' ? Colors.red : Colors.orange,
                            ),
                            title: Text(inc['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Estado: ${inc['estado']} • Categoría: ${inc['categoria']}\n${inc['descripcion']}'),
                            trailing: Chip(
                              label: Text(inc['estado'], style: const TextStyle(fontSize: 10, color: Colors.white)),
                              backgroundColor: inc['estado'] == 'RESUELTO' ? Colors.green : Colors.blueGrey,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
