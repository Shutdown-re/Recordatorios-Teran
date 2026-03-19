import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

import '../utils/theme.dart';
import '../utils/date_utils.dart' as date_util;

class AlarmaFullScreen extends StatefulWidget {
  final String cliente;
  final String equipo;
  final String fecha;
  final bool esPrueba;
  final bool puedeVibrar;
  final bool puedeSonar;

  const AlarmaFullScreen({
    super.key,
    required this.cliente,
    required this.equipo,
    required this.fecha,
    this.esPrueba = false,
    this.puedeVibrar = true,
    this.puedeSonar = true,
  });

  @override
  State<AlarmaFullScreen> createState() => _AlarmaFullScreenState();
}

class _AlarmaFullScreenState extends State<AlarmaFullScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<Color?> _colorAnimation;

  late Timer _alarmTimer;
  late Timer _vibrationTimer;
  int _elapsedSeconds = 0;
  bool _isSnoozed = false;
  bool _isDismissing = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingSound = false;

  // Patrón de vibración para alarma
  final List<int> _vibrationPattern = [0, 1000, 500, 1000, 500, 1000];

  // Sonido de alarma
  final String _alarmSound = 'assets/audio/alarma_urgente.mp3';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeAnimations();
    _startAlarm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _maintainWakeLock();
        break;
      case AppLifecycleState.resumed:
        // Cuando la app vuelve al primer plano
        _restartAlarmIfNeeded();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _initializeAnimations() {
    // Animación de pulso para fondo
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Animación de shake para botones
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: -10),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -10, end: 10),
            weight: 2,
          ),
          TweenSequenceItem(tween: Tween<double>(begin: 10, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Animación de color para fondo
    _colorAnimation = ColorTween(
      begin: AppTheme.errorColor.withOpacity(0.1),
      end: AppTheme.errorColor.withOpacity(0.3),
    ).animate(_animationController);
  }

  Future<void> _startAlarm() async {
    // Iniciar temporizador
    _startTimer();

    // Iniciar sonido si está habilitado
    if (widget.puedeSonar) {
      await _playAlarmSound();
    }

    // Iniciar vibración si está habilitada y disponible
    if (widget.puedeVibrar) {
      _startVibration();
    }

    // Forzar pantalla completa
    _setFullScreenFlags();
  }

  void _setFullScreenFlags() {
    // Configurar para mantener pantalla encendida
  }

  void _maintainWakeLock() {
    // Mantener app activa
  }

  void _restartAlarmIfNeeded() {
    // Si la alarma fue pausada, reanudar
    if (!_isSnoozed && !_isDismissing) {
      _startAlarm();
    }
  }

  Future<void> _playAlarmSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(_alarmSound));
      _isPlayingSound = true;
    } catch (e) {
      debugPrint('Error reproduciendo sonido de alarma: $e');
      // Fallback a tono del sistema
      _playFallbackSound();
    }
  }

  void _playFallbackSound() {
    // Aquí podrías implementar un sonido de fallback
    // Por ahora solo registramos el error
    debugPrint('Usando fallback para sonido de alarma');
  }

  void _startVibration() async {
    if (await Vibration.hasVibrator() == true) {
      _vibrationTimer = Timer.periodic(
        const Duration(milliseconds: 3500), // Duración total del patrón
        (timer) {
          Vibration.vibrate(pattern: _vibrationPattern);
        },
      );
    }
  }

  void _startTimer() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _snoozeAlarm() async {
    setState(() {
      _isSnoozed = true;
    });

    // Detener sonido y vibración temporalmente
    await _stopAlarmEffects();

    // Mostrar mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⏰ Alarma pospuesta por 5 minutos'),
        backgroundColor: AppTheme.warningColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Esperar 5 minutos y reactivar
    await Future.delayed(const Duration(minutes: 5));

    if (mounted) {
      setState(() {
        _isSnoozed = false;
      });
      await _startAlarm();
    }
  }

  Future<void> _dismissAlarm() async {
    setState(() {
      _isDismissing = true;
    });

    await _stopAlarmEffects();

    // Navegar de regreso
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _stopAlarmEffects() async {
    // Detener animaciones
    _animationController.stop();

    // Detener temporizadores
    _alarmTimer.cancel();
    _vibrationTimer.cancel();

    // Detener sonido
    if (_isPlayingSound) {
      await _audioPlayer.stop();
      _isPlayingSound = false;
    }

    // Detener vibración
    Vibration.cancel();
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildAlarmHeader() {
    return Column(
      children: [
        // Icono de alarma animado
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.errorColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.esPrueba
                        ? FontAwesomeIcons.bell
                        : FontAwesomeIcons.exclamationTriangle,
                    size: 60,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Título de la alarma
        Text(
          widget.esPrueba
              ? '🔔 PRUEBA DE ALARMA'
              : '🚨 ¡MANTENIMIENTO PENDIENTE!',
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtítulo
        Text(
          widget.esPrueba
              ? 'Esta es una prueba de alarma'
              : '¡Hoy es el día del mantenimiento!',
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAlarmInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del mantenimiento
          _buildInfoRow('📋 Cliente:', widget.cliente),
          const SizedBox(height: 12),
          _buildInfoRow('🔧 Equipo:', widget.equipo),
          const SizedBox(height: 12),
          _buildInfoRow('📅 Fecha programada:', widget.fecha),

          const SizedBox(height: 20),

          // Mensaje urgente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⏰ ¡Es hora del mantenimiento programado!\n'
                    '📞 Contacta al cliente para confirmar la visita.',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            icon: FontAwesomeIcons.clock,
            label: 'Tiempo activa',
            value: _formatElapsedTime(),
            color: AppTheme.warningColor,
          ),

          _buildStatusItem(
            icon: FontAwesomeIcons.bell,
            label: 'Estado',
            value: _isSnoozed ? 'Pos-puesta' : 'Activa',
            color: _isSnoozed
                ? AppTheme.textSecondaryColor
                : AppTheme.errorColor,
          ),

          _buildStatusItem(
            icon: FontAwesomeIcons.calendarDay,
            label: 'Fecha',
            value: date_util.DateUtils.formatDate(DateTime.now()),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: FontAwesomeIcons.bellSlash,
              label: 'Posponer',
              color: AppTheme.warningColor,
              onPressed: _snoozeAlarm,
              isLoading: _isSnoozed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: FontAwesomeIcons.checkCircle,
              label: 'Cerrar Alarma',
              color: AppTheme.successColor,
              onPressed: _dismissAlarm,
              isLoading: _isDismissing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVolumeWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.volumeUp,
            color: AppTheme.warningColor,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Asegúrate de que el volumen esté alto para escuchar la alarma',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _colorAnimation.value,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Encabezado de la alarma
                  _buildAlarmHeader(),

                  const SizedBox(height: 32),

                  // Información del mantenimiento
                  _buildAlarmInfo(),

                  const SizedBox(height: 24),

                  // Estado de la alarma
                  _buildAlarmStatus(),

                  const SizedBox(height: 32),

                  // Botones de acción
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // Advertencia de volumen
                  if (widget.puedeSonar) _buildVolumeWarning(),

                  const SizedBox(height: 16),

                  // Texto informativo
                  Text(
                    'Esta pantalla permanecerá activa hasta que cierres la alarma',
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _alarmTimer.cancel();
    _vibrationTimer.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Pantalla de alarma simplificada para notificaciones push
class AlarmNotificationScreen extends StatelessWidget {
  final String cliente;
  final String equipo;
  final String fecha;

  const AlarmNotificationScreen({
    super.key,
    required this.cliente,
    required this.equipo,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FontAwesomeIcons.bell, size: 80, color: AppTheme.errorColor),

              const SizedBox(height: 24),

              Text(
                '🔔 Recordatorio de Mantenimiento',
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildNotificationRow('Cliente:', cliente),
                    const SizedBox(height: 12),
                    _buildNotificationRow('Equipo:', equipo),
                    const SizedBox(height: 12),
                    _buildNotificationRow('Fecha:', fecha),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.secondaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
