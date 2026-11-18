import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Paleta de diseño arquitectónica (Material 3)
  static const Color _navyDark = Color(0xFF0F172A);
  static const Color _navyPrimary = Color(0xFF1E3A8A);
  static const Color _amberAccent = Color(0xFFD97706);
  static const Color _surfaceBg = Color(0xFFF8FAFC);
  static const Color _borderSubtle = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF64748B);

  late final AuthService _authService;
  final ApiClient _api = ApiClient();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  String get _activeCondoName {
    if (_condos.isEmpty) return 'Condominio Principal';
    final match = _condos.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['id'] == _condoId,
          orElse: () => _condos.first as Map<String, dynamic>,
        );
    return match['nombre']?.toString() ?? 'Condominio Principal';
  }

  String get _userInitials {
    final n = (_user?['nombres'] ?? '').toString().trim();
    final a = (_user?['apellidos'] ?? '').toString().trim();
    final first = n.isNotEmpty ? n[0].toUpperCase() : 'R';
    final second = a.isNotEmpty ? a[0].toUpperCase() : '';
    return '$first$second';
  }

  String get _formattedRole {
    switch (_role.toUpperCase()) {
      case 'CONSERJE':
        return 'Conserjería';
      case 'INQUILINO':
        return 'Inquilino';
      default:
        return 'Copropietario';
    }
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
    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Cerrar drawer
    }
    if (id == _condoId) return;

    setState(() => _isLoading = true);
    await _authService.seleccionarCondominio(id);
    await _loadSession();
  }

  void _generarPaseQRBottomSheet() {
    final nombreController = TextEditingController();
    final docController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int horasValidez = 12;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _navyPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: _navyPrimary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Pase de Visita',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _navyDark,
                            ),
                          ),
                          Text(
                            'El conserje escaneará este pase en portería',
                            style: TextStyle(fontSize: 13, color: _textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nombreController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del visitante' : null,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Visitante',
                    hintText: 'Ej. Carlos Mendoza',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: _surfaceBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: docController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Documento / CI (Opcional)',
                    hintText: 'Ej. 7845120 LP',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: _surfaceBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vigencia del pase',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navyDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [6, 12, 24].map((hrs) {
                    final selected = horasValidez == hrs;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: hrs == 24 ? 0 : 8),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              '$hrs horas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _navyDark,
                              ),
                            ),
                          ),
                          selected: selected,
                          selectedColor: _navyDark,
                          backgroundColor: _surfaceBg,
                          side: BorderSide(color: selected ? _navyDark : _borderSubtle),
                          showCheckmark: false,
                          onSelected: (_) => setSheetState(() => horasValidez = hrs),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isSubmitting = true);
                            try {
                              final res = await _api.post('/conserjeria/qr/generar', {
                                'unidad_id': 1,
                                'nombre_visitante': nombreController.text.trim(),
                                'documento_visitante': docController.text.trim(),
                                'fecha_expiracion': DateTime.now()
                                    .add(Duration(hours: horasValidez))
                                    .toIso8601String(),
                              });

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                _mostrarPaseGeneradoSheet(
                                  visitante: nombreController.text.trim(),
                                  codigo: res['codigo_seguro']?.toString() ?? 'N/D',
                                  horas: horasValidez,
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('No se pudo generar el pase: $e'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Generar Pase QR',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarPaseGeneradoSheet({
    required String visitante,
    required String codigo,
    required int horas,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (qrCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 36),
            const SizedBox(height: 8),
            const Text(
              'Pase QR Listo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _navyDark),
            ),
            const SizedBox(height: 4),
            Text(
              '$visitante · Válido por $horas horas',
              style: const TextStyle(fontSize: 14, color: _textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 170, color: _navyDark),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderSubtle),
                    ),
                    child: SelectableText(
                      codigo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1.4,
                        color: _navyPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado al portapapeles')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _borderSubtle),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18, color: _navyDark),
                    label: const Text('Copiar código', style: TextStyle(color: _navyDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(qrCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navyDark,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Listo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 160,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.05,
          children: List.generate(
            4,
            (_) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderSubtle),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentDashboard() {
    final nombre = (_user?['nombres'] ?? 'Residente').toString().split(' ').first;

    return RefreshIndicator(
      onRefresh: _loadSession,
      color: _navyPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Tarjeta Hero arquitectónica
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_navyDark, _navyPrimary],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _navyPrimary.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$_formattedRole · $_activeCondoName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_condos.length > 1)
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Cambiar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Hola, $nombre!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona tus visitas, expensas y áreas comunes desde un solo lugar.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _generarPaseQRBottomSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amberAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                      label: const Text(
                        'Crear Pase de Visita QR',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 26),

          const Text(
            'Servicios y Opciones',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _navyDark,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.02,
            children: [
              _buildActionCard(
                title: 'Mis Expensas',
                subtitle: 'Saldo y pago QR',
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFF16A34A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExpensasScreen()),
                ),
              ),
              _buildActionCard(
                title: 'Reservas',
                subtitle: 'Churrasquera y salón',
                icon: Icons.event_available_rounded,
                accentColor: const Color(0xFF0D9488),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReservasScreen()),
                ),
              ),
              _buildActionCard(
                title: 'Incidencias',
                subtitle: 'Reportar averías',
                icon: Icons.build_circle_outlined,
                accentColor: const Color(0xFFEA580C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IncidenciasScreen()),
                ),
              ),
              _buildActionCard(
                title: 'Pase Rápido',
                subtitle: 'Invitar visitantes',
                icon: Icons.qr_code_scanner_rounded,
                accentColor: _navyPrimary,
                onTap: _generarPaseQRBottomSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: _textMuted.withValues(alpha: 0.65),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: _navyDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final fullName = '${_user?['nombres'] ?? ''} ${_user?['apellidos'] ?? ''}'.trim();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _navyDark,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    child: Text(
                      _userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Residente' : fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'CI: ${_user?['ci'] ?? 'N/D'} · $_formattedRole',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Text(
                'Mis Condominios',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _condos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final c = _condos[index];
                  final bool isSelected = c['id'] == _condoId;

                  return InkWell(
                    onTap: () => _cambiarCondominio(c['id']),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _navyPrimary.withValues(alpha: 0.06) : _surfaceBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? _navyPrimary : _borderSubtle,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            color: isSelected ? _navyPrimary : _textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['nombre'] ?? 'Condominio',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? _navyPrimary : _navyDark,
                                  ),
                                ),
                                Text(
                                  'Rol: ${c['rol_id'] ?? _role}',
                                  style: const TextStyle(fontSize: 12, color: _textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: _navyPrimary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: _borderSubtle),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  await _authService.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isConserje = _role == 'CONSERJE';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _borderSubtle),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: _navyDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConserje ? 'Conserjería / Portería' : 'Portal Residente',
                style: const TextStyle(
                  color: _navyDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _activeCondoName,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: _navyDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No tienes notificaciones nuevas')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : (isConserje ? PorteriaScreen(condominioId: _condoId ?? 1) : _buildResidentDashboard()),
    );
  }
}
