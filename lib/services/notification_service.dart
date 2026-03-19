import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'alarm_service.dart';

// Callbacks para interacciones con notificaciones
typedef AlarmTapCallback =
    void Function(String cliente, String equipo, String fecha);
typedef NotificationActionCallback =
    void Function(String actionId, String cliente, String equipo, String fecha);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _initialized = false;

  // MethodChannel para comunicación con Android
  static const platform = MethodChannel('com.example.agenda_flutter/alarm');

  // Callbacks para alarmas
  AlarmTapCallback? _alarmTapCallback;
  NotificationActionCallback? _notificationActionCallback;

  // Canales de notificación
  static const String _channelIdAlarmas = 'alarmas_channel';
  static const String _channelIdRecordatorios = 'recordatorios_channel';
  static const String _channelIdGeneral = 'general_channel';

  Future<void> initialize() async {
    if (_initialized) return;

    // Solicitar permisos POST_NOTIFICATIONS (Android 13+)
    await _requestNotificationPermissions();

    // Configurar notificaciones locales
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Crear canales de notificación
    await _crearCanales();

    _initialized = true;
    debugPrint('✅ Servicio de notificaciones inicializado');
  }

  // Solicitar permisos de notificaciones
  Future<void> _requestNotificationPermissions() async {
    debugPrint('📱 Solicitando permisos de notificaciones...');
    try {
      final status = await Permission.notification.request();
      debugPrint('📱 Estado permiso notificaciones: $status');

      if (status.isDenied) {
        debugPrint('⚠️ Permisos de notificación denegados');
      } else if (status.isGranted) {
        debugPrint('✅ Permisos de notificación concedidos');
      } else if (status.isPermanentlyDenied) {
        debugPrint('❌ Permisos de notificación permanentemente denegados');
        openAppSettings();
      }
    } catch (e) {
      debugPrint('❌ Error solicitando permisos: $e');
    }
  }

  // Registrar callback para cuando se toca una alarma
  void setAlarmTapCallback(AlarmTapCallback callback) {
    _alarmTapCallback = callback;
    debugPrint('✅ Callback de alarma registrado');
  }

  // Registrar callback para acciones de notificación (snooze/dismiss)
  void setNotificationActionCallback(NotificationActionCallback callback) {
    _notificationActionCallback = callback;
    debugPrint('✅ Callback de acciones de notificación registrado');
  }

  // Limpiar callbacks
  void clearAlarmTapCallback() {
    _alarmTapCallback = null;
  }

  // Lanzar la actividad fullscreen de alarma
  Future<void> launchFullscreenAlarm({
    required String cliente,
    required String equipo,
    required String fecha,
  }) async {
    try {
      await platform.invokeMethod('launchFullscreenAlarm', {
        'cliente': cliente,
        'equipo': equipo,
        'fecha': fecha,
      });
      debugPrint('✅ Actividad fullscreen de alarma lanzada');
    } catch (e) {
      debugPrint('❌ Error lanzando actividad fullscreen: $e');
    }
  }

  void clearNotificationActionCallback() {
    _notificationActionCallback = null;
  }

  // Crear canales de notificación para Android
  Future<void> _crearCanales() async {
    // Canal para alarmas (alta prioridad, pantalla completa)
    const AndroidNotificationChannel alarmaChannel = AndroidNotificationChannel(
      _channelIdAlarmas,
      'Alarmas de Mantenimiento',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      description: 'Alarmas urgentes para mantenimientos pendientes',
    );

    // Canal para recordatorios
    const AndroidNotificationChannel recordatorioChannel =
        AndroidNotificationChannel(
          _channelIdRecordatorios,
          'Recordatorios de Mantenimiento',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          description: 'Notificaciones para recordatorios de mantenimiento',
        );

    // Canal general
    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          _channelIdGeneral,
          'Notificaciones Generales',
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          description: 'Notificaciones generales de la aplicación',
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(alarmaChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(recordatorioChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(generalChannel);
  }

  // Mostrar notificación normal
  Future<void> showNotification({
    required String title,
    required String body,
    String channelId = _channelIdGeneral,
    int id = 0,
    String? payload,
    bool vibrate = false,
    bool playSound = false,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Mostrar notificación programada
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduleTime,
    String channelId = _channelIdRecordatorios,
    int id = 0,
    String? payload,
    bool repeat = false,
  }) async {
    if (!_initialized) await initialize();

    // Configurar detalles según el canal
    AndroidNotificationDetails androidDetails;
    switch (channelId) {
      case _channelIdAlarmas:
        androidDetails = const AndroidNotificationDetails(
          _channelIdAlarmas,
          'Alarmas de Mantenimiento',
          channelDescription: 'Alarmas urgentes para mantenimientos pendientes',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          timeoutAfter: 60000, // 1 minuto
          actions: [
            AndroidNotificationAction(
              'dismiss',
              'Cerrar',
              cancelNotification: true,
            ),
            AndroidNotificationAction('snooze', 'Posponer'),
          ],
        );
        break;
      case _channelIdRecordatorios:
        androidDetails = const AndroidNotificationDetails(
          _channelIdRecordatorios,
          'Recordatorios de Mantenimiento',
          channelDescription:
              'Notificaciones para recordatorios de mantenimiento',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        );
        break;
      default:
        androidDetails = const AndroidNotificationDetails(
          _channelIdGeneral,
          'Notificaciones Generales',
          channelDescription: 'Notificaciones generales de la aplicación',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
    }

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    // Usar solo .show() en lugar de zonedSchedule para evitar problemas de permisos
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    debugPrint('✅ Notificación programada para: $scheduleTime - $title');
  }

  // Mostrar alarma en pantalla completa
  Future<void> showFullScreenAlarm({
    required String cliente,
    required String equipo,
    required String fecha,
    bool esPrueba = false,
    bool repetir = false,
  }) async {
    if (!_initialized) await initialize();

    debugPrint('');
    debugPrint('========================================');
    debugPrint('🔔 NOTIFICACIÓN: Preparando alarma full-screen');
    debugPrint('   Cliente: $cliente');
    debugPrint('   Equipo: $equipo');
    debugPrint('   Es Prueba: $esPrueba');
    debugPrint('========================================');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelIdAlarmas,
          'Alarmas de Mantenimiento',
          channelDescription: 'Alarmas urgentes para mantenimientos pendientes',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          playSound: true,
          // Usar alarma_10.mp3 como sonido de notificación
          sound: RawResourceAndroidNotificationSound('alarma_10'),
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          timeoutAfter: 300000, // 5 minutos
          colorized: true,
          color: Colors.red,
          actions: [
            AndroidNotificationAction(
              'dismiss',
              'Cerrar Alarma',
              cancelNotification: true,
            ),
            AndroidNotificationAction('snooze', 'Posponer 5 min'),
          ],
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    const String titulo = '🚨 Alarma de Mantenimiento';
    final String texto = 'Mantenimiento requerido para $equipo de $cliente';

    final notificationId = 999; // ID fijo para la alarma

    try {
      await _notificationsPlugin.show(
        notificationId,
        titulo,
        texto,
        platformChannelSpecifics,
        payload: 'alarma|$cliente|$equipo|$fecha|${esPrueba.toString()}',
      );

      debugPrint('✅ Alarma mostrada en centro de notificaciones');
      debugPrint('   ID: $notificationId');
      debugPrint('========================================');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Error mostrando alarma: $e');
      debugPrint('   Stack: ${StackTrace.current}');
    }
  }

  // Mostrar notificación de recordatorio
  Future<void> showReminderNotification({
    required String cliente,
    required String equipo,
    required String fecha,
  }) async {
    if (!_initialized) await initialize();

    const titulo = '🔔 Recordatorio de Mantenimiento';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelIdRecordatorios,
          'Recordatorios de Mantenimiento',
          channelDescription:
              'Notificaciones para recordatorios de mantenimiento',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          // Usar sonido por defecto del sistema
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      'Mantenimiento mañana para $cliente',
      platformChannelSpecifics,
      payload: 'recordatorio|$cliente|$equipo|$fecha',
    );

    debugPrint('🔔 Recordatorio mostrado: $cliente');
  }

  // Cancelar notificación específica
  Future<void> cancelNotification(int id) async {
    if (!_initialized) await initialize();
    await _notificationsPlugin.cancel(id);
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notificationsPlugin.cancelAll();
  }

  // Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Manejar tap en notificación
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('');
    debugPrint('════════════════════════════════════════');
    debugPrint('🔔 NOTIFICACIÓN: Evento recibido');
    debugPrint('   Payload: ${response.payload}');
    debugPrint('   Action ID: ${response.actionId}');
    debugPrint('════════════════════════════════════════');

    // Extraer datos del payload
    String? cliente, equipo, fecha;
    if (response.payload != null) {
      final payload = response.payload!;
      final parts = payload.split('|');
      if (parts.length >= 4 && parts[0] == 'alarma') {
        cliente = parts[1];
        equipo = parts[2];
        fecha = parts[3];

        debugPrint('   Cliente: $cliente');
        debugPrint('   Equipo: $equipo');
        debugPrint('   Fecha: $fecha');
      }
    }

    // Si se ejecutó una acción de botón (dismiss/snooze)
    if (response.actionId != null) {
      debugPrint('📌 Acción detectada: ${response.actionId}');

      // Primero, ejecutar callback si está registrado
      if (_notificationActionCallback != null &&
          cliente != null &&
          equipo != null &&
          fecha != null) {
        debugPrint('📍 [1] Ejecutando callback registrado...');
        _notificationActionCallback!(
          response.actionId!,
          cliente,
          equipo,
          fecha,
        );
      } else {
        debugPrint('⚠️ [1] No hay callback registrado o faltan datos');
        debugPrint(
          '    Callback existe: ${_notificationActionCallback != null}',
        );
        debugPrint('    Cliente: $cliente');
        debugPrint('    Equipo: $equipo');
        debugPrint('    Fecha: $fecha');
      }

      // Ejecutar acción directamente también como respaldo
      debugPrint('📍 [2] Ejecutando acción directamente como respaldo...');
      if (response.actionId == 'dismiss') {
        debugPrint('✅ [2] Acción dismiss: deteniendo alarma');
        _handleDismissAction();
      } else if (response.actionId == 'snooze') {
        debugPrint('✅ [2] Acción snooze: posponiendo alarma');
        if (cliente != null && equipo != null && fecha != null) {
          _handleSnoozeAction(cliente, equipo, fecha);
        }
      }

      cancelAllNotifications();
      return;
    }

    // Si se clickeó directamente en la notificación (sin presionar botón)
    if (response.payload != null && response.actionId == null) {
      final payload = response.payload!;
      final parts = payload.split('|');

      if (parts.isNotEmpty) {
        final tipo = parts[0];

        switch (tipo) {
          case 'alarma':
            if (parts.length >= 4) {
              final cli = parts[1];
              final equ = parts[2];
              final fec = parts[3];

              debugPrint('🚨 Alarma tocada: $cli - $equ');

              // Lanzar FullscreenAlarmActivity
              launchFullscreenAlarm(cliente: cli, equipo: equ, fecha: fec);

              // Llamar callback de alarma
              if (_alarmTapCallback != null) {
                _alarmTapCallback!(cli, equ, fec);
                debugPrint('✅ Callback de alarma ejecutado');
              }

              // Cancelar notificación
              cancelAllNotifications();
            }
            break;

          case 'recordatorio':
            if (parts.length >= 4) {
              final cli = parts[1];
              final equ = parts[2];

              debugPrint('📝 Recordatorio clickeado: $cli - $equ');
            }
            break;
        }
      }
    }
  }

  // Manejar acción dismiss directamente
  void _handleDismissAction() {
    debugPrint('➡️ _handleDismissAction() ejecutando...');
    try {
      cancelAllNotifications();
      debugPrint('✅ Notificación cancelada');

      // Obtener AlarmService y detener la alarma
      final alarmService = AlarmService();
      alarmService.detenerAlarma();
      debugPrint('✅ AlarmService.detenerAlarma() llamado');
    } catch (e) {
      debugPrint('❌ Error en _handleDismissAction: $e');
    }
  }

  // Manejar acción snooze directamente
  void _handleSnoozeAction(String cliente, String equipo, String fecha) {
    debugPrint('➡️ _handleSnoozeAction() ejecutando...');
    try {
      cancelAllNotifications();
      debugPrint('✅ Notificación cancelada');

      // Obtener AlarmService y posponer la alarma
      final alarmService = AlarmService();
      alarmService.posponderAlarma(cliente, equipo, fecha, null);
      debugPrint('✅ AlarmService.posponderAlarma() llamado');
    } catch (e) {
      debugPrint('❌ Error en _handleSnoozeAction: $e');
    }
  }

  // Verificar permisos de notificación
  Future<bool> checkNotificationPermissions() async {
    if (!_initialized) await initialize();

    final bool? granted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return granted ?? false;
  }

  // Limpiar todas las notificaciones programadas
  Future<void> clearAllScheduledNotifications() async {
    if (!_initialized) await initialize();

    final pendientes = await getPendingNotifications();
    for (final notificacion in pendientes) {
      await cancelNotification(notificacion.id);
    }

    debugPrint('✅ Todas las notificaciones programadas canceladas');
  }
}
