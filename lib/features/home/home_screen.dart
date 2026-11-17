import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import '../conserjeria/porteria_screen.dart';
import '../expensas/expensas_screen.dart';
import '../reservas/reservas_screen.dart';
import '../incidencias/incidencias_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _authService;
  final ApiClient _api = ApiClient();

  String _role = 'COPROPIETARIO';
  int? _condoId;
  Map<String, dynamic>? _user;
  List<dynamic> _condos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(apiClient: _api);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final role = await _authService.getActiveRole();
    final condoId = await _authService.getActiveCondoId();
    final user = await _authService.getUserData();

    try {
      final condsRes = await _api.get('/auth/condominios');
      if (mounted) {
        setState(() {
          _condos = condsRes as List? ?? [];
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _role = role ?? 'COPROPIETARIO';
        _condoId = condoId;
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _cambiarCondominio(dynamic rawId) async {
    final id = int.tryParse(rawId.toString()) ?? (rawId as int);
    Navigator.pop(context); // Cerrar drawer
    setState(() => _isLoading = true);
    await _authService.seleccionarCondominio(id);
    await _loadSession();
  }

  void _generarPaseQRDialog() {
    final nombreController = TextEditingController();
    final docController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar Pase QR para Visitante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El conserje podrá escanear este código en la entrada:'),
            const SizedBox(height: 12),
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre del Visitante')),
            const SizedBox(height: 12),
            TextField(controller: docController, decoration: const InputDecoration(labelText: 'CI Visitante (Opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await _api.post('/conserjeria/qr/generar', {
                  'unidad_id': 1,
                  'nombre_visitante': nombreController.text,
                  'documento_visitante': docController.text,
                  'fecha_expiracion': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
                });

                showDialog(
                  context: context,
                  builder: (qrCtx) => AlertDialog(
                    title: const Text('Pase QR Generado'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Visitante: ${nombreController.text}'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: const Icon(Icons.qr_code_2, size: 160, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 12),
                        SelectableText('Código: ${res['codigo_seguro']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    actions: [
                      ElevatedButton(onPressed: () => Navigator.pop(qrCtx), child: const Text('Cerrar')),
                    ],
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Generar Pase'),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF1E3A8A),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${_user?['nombres'] ?? 'Residente'}!',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rol: $_role en Condominio Demo',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _generarPaseQRDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Crear Pase de Visita QR'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Servicios y Opciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              title: 'Mis Expensas',
              subtitle: 'Ver saldo y pagar con QR',
              icon: Icons.receipt_long_rounded,
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensasScreen())),
            ),
            _buildActionCard(
              title: 'Reservas',
              subtitle: 'Churrasquera y salón',
              icon: Icons.event_available,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservasScreen())),
            ),
            _buildActionCard(
              title: 'Incidencias',
              subtitle: 'Reportar averías',
              icon: Icons.report_problem_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidenciasScreen())),
            ),
            _buildActionCard(
              title: 'Pase QR Rápido',
              subtitle: 'Invitar visitas',
              icon: Icons.qr_code_scanner,
              color: Colors.indigo,
              onTap: _generarPaseQRDialog,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isConserje = _role == 'CONSERJE';

    return Scaffold(
      appBar: AppBar(
        title: Text(isConserje ? 'Conserjería / Portería' : 'Portal Residente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${_user?['nombres'] ?? ''} ${_user?['apellidos'] ?? ''}'),
              accountEmail: Text('CI: ${_user?['ci'] ?? ''} • Rol: $_role'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1E3A8A)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Mis Condominios:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ..._condos.map((c) => ListTile(
                  leading: const Icon(Icons.apartment),
                  title: Text(c['nombre'] ?? 'Condominio'),
                  subtitle: Text('Rol: ${c['rol_id']}'),
                  selected: c['id'] == _condoId,
                  trailing: c['id'] == _condoId ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  onTap: () => _cambiarCondominio(c['id'] as int),
                )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ],
        ),
      ),
      body: isConserje ? PorteriaScreen(condominioId: _condoId ?? 1) : _buildResidentDashboard(),
    );
  }
}
