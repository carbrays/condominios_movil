import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ExpensasScreen extends StatefulWidget {
  const ExpensasScreen({super.key});

  @override
  State<ExpensasScreen> createState() => _ExpensasScreenState();
}

class _ExpensasScreenState extends State<ExpensasScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _expensas = [];
  List<dynamic> _cuentasQr = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinanzas();
  }

  Future<void> _loadFinanzas() async {
    setState(() => _isLoading = true);
    try {
      final resExp = await _api.get('/finanzas/expensas');
      final resCuentas = await _api.get('/pagos/cuentas');
      if (mounted) {
        setState(() {
          _expensas = resExp['items'] as List? ?? [];
          _cuentasQr = resCuentas as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoPago(Map<String, dynamic> expensa) {
    final montoController = TextEditingController(text: expensa['saldo_pendiente'].toString());
    final refController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pagar Expensa: ${expensa['periodo']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_cuentasQr.isNotEmpty) ...[
                const Text('Escanee el QR o transfiera a:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${_cuentasQr[0]['banco']} • Cta: ${_cuentasQr[0]['numero_cuenta']}'),
                const SizedBox(height: 8),
                Container(
                  height: 140,
                  width: 140,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.qr_code_2, size: 100, color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: montoController,
                decoration: const InputDecoration(labelText: 'Monto a Pagar (Bs.)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refController,
                decoration: const InputDecoration(labelText: 'Nº Transacción / Referencia'),
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
                await _api.post('/pagos/subir', {
                  'unidad_id': expensa['unidad_id'],
                  'expensa_id': expensa['id'],
                  'monto': double.tryParse(montoController.text) ?? 100.0,
                  'fecha_pago': DateTime.now().toIso8601String().substring(0, 10),
                  'metodo_pago': 'QR_TRANSFERENCIA',
                  'referencia_transaccion': refController.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comprobante enviado para validación'), backgroundColor: Colors.green),
                );
                _loadFinanzas();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Confirmar Envío'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Expensas y Finanzas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFinanzas,
              child: _expensas.isEmpty
                  ? const Center(child: Text('No tiene expensas registradas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _expensas.length,
                      itemBuilder: (ctx, i) {
                        final e = _expensas[i];
                        final bool pagado = e['estado'] == 'PAGADO';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Periodo: ${e['periodo']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Chip(
                                      label: Text(e['estado'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: pagado ? Colors.green : (e['estado'] == 'EN_MORA' ? Colors.red : Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Unidad: ${e['unidad_codigo']} • Concepto: ${e['concepto_nombre'] ?? 'Expensa General'}'),
                                Text('Total: Bs. ${e['monto_total']} • Vencimiento: ${e['fecha_vencimiento']}'),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Saldo Pendiente: Bs. ${e['saldo_pendiente']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (!pagado)
                                      ElevatedButton.icon(
                                        onPressed: () => _mostrarDialogoPago(e),
                                        icon: const Icon(Icons.qr_code, size: 18),
                                        label: const Text('Pagar QR'),
                                        style: ElevatedButton.styleFrom(minimumSize: const Size(120, 38)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
