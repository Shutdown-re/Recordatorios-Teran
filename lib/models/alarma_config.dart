import 'package:flutter/material.dart';

class AlarmaConfig {
  // Sonidos disponibles
  static const List<String> sonidosDisponibles = [
    'sonido_default',
    'alarma_urgente',
    'tono_suave',
    'campana',
    'digital',
  ];

  // Vibraciones disponibles
  static const List<String> vibracionesDisponibles = [
    'sin_vibracion',
    'corta',
    'larga',
    'patron_alarma',
    'constante',
  ];

  // Configuración de la alarma
  String sonidoSeleccionado;
  String vibracionSeleccionada;
  int volumen; // 0-100
  bool vibrar;
  bool sonido;
  bool pantallaCompleta;
  bool despertarPantalla;
  bool modoSilencioso;
  Duration duracionAlarma;
  bool repetirAlarma;
  int repeticionesMaximas;
  bool pruebaAutomatica;
  bool notificacionesPush;
  bool recordatorioPrevio;
  Duration tiempoRecordatorioPrevio;

  AlarmaConfig({
    this.sonidoSeleccionado = 'sonido_default',
    this.vibracionSeleccionada = 'patron_alarma',
    this.volumen = 100,
    this.vibrar = true,
    this.sonido = true,
    this.pantallaCompleta = true,
    this.despertarPantalla = true,
    this.modoSilencioso = false,
    this.duracionAlarma = const Duration(minutes: 5),
    this.repetirAlarma = true,
    this.repeticionesMaximas = 3,
    this.pruebaAutomatica = false,
    this.notificacionesPush = true,
    this.recordatorioPrevio = true,
    this.tiempoRecordatorioPrevio = const Duration(hours: 24),
  });

  // Constructor desde JSON
  factory AlarmaConfig.fromJson(Map<String, dynamic> json) {
    return AlarmaConfig(
      sonidoSeleccionado:
          json['sonido_seleccionado'] ??
          json['sonidoSeleccionado'] ??
          'sonido_default',
      vibracionSeleccionada:
          json['vibracion_seleccionada'] ??
          json['vibracionSeleccionada'] ??
          'patron_alarma',
      volumen: json['volumen'] ?? 100,
      vibrar: (json['vibrar'] ?? true) is bool
          ? (json['vibrar'] as bool)
          : (json['vibrar'] as int) == 1,
      sonido: (json['sonido'] ?? true) is bool
          ? (json['sonido'] as bool)
          : (json['sonido'] as int) == 1,
      pantallaCompleta:
          (json['pantalla_completa'] ?? json['pantallaCompleta'] ?? true)
              is bool
          ? (json['pantalla_completa'] ?? json['pantallaCompleta'] as bool)
          : (json['pantalla_completa'] ?? json['pantallaCompleta'] as int) == 1,
      despertarPantalla:
          (json['despertar_pantalla'] ?? json['despertarPantalla'] ?? true)
              is bool
          ? (json['despertar_pantalla'] ?? json['despertarPantalla'] as bool)
          : (json['despertar_pantalla'] ?? json['despertarPantalla'] as int) ==
                1,
      modoSilencioso:
          (json['modo_silencioso'] ?? json['modoSilencioso'] ?? false) is bool
          ? (json['modo_silencioso'] ?? json['modoSilencioso'] as bool)
          : (json['modo_silencioso'] ?? json['modoSilencioso'] as int) == 1,
      duracionAlarma: Duration(
        minutes: json['duracion_alarma'] ?? json['duracionAlarma'] ?? 5,
      ),
      repetirAlarma:
          (json['repetir_alarma'] ?? json['repetirAlarma'] ?? true) is bool
          ? (json['repetir_alarma'] ?? json['repetirAlarma'] as bool)
          : (json['repetir_alarma'] ?? json['repetirAlarma'] as int) == 1,
      repeticionesMaximas:
          json['repeticiones_maximas'] ?? json['repeticionesMaximas'] ?? 3,
      pruebaAutomatica:
          (json['prueba_automatica'] ?? json['pruebaAutomatica'] ?? false)
              is bool
          ? (json['prueba_automatica'] ?? json['pruebaAutomatica'] as bool)
          : (json['prueba_automatica'] ?? json['pruebaAutomatica'] as int) == 1,
      notificacionesPush:
          (json['notificaciones_push'] ?? json['notificacionesPush'] ?? true)
              is bool
          ? (json['notificaciones_push'] ?? json['notificacionesPush'] as bool)
          : (json['notificaciones_push'] ??
                    json['notificacionesPush'] as int) ==
                1,
      recordatorioPrevio:
          (json['recordatorio_previo'] ?? json['recordatorioPrevio'] ?? true)
              is bool
          ? (json['recordatorio_previo'] ?? json['recordatorioPrevio'] as bool)
          : (json['recordatorio_previo'] ??
                    json['recordatorioPrevio'] as int) ==
                1,
      tiempoRecordatorioPrevio: Duration(
        hours:
            json['tiempo_recordatorio_previo'] ??
            json['tiempoRecordatorioPrevio'] ??
            24,
      ),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'sonido_seleccionado': sonidoSeleccionado,
      'vibracion_seleccionada': vibracionSeleccionada,
      'volumen': volumen,
      'vibrar': vibrar ? 1 : 0,
      'sonido': sonido ? 1 : 0,
      'pantalla_completa': pantallaCompleta ? 1 : 0,
      'despertar_pantalla': despertarPantalla ? 1 : 0,
      'modo_silencioso': modoSilencioso ? 1 : 0,
      'duracion_alarma': duracionAlarma.inMinutes,
      'repetir_alarma': repetirAlarma ? 1 : 0,
      'repeticiones_maximas': repeticionesMaximas,
      'prueba_automatica': pruebaAutomatica ? 1 : 0,
      'notificaciones_push': notificacionesPush ? 1 : 0,
      'recordatorio_previo': recordatorioPrevio ? 1 : 0,
      'tiempo_recordatorio_previo': tiempoRecordatorioPrevio.inHours,
    };
  }

  // Patrones de vibración
  static List<int> obtenerPatronVibracion(String tipo) {
    switch (tipo) {
      case 'corta':
        return [0, 500];
      case 'larga':
        return [0, 1000];
      case 'patron_alarma':
        return [0, 1000, 500, 1000, 500, 1000];
      case 'constante':
        return [0, 1000];
      default:
        return [];
    }
  }

  // Validar configuración
  bool esValida() {
    if (volumen < 0 || volumen > 100) return false;
    if (repeticionesMaximas < 1 || repeticionesMaximas > 10) return false;
    if (duracionAlarma.inMinutes < 1 || duracionAlarma.inMinutes > 60) {
      return false;
    }
    return true;
  }

  // Obtener descripción del sonido
  String get descripcionSonido {
    switch (sonidoSeleccionado) {
      case 'sonido_default':
        return 'Sonido por defecto';
      case 'alarma_urgente':
        return 'Alarma urgente';
      case 'tono_suave':
        return 'Tono suave';
      case 'campana':
        return 'Campana';
      case 'digital':
        return 'Digital';
      default:
        return 'Sonido personalizado';
    }
  }

  // Obtener descripción de la vibración
  String get descripcionVibracion {
    switch (vibracionSeleccionada) {
      case 'sin_vibracion':
        return 'Sin vibración';
      case 'corta':
        return 'Vibración corta';
      case 'larga':
        return 'Vibración larga';
      case 'patron_alarma':
        return 'Patrón de alarma';
      case 'constante':
        return 'Vibración constante';
      default:
        return 'Vibración personalizada';
    }
  }

  // Verificar si tiene configuraciones de alarma activas
  bool get tieneAlarmaActiva {
    return sonido || vibrar;
  }

  // Configuración predeterminada
  static AlarmaConfig get defaultConfig {
    return AlarmaConfig();
  }

  // Configuración silenciosa (para pruebas)
  static AlarmaConfig get configSilenciosa {
    return AlarmaConfig(sonido: false, vibrar: false, pantallaCompleta: false);
  }

  // Configuración máxima (para alarmas importantes)
  static AlarmaConfig get configMaxima {
    return AlarmaConfig(
      sonidoSeleccionado: 'alarma_urgente',
      vibracionSeleccionada: 'patron_alarma',
      volumen: 100,
      vibrar: true,
      sonido: true,
      pantallaCompleta: true,
      despertarPantalla: true,
      duracionAlarma: const Duration(minutes: 10),
      repetirAlarma: true,
      repeticionesMaximas: 5,
    );
  }

  @override
  String toString() {
    return 'AlarmaConfig{sonido: $sonido, vibrar: $vibrar, pantallaCompleta: $pantallaCompleta, volumen: $volumen}';
  }
}

// Clase para configuración de notificaciones
class NotificacionConfig {
  bool mostrarNotificaciones;
  bool sonidoNotificaciones;
  bool vibrarNotificaciones;
  bool notificacionesPush;
  bool notificacionesProgramadas;
  bool recordatoriosDiarios;
  TimeOfDay horaRecordatoriosDiarios;
  bool resumenSemanal;

  NotificacionConfig({
    this.mostrarNotificaciones = true,
    this.sonidoNotificaciones = true,
    this.vibrarNotificaciones = true,
    this.notificacionesPush = true,
    this.notificacionesProgramadas = true,
    this.recordatoriosDiarios = false,
    this.horaRecordatoriosDiarios = const TimeOfDay(hour: 9, minute: 0),
    this.resumenSemanal = true,
  });

  factory NotificacionConfig.fromJson(Map<String, dynamic> json) {
    return NotificacionConfig(
      mostrarNotificaciones: json['mostrarNotificaciones'] ?? true,
      sonidoNotificaciones: json['sonidoNotificaciones'] ?? true,
      vibrarNotificaciones: json['vibrarNotificaciones'] ?? true,
      notificacionesPush: json['notificacionesPush'] ?? true,
      notificacionesProgramadas: json['notificacionesProgramadas'] ?? true,
      recordatoriosDiarios: json['recordatoriosDiarios'] ?? false,
      horaRecordatoriosDiarios: TimeOfDay(
        hour: json['horaRecordatoriosDiarios_hour'] ?? 9,
        minute: json['horaRecordatoriosDiarios_minute'] ?? 0,
      ),
      resumenSemanal: json['resumenSemanal'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mostrarNotificaciones': mostrarNotificaciones,
      'sonidoNotificaciones': sonidoNotificaciones,
      'vibrarNotificaciones': vibrarNotificaciones,
      'notificacionesPush': notificacionesPush,
      'notificacionesProgramadas': notificacionesProgramadas,
      'recordatoriosDiarios': recordatoriosDiarios,
      'horaRecordatoriosDiarios_hour': horaRecordatoriosDiarios.hour,
      'horaRecordatoriosDiarios_minute': horaRecordatoriosDiarios.minute,
      'resumenSemanal': resumenSemanal,
    };
  }
}

// Clase para estadísticas de alarmas
class AlarmaEstadisticas {
  int totalAlarmas;
  int alarmasCompletadas;
  int alarmasCanceladas;
  int alarmasVencidas;
  DateTime fechaUltimaAlarma;
  Duration tiempoPromedioRespuesta;

  AlarmaEstadisticas({
    this.totalAlarmas = 0,
    this.alarmasCompletadas = 0,
    this.alarmasCanceladas = 0,
    this.alarmasVencidas = 0,
    DateTime? fechaUltimaAlarma,
    this.tiempoPromedioRespuesta = Duration.zero,
  }) : fechaUltimaAlarma = fechaUltimaAlarma ?? DateTime.now();

  // Calcular porcentaje de completitud
  double get porcentajeCompletitud {
    if (totalAlarmas == 0) return 0;
    return (alarmasCompletadas / totalAlarmas) * 100;
  }

  // Calcular porcentaje de cancelación
  double get porcentajeCancelacion {
    if (totalAlarmas == 0) return 0;
    return (alarmasCanceladas / totalAlarmas) * 100;
  }

  // Obtener estadísticas como texto
  String get resumen {
    return 'Total: $totalAlarmas | Completadas: $alarmasCompletadas | Canceladas: $alarmasCanceladas | Vencidas: $alarmasVencidas';
  }

  // Reiniciar estadísticas
  void reiniciar() {
    totalAlarmas = 0;
    alarmasCompletadas = 0;
    alarmasCanceladas = 0;
    alarmasVencidas = 0;
    fechaUltimaAlarma = DateTime.now();
    tiempoPromedioRespuesta = Duration.zero;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAlarmas': totalAlarmas,
      'alarmasCompletadas': alarmasCompletadas,
      'alarmasCanceladas': alarmasCanceladas,
      'alarmasVencidas': alarmasVencidas,
      'fechaUltimaAlarma': fechaUltimaAlarma.toIso8601String(),
      'tiempoPromedioRespuesta': tiempoPromedioRespuesta.inSeconds,
    };
  }

  factory AlarmaEstadisticas.fromJson(Map<String, dynamic> json) {
    return AlarmaEstadisticas(
      totalAlarmas: json['totalAlarmas'] ?? 0,
      alarmasCompletadas: json['alarmasCompletadas'] ?? 0,
      alarmasCanceladas: json['alarmasCanceladas'] ?? 0,
      alarmasVencidas: json['alarmasVencidas'] ?? 0,
      fechaUltimaAlarma: json['fechaUltimaAlarma'] != null
          ? DateTime.parse(json['fechaUltimaAlarma'])
          : DateTime.now(),
      tiempoPromedioRespuesta: Duration(
        seconds: json['tiempoPromedioRespuesta'] ?? 0,
      ),
    );
  }
}
