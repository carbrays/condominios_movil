import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  // Paleta de diseño HabitaCondo
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _surfaceLow = Color(0xFFEFF4FF);
  static const Color _surfaceContainer = Color(0xFFE5EEFF);
  static const Color _surfaceHigh = Color(0xFFDCE9FF);
  static const Color _surfaceCard = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF001428);
  static const Color _primaryContainer = Color(0xFF0F2942);
  static const Color _secondary = Color(0xFF006C49);
  static const Color _secondaryContainer = Color(0xFF6CF8BB);
  static const Color _onSecondaryContainer = Color(0xFF005236);
  static const Color _onSurface = Color(0xFF0B1C30);
  static const Color _onSurfaceVariant = Color(0xFF43474D);
  static const Color _errorColor = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);

  final ApiClient _api = ApiClient();

  List<dynamic> _areas = [];
  List<dynamic> _misReservas = [];
  bool _isLoading = true;
  bool _showQrKey = false;
  bool _showRules = false;

  String _selectedCategory = 'todas';
  late DateTime _selectedDate;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now.add(const Duration(days: 1));
    _weekStart = DateTime(now.year, now.month, now.day);
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
          _misReservas = (resReservas is Map ? resReservas['items'] : null) as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar áreas: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _dayAbbr(int weekday) {
    const names = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return names[month - 1];
  }

  String _inferCategory(Map<String, dynamic> area) {
    final raw = (area['categoria'] ?? '').toString().toLowerCase();
    if (raw.isNotEmpty) return raw;
    final name = (area['nombre'] ?? '').toString().toLowerCase();
    if (name.contains('pádel') || name.contains('padel') || name.contains('gimnasio') || name.contains('cancha')) {
      return 'deportes';
    }
    if (name.contains('salón') || name.contains('salon') || name.contains('lounge') || name.contains('evento')) {
      return 'social';
    }
    return 'exteriores';
  }

  IconData _iconForArea(Map<String, dynamic> area) {
    final name = (area['nombre'] ?? '').toString().toLowerCase();
    if (name.contains('quincho') || name.contains('parrilla') || name.contains('churras')) {
      return Icons.outdoor_grill_outlined;
    }
    if (name.contains('pádel') || name.contains('padel') || name.contains('tenis')) {
      return Icons.sports_tennis_outlined;
    }
    if (name.contains('piscina') || name.contains('alberca')) {
      return Icons.pool_outlined;
    }
    if (name.contains('gimnasio') || name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center_outlined;
    }
    if (name.contains('salón') || name.contains('salon') || name.contains('evento')) {
      return Icons.celebration_outlined;
    }
    return Icons.deck_outlined;
  }

  List<dynamic> get _filteredAreas {
    if (_selectedCategory == 'todas') return _areas;
    return _areas.where((a) => _inferCategory(Map<String, dynamic>.from(a)) == _selectedCategory).toList();
  }

  Map<String, dynamic>? get _proximaReserva {
    for (final item in _misReservas) {
      final map = Map<String, dynamic>.from(item);
      if ((map['estado'] ?? '').toString().toUpperCase() == 'CONFIRMADA') {
        return map;
      }
    }
    return null;
  }

  int get _activeReservationsCount => _misReservas
      .where((r) => (r['estado'] ?? '').toString().toUpperCase() == 'CONFIRMADA')
      .length;

  Future<void> _confirmarCancelacion(Map<String, dynamic> reserva) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: _errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: _errorColor, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Cancelar reserva?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Liberarás el turno de ${reserva['area_nombre']} para el ${reserva['fecha_reserva']}. Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: _surfaceContainer,
                      foregroundColor: _primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Mantener', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _errorColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sí, cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.patch('/reservas/${reserva['id']}/cancelar', {
        'motivo': 'Cancelado por usuario',
      });
      if (mounted) {
        setState(() => _showQrKey = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada con éxito'),
            backgroundColor: _secondary,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _errorColor),
        );
      }
    }
  }

  void _solicitarReserva(Map<String, dynamic> area) {
    final fechaController = TextEditingController(text: _formatDateIso(_selectedDate));
    final inicioController = TextEditingController(text: '14:00');
    final finController = TextEditingController(text: '18:00');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3C6CE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForArea(area), color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area['nombre'] ?? 'Área Común',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Máx. ${area['capacidad_maxima']} pers. · Horario ${area['hora_inicio']} - ${area['hora_fin']}',
                          style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: fechaController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      fechaController.text = _formatDateIso(picked);
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Fecha de reserva',
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                  filled: true,
                  fillColor: _surfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inicioController,
                      decoration: InputDecoration(
                        labelText: 'Hora inicio',
                        hintText: '14:00',
                        prefixIcon: const Icon(Icons.schedule, size: 18),
                        filled: true,
                        fillColor: _surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: finController,
                      decoration: InputDecoration(
                        labelText: 'Hora fin',
                        hintText: '18:00',
                        prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
                        filled: true,
                        fillColor: _surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Costo de reserva',
                      style: TextStyle(fontSize: 13, color: _onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      (area['costo_reserva'] ?? 0) == 0 ? 'Sin costo' : 'Bs. ${area['costo_reserva']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await _api.post('/reservas', {
                              'area_comun_id': area['id'],
                              'unidad_id': 1,
                              'fecha_reserva': fechaController.text,
                              'hora_inicio': inicioController.text,
                              'hora_fin': finController.text,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reserva confirmada con éxito'),
                                  backgroundColor: _secondary,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: _errorColor),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Confirmar reserva', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxima = _proximaReserva;
    final filteredAreas = _filteredAreas;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HabitaCondo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primary),
            ),
            Text(
              'Áreas Comunes y Reservas',
              style: TextStyle(fontSize: 12, color: _onSurfaceVariant, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            tooltip: 'Actualizar',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              color: _primary,
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (proxima != null) ...[
                    _buildUpcomingHero(proxima),
                    const SizedBox(height: 24),
                  ],
                  _buildDateSelectorHeader(),
                  const SizedBox(height: 12),
                  _buildWeekStrip(),
                  const SizedBox(height: 16),
                  _buildCategoryFilterRow(),
                  const SizedBox(height: 16),
                  if (filteredAreas.isEmpty)
                    _buildEmptyState('No hay áreas disponibles en esta categoría.')
                  else
                    ...filteredAreas.map((a) => _buildAmenityCard(Map<String, dynamic>.from(a))),
                  const SizedBox(height: 16),
                  _buildRulesSection(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUpcomingHero(Map<String, dynamic> reserva) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mi Reserva Próxima',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary),
            ),
            Text(
              '$_activeReservationsCount de 2 activas',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.outdoor_grill_outlined, color: _primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva['area_nombre'] ?? 'Área Reservada',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: _secondary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${reserva['fecha_reserva']} · ${reserva['hora_inicio']} - ${reserva['hora_fin']}',
                                style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: _secondary),
                      const SizedBox(width: 4),
                      Text(
                        reserva['estado'] ?? 'CONFIRMADA',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(
                      'Unidad #${reserva['unidad_id'] ?? 1}',
                      style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                    ),
                    const Spacer(),
                    const Icon(Icons.pin_drop_outlined, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text(
                      reserva['ubicacion'] ?? 'Área Común',
                      style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => setState(() => _showQrKey = !_showQrKey),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                        label: Text(
                          _showQrKey ? 'Ocultar llave' : 'Ver llave digital',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 48,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _surfaceContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _confirmarCancelacion(reserva),
                      icon: const Icon(Icons.cancel_outlined, color: _errorColor, size: 20),
                      tooltip: 'Cancelar reserva',
                    ),
                  ),
                ],
              ),
              if (_showQrKey) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomPaint(
                          size: const Size(112, 112),
                          painter: _QrPatternPainter(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Acceso Cerradura Electrónica',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Válido para ${reserva['fecha_reserva']} · ${reserva['hora_inicio']}',
                        style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectorHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amenidades Disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primary),
              ),
              SizedBox(height: 2),
              Text(
                'Selecciona un día para consultar y apartar',
                style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: _surfaceContainer,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_left, size: 18, color: _primary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${_monthName(_weekStart.month)} ${_weekStart.year}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _primary),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.chevron_right, size: 18, color: _primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = _weekStart.add(Duration(days: index));
          final isSelected = _formatDateIso(day) == _formatDateIso(_selectedDate);
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? _primary : _surfaceCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: isSelected ? 0.14 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayAbbr(day.weekday),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFFD1E4FF) : _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = const [
      ('todas', 'Todas', Icons.apps_rounded),
      ('deportes', 'Deportes', Icons.fitness_center_rounded),
      ('social', 'Social', Icons.celebration_rounded),
      ('exteriores', 'Exteriores', Icons.deck_rounded),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, icon) = categories[i];
          final active = _selectedCategory == key;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? _primary : _surfaceCard,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: active ? Colors.white : _onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmenityCard(Map<String, dynamic> area) {
    final costo = area['costo_reserva'] ?? 0;
    final esGratis = costo == 0 || costo == 0.0 || costo.toString() == '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 112,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary, _primaryContainer],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Icon(
                    _iconForArea(area),
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            area['ubicacion'] ?? 'Área Común',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFD1E4FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            esGratis ? 'Sin costo' : 'Bs. $costo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: esGratis ? _secondaryContainer : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area['nombre'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Capacidad: ${area['capacidad_maxima']} personas',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFD1E4FF)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HORARIO HABILITADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${area['hora_inicio']} a ${area['hora_fin']} hrs',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _solicitarReserva(area),
                    icon: const Icon(Icons.event_available_rounded, size: 17),
                    label: const Text('Reservar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _showRules = !_showRules),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _secondaryContainer.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.policy_outlined, color: _secondary, size: 19),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reglamento de Áreas Comunes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary),
                        ),
                        Text(
                          'Límites de reserva y cancelación',
                          style: TextStyle(fontSize: 12, color: _onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showRules ? Icons.expand_less : Icons.expand_more,
                    color: _onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showRules)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Cada unidad puede mantener un máximo de 2 reservas activas simultáneas.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Cancelaciones: con al menos 12 horas de anticipación.'
                    '• Música: límite permitido hasta las 23:00 hrs en áreas exteriores.'
                    '• Invitados: registrar en portería antes del inicio del turno.',
                    style: TextStyle(fontSize: 12, color: _onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Reservas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _primary),
        ),
        const SizedBox(height: 10),
        if (_misReservas.isEmpty)
          _buildEmptyState('No hay reservas registradas.')
        else
          ..._misReservas.map((raw) {
            final r = Map<String, dynamic>.from(raw);
            final estado = (r['estado'] ?? '').toString().toUpperCase();
            final isConfirmed = estado == 'CONFIRMADA';
            final isCancelled = estado == 'CANCELADA';
            final stateColor = isConfirmed
                ? _secondary
                : (isCancelled ? _errorColor : _onSurfaceVariant);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surfaceCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['area_nombre']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r['fecha_reserva']} · ${r['hora_inicio']} - ${r['hora_fin']}',
                          style: const TextStyle(fontSize: 12, color: _onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estado,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: stateColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isConfirmed)
                    TextButton(
                      onPressed: () => _confirmarCancelacion(r),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: _errorColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: _onSurfaceVariant),
      ),
    );
  }
}

class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final navy = Paint()..color = const Color(0xFF001428);
    final emerald = Paint()..color = const Color(0xFF006C49);
    final white = Paint()..color = Colors.white;

    void finder(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 28, 28), const Radius.circular(4)),
        navy,
      );
      canvas.drawRect(Rect.fromLTWH(x + 5, y + 5, 18, 18), white);
      canvas.drawRect(Rect.fromLTWH(x + 9, y + 9, 10, 10), navy);
    }

    finder(6, 6);
    finder(size.width - 34, 6);
    finder(6, size.height - 34);

    final blocks = [
      Rect.fromLTWH(44, 10, 8, 8),
      Rect.fromLTWH(58, 18, 8, 8),
      Rect.fromLTWH(46, 30, 10, 10),
      Rect.fromLTWH(44, 46, 18, 18),
      Rect.fromLTWH(70, 48, 10, 10),
      Rect.fromLTWH(86, 48, 12, 8),
      Rect.fromLTWH(12, 48, 20, 8),
      Rect.fromLTWH(70, 66, 8, 16),
      Rect.fromLTWH(84, 76, 16, 8),
      Rect.fromLTWH(44, 78, 14, 14),
    ];

    for (var i = 0; i < blocks.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(blocks[i], const Radius.circular(2)),
        i == 0 || i == 3 || i == 8 ? emerald : navy,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
