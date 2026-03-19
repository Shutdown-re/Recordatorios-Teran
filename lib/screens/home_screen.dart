import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/recordatorio.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/recordatorio_card.dart';
import '../widgets/welcome_card.dart';
import 'add_recordatorio_screen.dart';
import 'recordatorios_list_screen.dart';
import 'mapas_screen.dart';
import 'alarm_sound_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _contentAnimation;

  List<Recordatorio> _recordatorios = [];
  bool _isLoading = true;

  String _searchQuery = '';
  int _selectedFilter = 0; // 0: Todos, 1: Pendientes, 2: Próximos, 3: Vencidos

  final List<String> _filterOptions = [
    'Todos',
    'Pendientes',
    'Próximos',
    'Vencidos',
  ];

  // Map para rastrear timers de alarmas por ID de recordatorio
  final Map<int, Timer> _alarmTimers = {};

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    _contentAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Iniciar animaciones
    _animationController.forward();

    // Cargar datos iniciales
    _loadRecordatorios();

    // Obtener servicios
    final alarmService = context.read<AlarmService>();
    final notificationService = context.read<NotificationService>();

    // Registrar callback para cuando se dispara una alarma programada
    // La alarma nativa del teléfono (app Clock) se encarga de sonar
    alarmService.setAlarmFireCallback((cliente, equipo, fecha) {
      debugPrint('');
      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║ ⏰ ALARMA DISPARADA AUTOMÁTICAMENTE');
      debugPrint('║ Cliente: $cliente');
      debugPrint('║ Equipo: $equipo');
      debugPrint('╚════════════════════════════════════════╝');
      debugPrint('La alarma nativa del Reloj se encargará de sonar.');
    });

    // Registrar callback para acciones de notificación (snooze/dismiss)
    notificationService.setNotificationActionCallback((
      actionId,
      cliente,
      equipo,
      fecha,
    ) {
      debugPrint('');
      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║ 🔔 ACCIÓN DE NOTIFICACIÓN: $actionId');
      debugPrint('║ Cliente: $cliente');
      debugPrint('║ Equipo: $equipo');
      debugPrint('╚════════════════════════════════════════╝');

      if (actionId == 'snooze') {
        debugPrint('⏸️  Ejecutando posponer...');
        alarmService.posponderAlarma(cliente, equipo, fecha, null);
      } else if (actionId == 'dismiss') {
        debugPrint('✅ Ejecutando detener alarma...');
        alarmService.detenerAlarma();
      }
    });

    // Registrar callback para cuando se toque una alarma desde notificación
    notificationService.setAlarmTapCallback((cliente, equipo, fecha) {
      debugPrint('');
      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║ 📱 CALLBACK DE ALARMA DESDE NOTIFICACIÓN');
      debugPrint('║ Cliente: $cliente');
      debugPrint('║ Equipo: $equipo');
      debugPrint('╚════════════════════════════════════════╝');
      debugPrint('La alarma nativa del Reloj se encargará de sonar.');
    });

    // Verificar y programar alarmas de hoy
    Future.delayed(const Duration(milliseconds: 500), () {
      _verificarYProgramarAlarmas();
    });
  }

  // Verificar y programar alarmas de hoy
  Future<void> _verificarYProgramarAlarmas() async {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║ 🔍 VERIFICANDO ALARMAS DE HOY');
    debugPrint('╚════════════════════════════════════════╝');

    final alarmService = context.read<AlarmService>();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    // Recordatorios con alarma para hoy
    final recordatoriosHoy = _recordatorios.where((r) {
      final fecha = r.fechaProximoMantenimiento;
      final mismodia = DateTime(fecha.year, fecha.month, fecha.day);
      return mismodia == hoy && r.alarmaProgramada && !r.estaVencido();
    }).toList();

    debugPrint(
      '📋 Recordatorios encontrados para hoy: ${recordatoriosHoy.length}',
    );

    for (var recordatorio in recordatoriosHoy) {
      final horaAlarma = recordatorio.fechaProximoMantenimiento;

      // Si la hora de alarma ya pasó, saltar
      if (horaAlarma.isBefore(ahora)) {
        debugPrint('⏭️  Saltando: ${recordatorio.cliente} - hora ya pasó');
        continue;
      }

      final tiempoHasta = horaAlarma.difference(ahora);
      final segundos = tiempoHasta.inSeconds;

      debugPrint('📅 Recordatorio: ${recordatorio.cliente}');
      debugPrint('   Equipo: ${recordatorio.equipo}');
      debugPrint(
        '   Hora alarma: ${horaAlarma.hour}:${horaAlarma.minute.toString().padLeft(2, '0')}',
      );
      debugPrint(
        '   Tiempo hasta alarma: ${tiempoHasta.inMinutes}min ${tiempoHasta.inSeconds % 60}seg',
      );

      if (segundos > 0 && segundos < 86400) {
        // Menos de 24 horas
        // Programar timer para cuando llegue la hora
        final timer = Timer(Duration(seconds: segundos), () {
          // Verificar que el recordatorio aún existe antes de disparar
          Recordatorio? recordatorioAun;
          try {
            recordatorioAun = _recordatorios.firstWhere(
              (r) => r.id == recordatorio.id,
            );
          } catch (e) {
            recordatorioAun = null;
          }

          if (recordatorioAun == null) {
            debugPrint(
              '⏭️  Recordatorio ${recordatorio.cliente} fue eliminado, cancelando alarma',
            );
            return;
          }

          if (mounted) {
            debugPrint('');
            debugPrint('╔════════════════════════════════════════╗');
            debugPrint('║ ⏰ HORA DE LA ALARMA: ${recordatorio.cliente}');
            debugPrint('╚════════════════════════════════════════╝');

            // activarAlarmaInmediata() ejecutará el callback que abrirá
            // automáticamente FullScreenAlarmScreen
            alarmService.activarAlarmaInmediata(
              cliente: recordatorio.cliente,
              equipo: recordatorio.equipo,
              fecha: '${horaAlarma.day}/${horaAlarma.month}/${horaAlarma.year}',
              fechaAlarma: horaAlarma,
            );
          }
        });

        // Guardar referencia del timer para poder cancelarlo después
        _alarmTimers[recordatorio.id ?? 0] = timer;

        debugPrint('✅ Alarma programada en timer');
      }
    }

    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║ ✓ Verificación completada');
    debugPrint('╚════════════════════════════════════════╝');
    debugPrint('');
  }

  @override
  void dispose() {
    _animationController.dispose();

    // Cancelar todos los timers de alarmas
    for (final timer in _alarmTimers.values) {
      timer.cancel();
    }
    _alarmTimers.clear();

    // Limpiar callbacks cuando se cierra la pantalla
    final alarmService = context.read<AlarmService>();
    alarmService.clearAlarmFireCallback();

    final notificationService = context.read<NotificationService>();
    notificationService.clearAlarmTapCallback();
    notificationService.clearNotificationActionCallback();

    super.dispose();
  }

  Future<void> _loadRecordatorios() async {
    try {
      final storageService = context.read<StorageService>();
      final loadedRecordatorios = await storageService.getRecordatorios();

      // Cancelar timers de recordatorios que ya no existen
      final idsActuales = loadedRecordatorios.map((r) => r.id).toSet();
      for (final id in List.from(_alarmTimers.keys)) {
        if (!idsActuales.contains(id)) {
          _alarmTimers[id]?.cancel();
          _alarmTimers.remove(id);
          debugPrint('🗑️  Timer cancelado para recordatorio eliminado: $id');
        }
      }

      setState(() {
        _recordatorios = loadedRecordatorios;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando recordatorios: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadRecordatorios();
  }

  int get _pendientesCount =>
      _recordatorios.where((r) => !r.estaVencido()).length;
  int get _proximosCount =>
      _recordatorios.where((r) => r.esProximo() && !r.estaVencido()).length;
  int get _vencidosCount => _recordatorios.where((r) => r.estaVencido()).length;

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceColor, AppTheme.cardColor],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen del Día',
                style: AppTheme.heading3.copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.syncAlt, size: 16),
                onPressed: _refreshData,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  value: _pendientesCount,
                  label: 'Pendientes',
                  color: AppTheme.successColor,
                  icon: FontAwesomeIcons.calendarCheck,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: _proximosCount,
                  label: 'Próximos',
                  color: AppTheme.warningColor,
                  icon: FontAwesomeIcons.clock,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  value: _vencidosCount,
                  label: 'Vencidos',
                  color: AppTheme.errorColor,
                  icon: FontAwesomeIcons.exclamationTriangle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Formato mm:ss para el countdown
  String _formatSnoozeTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildSnoozeBanner() {
    final alarmService = context.read<AlarmService>();

    return ValueListenableBuilder<int>(
      valueListenable: alarmService.snoozeSecondsLeft,
      builder: (context, secondsLeft, _) {
        if (secondsLeft <= 0) return const SizedBox.shrink();

        final cliente = alarmService.snoozeCliente ?? '';
        final equipo = alarmService.snoozeEquipo ?? '';

        return Container(
          margin: const EdgeInsets.only(
            left: AppTheme.defaultPadding,
            right: AppTheme.defaultPadding,
            bottom: 16,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.upcomingColor.withOpacity(0.15),
                AppTheme.upcomingColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.upcomingColor.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.upcomingColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.upcomingColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.clock,
                      size: 16,
                      color: AppTheme.upcomingColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ALARMA POSPUESTA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.upcomingColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cliente,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.upcomingColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.upcomingColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _formatSnoozeTime(secondsLeft),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.upcomingColor,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              if (equipo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 42), // Align with text above
                    Icon(
                      FontAwesomeIcons.tools,
                      size: 11,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        equipo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      secondsLeft / (AlarmService.snoozeDurationMinutes * 60),
                  backgroundColor: AppTheme.surfaceColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.upcomingColor,
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sonará de nuevo en ${_formatSnoozeTime(secondsLeft)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      alarmService.detenerAlarma();
                    },
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Acciones Rápidas',
              style: AppTheme.heading3.copyWith(fontSize: 18),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildQuickActionCard(
                icon: FontAwesomeIcons.plusCircle,
                label: 'Nuevo Recordatorio',
                color: AppTheme.primaryColor,
                onTap: () => _navigateToAddRecordatorio(),
              ),
              _buildQuickActionCard(
                icon: FontAwesomeIcons.listAlt,
                label: 'Ver Todos',
                color: AppTheme.accentColor,
                onTap: () => _navigateToRecordatoriosList(),
              ),
              _buildQuickActionCard(
                icon: FontAwesomeIcons.mapMarkerAlt,
                label: 'Mapa',
                color: const Color(0xFF2196F3),
                onTap: () => _navigateToMapa(),
              ),
              _buildQuickActionCard(
                icon: FontAwesomeIcons.bell,
                label: 'Probar Alarma',
                color: const Color(0xFFFF9800),
                onTap: _probarAlarma,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReminders() {
    // Mostrar los próximos mantenimientos sin aplicar filtros actuales
    final upcoming = _recordatorios
        .where((r) => r.esProximo() && !r.estaVencido())
        .toList();

    if (upcoming.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.calendarPlus,
              color: AppTheme.textSecondaryColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay mantenimientos próximos',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega un nuevo recordatorio para comenzar',
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximos Mantenimientos',
                  style: AppTheme.heading3.copyWith(fontSize: 18),
                ),
                TextButton(
                  onPressed: _navigateToRecordatoriosList,
                  child: Text(
                    'Ver todos',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...upcoming.map((recordatorio) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecordatorioCard(
                recordatorio: recordatorio,
                compact: true,
                onTap: () => _showRecordatorioDetails(recordatorio),
                onEdit: () => _editRecordatorio(recordatorio),
                onAlarm: () => _toggleAlarma(recordatorio),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = _selectedFilter == index;
            final count = index == 0
                ? _recordatorios.length
                : index == 1
                ? _pendientesCount
                : index == 2
                ? _proximosCount
                : _vencidosCount;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.textSecondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = index;
                  });
                },
                backgroundColor: AppTheme.surfaceColor,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : AppTheme.textColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.borderColor,
                  ),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.defaultPadding,
        vertical: 8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.search,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Buscar cliente, equipo o ubicación...',
                hintStyle: TextStyle(color: AppTheme.textSecondaryColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: AppTheme.textColor, fontSize: 14),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(FontAwesomeIcons.times, size: 14),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              color: AppTheme.textSecondaryColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'Agenda Téran',
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.bell),
            onPressed: _showNotifications,
            color: AppTheme.primaryColor,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.cog),
            onPressed: _showSettings,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _contentAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _contentAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - _contentAnimation.value)),
              child: child,
            ),
          );
        },
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Tarjeta de bienvenida
                      WelcomeCard(
                        userName: 'Cutberto Terán Morales',
                        userRole: 'Técnico Especializado',
                        userCompany: 'Téran Mantenimientos',
                        pendingCount: _pendientesCount,
                        upcomingCount: _proximosCount,
                        totalCount: _recordatorios.length,
                        onProfileTap: _showProfile,
                      ),

                      const SizedBox(height: 24),

                      // Banner de snooze (cuenta atrás)
                      _buildSnoozeBanner(),

                      // Estadísticas
                      _buildStatistics(),

                      const SizedBox(height: 24),

                      // Barra de búsqueda
                      _buildSearchBar(),

                      const SizedBox(height: 16),

                      // Filtros
                      _buildFilterChips(),

                      const SizedBox(height: 24),

                      // Acciones rápidas
                      _buildQuickActions(),

                      const SizedBox(height: 24),

                      // Próximos recordatorios
                      _buildUpcomingReminders(),

                      const SizedBox(height: 80), // Espacio para FAB
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 50 * (1 - _fabAnimation.value)),
              child: child,
            ),
          );
        },
        child: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.secondaryColor,
          onPressed: _navigateToAddRecordatorio,
          elevation: 4,
          child: const Icon(FontAwesomeIcons.plus, size: 24),
        ),
      ),
    );
  }

  // Métodos de navegación y acciones

  void _navigateToAddRecordatorio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddRecordatorioScreen()),
    );

    if (result == true) {
      await _refreshData();

      // Verificar nuevas alarmas después de crear recordatorio
      await Future.delayed(const Duration(milliseconds: 300));
      await _verificarYProgramarAlarmas();
    }
  }

  void _navigateToRecordatoriosList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordatoriosListScreen()),
    );

    if (result == true) {
      await _refreshData();
    }
  }

  void _navigateToMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapasScreen()),
    );
  }

  void _showRecordatorioDetails(Recordatorio recordatorio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          '📋 Detalles del Mantenimiento',
          style: AppTheme.heading3.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('👤 Cliente:', recordatorio.cliente),
              _buildDetailRow('🔧 Equipo:', recordatorio.equipo),
              _buildDetailRow(
                '📞 Teléfono:',
                recordatorio.telefono.isNotEmpty
                    ? recordatorio.telefono
                    : 'No especificado',
              ),
              _buildDetailRow(
                '📧 Email:',
                recordatorio.email.isNotEmpty
                    ? recordatorio.email
                    : 'No especificado',
              ),
              _buildDetailRow(
                '📅 Fecha del servicio:',
                recordatorio.fechaServicioCompleta(),
              ),
              _buildDetailRow('⏰ Frecuencia:', recordatorio.frecuencia),
              _buildDetailRow(
                '📅 Próximo mantenimiento:',
                recordatorio.fechaProximoCompleta(),
              ),
              _buildDetailRow(
                '📍 Ubicación:',
                recordatorio.ubicacion.isNotEmpty
                    ? recordatorio.ubicacion
                    : 'No especificada',
              ),
              if (recordatorio.observaciones.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      '📝 Observaciones:',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recordatorio.observaciones,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editRecordatorio(recordatorio);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _editRecordatorio(Recordatorio recordatorio) async {
    // Aquí iría la navegación a la pantalla de edición
    // Por ahora mostramos un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando: ${recordatorio.cliente}'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _toggleAlarma(Recordatorio recordatorio) async {
    try {
      final alarmService = context.read<AlarmService>();

      if (recordatorio.alarmaProgramada) {
        await alarmService.cancelarAlarma(recordatorio);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarma cancelada para ${recordatorio.cliente}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else {
        await alarmService.programarAlarma(recordatorio);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alarma programada para ${recordatorio.cliente}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }

      await _refreshData();
    } catch (e) {
      debugPrint('Error al programar/cancelar alarma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al gestionar la alarma'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _probarAlarma() async {
    final alarmService = context.read<AlarmService>();
    final notificationService = context.read<NotificationService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          '🔔 Probar Alarma',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: const Text(
          'Se mostrará una alarma en pantalla completa en 3 segundos.\n\n'
          'Asegúrate de que el volumen esté alto.',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                final cliente = 'Cliente de Prueba';
                final equipo = 'Aire Acondicionado Split';
                final fecha = DateFormat('dd/MM/yyyy').format(DateTime.now());
                final ahora = DateTime.now();

                // Crear alarma nativa en la app Reloj del teléfono
                await alarmService.activarAlarmaInmediata(
                  cliente: cliente,
                  equipo: equipo,
                  fecha: fecha,
                  fechaAlarma: ahora,
                  esPrueba: true,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alarma de prueba creada en la app Reloj'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error probando alarma: $e');
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Error al probar la alarma'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Probar Ahora'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'Centro de Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No hay notificaciones pendientes',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings() async {
    // Obtener estado de permisos
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    final systemAlertStatus = await Permission.systemAlertWindow.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Sonido de alarma
              ListTile(
                title: const Text(
                  'Sonido de alarma',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Selecciona el sonido para las alarmas',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Icon(
                  Icons.speaker_phone,
                  color: AppTheme.primaryColor,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    this.context,
                    MaterialPageRoute(
                      builder: (context) => const AlarmSoundSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(color: Colors.white24),

              // SECCIÓN DE PERMISOS
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  '🔐 PERMISOS',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Permiso de Ubicación
              _buildPermissionTile(
                icon: Icons.location_on,
                title: 'Ubicación',
                subtitle: 'Acceso a ubicación GPS',
                status: locationStatus,
                onTap: () async {
                  await Permission.location.request();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white24),

              // Permiso de Notificaciones
              _buildPermissionTile(
                icon: Icons.notifications,
                title: 'Notificaciones',
                subtitle: 'Recibir alertas y recordatorios',
                status: notificationStatus,
                onTap: () async {
                  await Permission.notification.request();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white24),

              // Permiso de Alarmas Exactas
              _buildPermissionTile(
                icon: Icons.alarm,
                title: 'Alarmas Exactas',
                subtitle: 'Programar alarmas en horas específicas',
                status: alarmStatus,
                onTap: () async {
                  await Permission.scheduleExactAlarm.request();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white24),

              // Permiso de Mostrar sobre otras apps
              _buildPermissionTile(
                icon: Icons.layers,
                title: 'Mostrar sobre otras apps',
                subtitle: 'Las alarmas aparecerán sobre otras aplicaciones',
                status: systemAlertStatus,
                onTap: () async {
                  await Permission.systemAlertWindow.request();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    final isGranted = status.isGranted;
    final statusColor = isGranted ? Colors.green : Colors.red;
    final statusIcon = isGranted ? Icons.check_circle : Icons.cancel;

    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: Icon(statusIcon, color: statusColor, size: 24),
      onTap: onTap,
      tileColor: isGranted
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
    );
  }

  void _showProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil de Cutberto Terán Morales'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
