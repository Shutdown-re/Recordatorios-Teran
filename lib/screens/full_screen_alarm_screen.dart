import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/audio_service.dart';

class FullScreenAlarmScreen extends StatefulWidget {
  final String cliente;
  final String equipo;
  final String fecha;
  final bool esPrueba;

  const FullScreenAlarmScreen({
    Key? key,
    required this.cliente,
    required this.equipo,
    required this.fecha,
    this.esPrueba = false,
  }) : super(key: key);

  @override
  State<FullScreenAlarmScreen> createState() => _FullScreenAlarmScreenState();
}

class _FullScreenAlarmScreenState extends State<FullScreenAlarmScreen>
    with WidgetsBindingObserver {
  bool _permissionAsked = false;
  late AudioService _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioService = AudioService();

    // Orden de prioridad para asegurar que todo funcione
    _requestOverlayPermission();
    _startVibration();

    // Nota: El sonido YA se está reproduciendo desde AlarmService
    // NO reproducir aquí nuevamente para evitar duplicados/interrupciones
    debugPrint('📱 FullScreenAlarmScreen abierto');
    debugPrint('📱 El audio ya debe estar reproduciéndose desde AlarmService');
  }

  Future<void> _requestOverlayPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;

    final status = await Permission.systemAlertWindow.request();
    debugPrint('📱 Permiso overlay: $status');
  }

  void _startVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      // Patrón de vibración intenso
      await Vibration.vibrate(
        pattern: [0, 500, 200, 500, 200, 500, 200, 500],
        intensities: [0, 255, 0, 255, 0, 255, 0, 255],
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.stopSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // No permitir pop con back button
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.shade800, Colors.red.shade900],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono de alarma animado
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: 1.3),
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          onEnd: () {},
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.alarm,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Título principal
                        const Text(
                          '¡ALARMA ACTIVA!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acción requerida',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Detalles en tarjeta translúcida
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: Icons.person,
                                label: 'Cliente',
                                value: widget.cliente,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                icon: Icons.build,
                                label: 'Equipo',
                                value: widget.equipo,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                icon: Icons.calendar_today,
                                label: 'Fecha',
                                value: widget.fecha,
                              ),
                              if (widget.esPrueba) ...[
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Modo de Prueba',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  debugPrint('');
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );
                                  debugPrint('✅ BOTÓN ACEPTAR PRESIONADO');
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );

                                  try {
                                    await Vibration.cancel();
                                    debugPrint('✅ Vibración cancelada');
                                  } catch (e) {
                                    debugPrint(
                                      '⚠️ Error cancelando vibración: $e',
                                    );
                                  }

                                  try {
                                    await _audioService.stopSound();
                                    debugPrint('✅ Sonido detenido');
                                  } catch (e) {
                                    debugPrint(
                                      '⚠️ Error deteniendo sonido: $e',
                                    );
                                  }

                                  if (mounted) {
                                    debugPrint(
                                      '✅ Widget mounted, ejecutando Navigator.pop()',
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop();
                                    debugPrint('✅ Navigator.pop() ejecutado');
                                  } else {
                                    debugPrint('❌ Widget NOT mounted');
                                  }
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );
                                  debugPrint('');
                                },
                                icon: const Icon(Icons.check_circle, size: 24),
                                label: const Text('Aceptar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  debugPrint('');
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );
                                  debugPrint('⏸️  BOTÓN POSPONER PRESIONADO');
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );

                                  try {
                                    await Vibration.cancel();
                                    debugPrint('✅ Vibración cancelada');
                                  } catch (e) {
                                    debugPrint(
                                      '⚠️ Error cancelando vibración: $e',
                                    );
                                  }

                                  try {
                                    await _audioService.stopSound();
                                    debugPrint('✅ Sonido detenido');
                                  } catch (e) {
                                    debugPrint(
                                      '⚠️ Error deteniendo sonido: $e',
                                    );
                                  }

                                  if (mounted) {
                                    debugPrint(
                                      '✅ Widget mounted, ejecutando Navigator.pop()',
                                    );
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop('snooze');
                                    debugPrint('✅ Navigator.pop() ejecutado');
                                  } else {
                                    debugPrint('❌ Widget NOT mounted');
                                  }
                                  debugPrint(
                                    '═══════════════════════════════════════',
                                  );
                                  debugPrint('');
                                },
                                icon: const Icon(Icons.schedule, size: 24),
                                label: const Text('Posponer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
