import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:workmanager/workmanager.dart'; // Removido: incompatible
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/recordatorio.dart';
import '../models/alarma_config.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'audio_service.dart';

// Callback para cuando se dispara una alarma
typedef AlarmFireCallback =
    void Function(String cliente, String equipo, String fecha);

class AlarmService {
  final NotificationService _notificationService;
  final StorageService _storageService;
  final AudioService _audioService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // final AudioPlayer _notificationAudioPlayer =
  //     AudioPlayer(); // Para sonido adicional de notificación - COMENTADO: ahora la notificación lo proporciona
  Timer? _alarmTimer;
  bool _alarmaActiva = false;
  int _repeticiones = 0;

  // Callback cuando se dispara una alarma programada
  AlarmFireCallback? _alarmFireCallback;

  // === Estado de Snooze ===
  // Notifier que emite los segundos restantes del snooze (0 = no hay snooze activo)
  final ValueNotifier<int> snoozeSecondsLeft = ValueNotifier<int>(0);
  String? snoozeCliente;
  String? snoozeEquipo;
  Timer? _snoozeTicker;
  DateTime? _snoozeEndTime;
  static const int snoozeDurationMinutes = 5;

  // MethodChannel para comunicación con Android
  static const platform = MethodChannel('com.example.agenda_flutter/alarm');

  AlarmService()
    : _notificationService = NotificationService(),
      _storageService = StorageService(),
      _audioService = AudioService();

  // Registrar callback para cuando se dispara una alarma
  void setAlarmFireCallback(AlarmFireCallback callback) {
    _alarmFireCallback = callback;
    debugPrint('✅ Callback de alarma registrado en AlarmService');
  }

  // Limpiar callback
  void clearAlarmFireCallback() {
    _alarmFireCallback = null;
    debugPrint('✅ Callback de alarma limpiado');
  }

  // Programar alarma para un recordatorio
  Future<void> programarAlarma(Recordatorio recordatorio) async {
    try {
      final fechaAlarma = recordatorio.calcularFechaAlarma();

      // Si la fecha ya pasó, no programar
      if (fechaAlarma.isBefore(DateTime.now())) {
        debugPrint('La fecha de alarma ya pasó para: ${recordatorio.cliente}');
        return;
      }

      // Calcular delay en segundos
      final delay = fechaAlarma.difference(DateTime.now());
      final delaySegundos = delay.inSeconds;

      if (delaySegundos <= 0) {
        debugPrint('Delay negativo o cero para: ${recordatorio.cliente}');
        return;
      }

      debugPrint('✅ Alarma programada para: ${recordatorio.cliente}');

      // PASO 1: Crear alarma en la app Reloj nativa del teléfono
      // Mostrará: "Servicio: NombreCliente - Equipo"
      try {
        await _setNativeAlarm(
          recordatorio.cliente,
          recordatorio.equipo,
          fechaAlarma,
        );
        debugPrint('✅ Alarma creada en app Reloj nativa');
      } catch (e) {
        debugPrint(
          '⚠️ Error creando alarma nativa (continuando con notificación): $e',
        );
      }

      // PASO 2: Programar notificación local como respaldo
      await _notificationService.scheduleNotification(
        title: '🚨 Alarma: ${recordatorio.cliente}',
        body: recordatorio.equipo,
        scheduleTime: fechaAlarma,
        channelId: 'alarmas_channel',
        id: recordatorio.id.hashCode,
        payload:
            'alarma|${recordatorio.id}|${recordatorio.cliente}|${recordatorio.equipo}',
      );

      // Actualizar recordatorio
      final recordatorioActualizado = recordatorio.copyWith(
        alarmaProgramada: true,
        fechaAlarma: fechaAlarma,
      );

      await _storageService.actualizarRecordatorio(recordatorioActualizado);
    } catch (e) {
      debugPrint('❌ Error programando alarma: $e');
      rethrow;
    }
  }

  // Programar notificación previa (1 día antes)
  Future<void> programarNotificacionPrevia(Recordatorio recordatorio) async {
    try {
      final fechaNotificacion = recordatorio.calcularFechaNotificacion();

      // Si la fecha ya pasó, no programar
      if (fechaNotificacion.isBefore(DateTime.now())) {
        return;
      }

      final delay = fechaNotificacion.difference(DateTime.now());
      final delaySegundos = delay.inSeconds;

      if (delaySegundos <= 0) return;

      debugPrint(
        '✅ Notificación previa programada para: ${recordatorio.cliente}',
      );

      // Programar notificación local (sin workmanager)
      await _notificationService.scheduleNotification(
        title: '🔔 Recordatorio: ${recordatorio.cliente}',
        body: 'Mantenimiento mañana',
        scheduleTime: fechaNotificacion,
        channelId: 'recordatorios_channel',
        id: recordatorio.id.hashCode + 1000,
        payload: 'recordatorio|${recordatorio.id}|${recordatorio.cliente}',
      );

      final recordatorioActualizado = recordatorio.copyWith(
        notificacionProgramada: true,
        fechaNotificacion: fechaNotificacion,
      );

      await _storageService.actualizarRecordatorio(recordatorioActualizado);
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
    }
  }

  // Cancelar alarma de un recordatorio
  Future<void> cancelarAlarma(Recordatorio recordatorio) async {
    try {
      // Cancelar notificaciones locales programadas
      await _notificationService.cancelNotification(recordatorio.id.hashCode);
      await _notificationService.cancelNotification(
        recordatorio.id.hashCode + 1000,
      );

      // Eliminar alarma del Reloj nativo
      try {
        await _dismissNativeAlarm(recordatorio.cliente, recordatorio.equipo);
      } catch (e) {
        debugPrint('⚠️ Error eliminando alarma nativa al cancelar: $e');
      }

      final recordatorioActualizado = recordatorio.copyWith(
        alarmaProgramada: false,
        fechaAlarma: null,
        notificacionProgramada: false,
        fechaNotificacion: null,
      );

      await _storageService.actualizarRecordatorio(recordatorioActualizado);

      debugPrint('✅ Alarmas canceladas para: ${recordatorio.cliente}');
    } catch (e) {
      debugPrint('❌ Error cancelando alarma: $e');
    }
  }

  // Activar alarma inmediatamente (para pruebas)
  Future<void> activarAlarmaInmediata({
    required String cliente,
    required String equipo,
    required String fecha,
    DateTime? fechaAlarma,
    AlarmaConfig? config,
    bool esPrueba = false,
  }) async {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║ 🚨 ACTIVANDO ALARMA NATIVA ║');
    debugPrint('╚════════════════════════════════════════╝');

    if (_alarmaActiva) {
      debugPrint('⚠️ Alarma ya activa, deteniendo anterior...');
      await detenerAlarma();
    }

    _alarmaActiva = true;
    _clienteActivo = cliente;
    _equipoActivo = equipo;

    // PASO 1: Mostrar notificación en Flutter como recordatorio
    debugPrint('▼ PASO 1: Mostrar notificación como recordatorio');
    try {
      await _notificationService.showFullScreenAlarm(
        cliente: cliente,
        equipo: equipo,
        fecha: fecha,
        esPrueba: esPrueba,
      );
      debugPrint('✅ Notificación mostrada');
    } catch (e) {
      debugPrint('⚠️ Error en notificación: $e');
    }

    // PASO 2: Crear alarma nativa del sistema
    debugPrint('▼ PASO 2: Crear alarma nativa en app Alarmas');
    try {
      await _setNativeAlarm(cliente, equipo, fechaAlarma);
      debugPrint('✅ Alarma nativa creada');
    } catch (e) {
      debugPrint('❌ Error creando alarma nativa: $e');
    }

    // PASO 3: Ejecutar callback si está registrado
    debugPrint('▼ PASO 3: Ejecutar callback');
    if (_alarmFireCallback != null) {
      _alarmFireCallback!(cliente, equipo, fecha);
      debugPrint('✅ Callback de alarma ejecutado');
    } else {
      debugPrint('⚠️ No hay callback registrado');
    }

    debugPrint('✅ ALARMA NATIVA PROGRAMADA CORRECTAMENTE');
    debugPrint('');
  }

  // Crear alarma directamente en la app Reloj nativa del teléfono
  // El label mostrará: "Servicio: NombreCliente - Equipo"
  Future<void> _setNativeAlarm(
    String cliente,
    String equipo,
    DateTime? fechaAlarma,
  ) async {
    try {
      int hora = 0;
      int minuto = 0;

      if (fechaAlarma != null) {
        hora = fechaAlarma.hour;
        minuto = fechaAlarma.minute;
        debugPrint(
          '📅 Hora de alarma nativa: $hora:${minuto.toString().padLeft(2, '0')}',
        );
      }

      final result = await platform.invokeMethod('setNativeAlarm', {
        'cliente': cliente,
        'equipo': equipo,
        'hora': hora,
        'minuto': minuto,
      });
      debugPrint(
        '✅ Alarma nativa creada en Reloj: Servicio: $cliente - $equipo',
      );
    } catch (e) {
      debugPrint('❌ Error creando alarma nativa: $e');
      rethrow;
    }
  }

  // Eliminar alarma de la app Reloj nativa del teléfono
  // Se busca por label "Servicio: NombreCliente - Equipo" y se elimina
  Future<void> _dismissNativeAlarm(String cliente, String equipo) async {
    try {
      final result = await platform.invokeMethod('dismissNativeAlarm', {
        'cliente': cliente,
        'equipo': equipo,
      });
      debugPrint(
        '✅ Alarma nativa eliminada del Reloj: Servicio: $cliente - $equipo',
      );
    } catch (e) {
      debugPrint(
        '⚠️ Error eliminando alarma nativa (puede que ya no exista): $e',
      );
    }
  }

  // Nombre del cliente/equipo de la alarma activa (para poder eliminarla del nativo)
  String? _clienteActivo;
  String? _equipoActivo;

  // Detener alarma activa
  Future<void> detenerAlarma() async {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║ ⏹️  DETENIENDO ALARMA');
    debugPrint('╚════════════════════════════════════════╝');

    try {
      // Cancelar timer
      if (_alarmTimer != null) {
        _alarmTimer!.cancel();
        _alarmTimer = null;
        debugPrint('✅ Timer cancelado');
      } else {
        debugPrint('ℹ️ No había timer activo');
      }

      // Detener sonido
      try {
        await _audioPlayer.stop();
        debugPrint('✅ AudioPlayer detenido');
      } catch (e) {
        debugPrint('⚠️ Error deteniendo AudioPlayer: $e');
      }

      // Detener sonido de notificación - COMENTADO: ahora viene de la notificación directamente
      // try {
      //   await _notificationAudioPlayer.stop();
      //   debugPrint('✅ Sonido de notificación detenido');
      // } catch (e) {
      //   debugPrint('⚠️ Error deteniendo sonido de notificación: $e');
      // }

      // Detener vibración
      try {
        await Vibration.cancel();
        debugPrint('✅ Vibración cancelada');
      } catch (e) {
        debugPrint('⚠️ Error cancelando vibración: $e');
      }

      // Detener audio en AudioService
      try {
        await _audioService.stopSound();
        debugPrint('✅ AudioService detenido');
      } catch (e) {
        debugPrint('⚠️ Error deteniendo AudioService: $e');
      }

      // Cancelar notificación
      try {
        await _notificationService.cancelAllNotifications();
        debugPrint('✅ Notificaciones canceladas');
      } catch (e) {
        debugPrint('⚠️ Error cancelando notificaciones: $e');
      }

      // Eliminar alarma del Reloj nativo
      if (_clienteActivo != null && _equipoActivo != null) {
        try {
          await _dismissNativeAlarm(_clienteActivo!, _equipoActivo!);
          debugPrint('✅ Alarma nativa eliminada del Reloj');
        } catch (e) {
          debugPrint('⚠️ Error eliminando alarma nativa: $e');
        }
        _clienteActivo = null;
        _equipoActivo = null;
      }

      _alarmaActiva = false;
      _repeticiones = 0;

      // Limpiar estado de snooze si estaba activo
      _cancelSnoozeState();

      debugPrint('╔════════════════════════════════════════╗');
      debugPrint('║ ✅ ALARMA DETENIDA');
      debugPrint('╚════════════════════════════════════════╝');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error deteniendo alarma: $e');
      debugPrint('   Stack: ${StackTrace.current}');
    }
  }

  // Iniciar el ticker de cuenta atrás para snooze
  void _startSnoozeTicker() {
    _snoozeTicker?.cancel();
    _snoozeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_snoozeEndTime == null) {
        _cancelSnoozeState();
        return;
      }
      final remaining = _snoozeEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        snoozeSecondsLeft.value = 0;
        _cancelSnoozeState();
      } else {
        snoozeSecondsLeft.value = remaining;
      }
    });
  }

  // Cancelar el estado visual del snooze
  void _cancelSnoozeState() {
    _snoozeTicker?.cancel();
    _snoozeTicker = null;
    _snoozeEndTime = null;
    snoozeCliente = null;
    snoozeEquipo = null;
    snoozeSecondsLeft.value = 0;
  }

  // Posponer alarma 5 minutos
  Future<void> posponderAlarma(
    String cliente,
    String equipo,
    String fecha,
    DateTime? fechaAlarma,
  ) async {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║ ⏸️  POSPONIENDO ALARMA $snoozeDurationMinutes MINUTOS');
    debugPrint('║ Cliente: $cliente');
    debugPrint('║ Equipo: $equipo');
    debugPrint('╚════════════════════════════════════════╝');

    try {
      // Detener alarma actual
      await detenerAlarma();

      // Programar nueva alarma en 5 minutos usando Timer (más confiable)
      final ahora = DateTime.now();
      final proximaAlarma = ahora.add(Duration(minutes: snoozeDurationMinutes));

      debugPrint(
        '⏰ Nueva alarma programada para: ${proximaAlarma.hour}:${proximaAlarma.minute.toString().padLeft(2, '0')}',
      );

      // === Activar estado de snooze visible en la UI ===
      snoozeCliente = cliente;
      snoozeEquipo = equipo;
      _snoozeEndTime = proximaAlarma;
      snoozeSecondsLeft.value = Duration(
        minutes: snoozeDurationMinutes,
      ).inSeconds;
      _startSnoozeTicker();

      // Usar Timer para disparar la alarma después del snooze
      _alarmTimer = Timer(Duration(minutes: snoozeDurationMinutes), () async {
        // Limpiar estado visual de snooze
        _cancelSnoozeState();

        if (_alarmFireCallback != null) {
          debugPrint('');
          debugPrint('╔════════════════════════════════════════╗');
          debugPrint('║ 🔔 SNOOZE: ALARMA POSPONIDA SE DISPARA');
          debugPrint('║ Cliente: $cliente');
          debugPrint('║ Equipo: $equipo');
          debugPrint('╚════════════════════════════════════════╝');
          debugPrint('');

          // Activar la alarma nuevamente después del snooze
          await activarAlarmaInmediata(
            cliente: cliente,
            equipo: equipo,
            fecha: fecha,
            fechaAlarma: fechaAlarma,
          );
        }
      });

      debugPrint(
        '✅ Alarma posponida exitosamente (Timer + Countdown configurado)',
      );
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error posponiendo alarma: $e');
      debugPrint('   Stack: ${StackTrace.current}');
    }
  }

  // Verificar alarmas pendientes
  Future<void> checkPendingAlarms() async {
    try {
      final recordatorios = await _storageService.getRecordatorios();
      final ahora = DateTime.now();

      for (final recordatorio in recordatorios) {
        if (recordatorio.alarmaProgramada && recordatorio.fechaAlarma != null) {
          final diferencia = recordatorio.fechaAlarma!.difference(ahora);

          if (diferencia.inSeconds <= 0 && diferencia.inSeconds >= -300) {
            // 5 minutos de tolerancia
            debugPrint('⚠️ Alarma vencida detectada: ${recordatorio.cliente}');
            await _activarAlarmaVencida(recordatorio);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error verificando alarmas: $e');
    }
  }

  // Activar alarma vencida
  Future<void> _activarAlarmaVencida(Recordatorio recordatorio) async {
    await activarAlarmaInmediata(
      cliente: recordatorio.cliente,
      equipo: recordatorio.equipo,
      fecha: recordatorio.fechaProximoFormateada(),
      fechaAlarma: recordatorio.fechaProximoMantenimiento,
      config: AlarmaConfig.configMaxima,
    );
  }

  // Re-programar todas las alarmas (útil después de reiniciar dispositivo)
  Future<void> reprogramarTodasLasAlarmas() async {
    try {
      final recordatorios = await _storageService.getRecordatorios();

      for (final recordatorio in recordatorios) {
        if (recordatorio.alarmaProgramada) {
          await cancelarAlarma(recordatorio);
          await programarAlarma(recordatorio);
        }

        if (recordatorio.notificacionProgramada) {
          await programarNotificacionPrevia(recordatorio);
        }
      }

      debugPrint('✅ Todas las alarmas reprogramadas');
    } catch (e) {
      debugPrint('❌ Error reprogramando alarmas: $e');
    }
  }

  // Verificar si hay alarma activa
  bool get alarmaActiva => _alarmaActiva;

  // Obtener estado de la alarma
  String get estadoAlarma {
    if (!_alarmaActiva) return 'Inactiva';
    if (_repeticiones > 0) return 'Repitiendo ($_repeticiones)';
    return 'Activa';
  }

  // Limpiar recursos
  Future<void> dispose() async {
    _alarmTimer?.cancel();
    _snoozeTicker?.cancel();
    snoozeSecondsLeft.dispose();
    await _audioPlayer.dispose();
  }
}
