import 'package:intl/intl.dart';

class Recordatorio {
  int? id;
  String cliente;
  String telefono;
  String email;
  DateTime fechaServicio;
  String frecuencia;
  String equipo;
  String ubicacion;
  String observaciones;
  DateTime fechaProximoMantenimiento;
  int diasFrecuencia;
  bool alarmaProgramada;
  DateTime? fechaAlarma;
  bool notificacionProgramada;
  DateTime? fechaNotificacion;
  DateTime fechaCreacion;
  DateTime fechaModificacion;

  Recordatorio({
    this.id,
    required this.cliente,
    this.telefono = '',
    this.email = '',
    required this.fechaServicio,
    required this.frecuencia,
    required this.equipo,
    this.ubicacion = '',
    this.observaciones = '',
    required this.fechaProximoMantenimiento,
    required this.diasFrecuencia,
    this.alarmaProgramada = false,
    this.fechaAlarma,
    this.notificacionProgramada = false,
    this.fechaNotificacion,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now(),
       fechaModificacion = fechaModificacion ?? DateTime.now();

  // Constructor desde JSON
  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    return Recordatorio(
      id: json['id'],
      cliente: json['cliente'],
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      fechaServicio: DateTime.parse(json['fecha_servicio']),
      frecuencia: json['frecuencia'],
      equipo: json['equipo'],
      ubicacion: json['ubicacion'] ?? '',
      observaciones: json['observaciones'] ?? '',
      fechaProximoMantenimiento: DateTime.parse(
        json['fecha_proximo_mantenimiento'],
      ),
      diasFrecuencia:
          json['dias_frecuencia'] ?? calcularDiasFrecuencia(json['frecuencia']),
      alarmaProgramada: (json['alarma_programada'] as int?) == 1 ? true : false,
      fechaAlarma: json['fecha_alarma'] != null
          ? DateTime.parse(json['fecha_alarma'])
          : null,
      notificacionProgramada: (json['notificacion_programada'] as int?) == 1
          ? true
          : false,
      fechaNotificacion: json['fecha_notificacion'] != null
          ? DateTime.parse(json['fecha_notificacion'])
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
      fechaModificacion: json['fecha_modificacion'] != null
          ? DateTime.parse(json['fecha_modificacion'])
          : DateTime.now(),
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cliente': cliente,
      'telefono': telefono,
      'email': email,
      'fecha_servicio': fechaServicio.toIso8601String(),
      'frecuencia': frecuencia,
      'equipo': equipo,
      'ubicacion': ubicacion,
      'observaciones': observaciones,
      'fecha_proximo_mantenimiento': fechaProximoMantenimiento
          .toIso8601String(),
      'dias_frecuencia': diasFrecuencia,
      'alarma_programada': alarmaProgramada,
      'fecha_alarma': fechaAlarma?.toIso8601String(),
      'notificacion_programada': notificacionProgramada,
      'fecha_notificacion': fechaNotificacion?.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_modificacion': fechaModificacion.toIso8601String(),
    };
  }

  // Método para copiar con cambios
  Recordatorio copyWith({
    int? id,
    String? cliente,
    String? telefono,
    String? email,
    DateTime? fechaServicio,
    String? frecuencia,
    String? equipo,
    String? ubicacion,
    String? observaciones,
    DateTime? fechaProximoMantenimiento,
    int? diasFrecuencia,
    bool? alarmaProgramada,
    DateTime? fechaAlarma,
    bool? notificacionProgramada,
    DateTime? fechaNotificacion,
  }) {
    return Recordatorio(
      id: id ?? this.id,
      cliente: cliente ?? this.cliente,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      fechaServicio: fechaServicio ?? this.fechaServicio,
      frecuencia: frecuencia ?? this.frecuencia,
      equipo: equipo ?? this.equipo,
      ubicacion: ubicacion ?? this.ubicacion,
      observaciones: observaciones ?? this.observaciones,
      fechaProximoMantenimiento:
          fechaProximoMantenimiento ?? this.fechaProximoMantenimiento,
      diasFrecuencia: diasFrecuencia ?? this.diasFrecuencia,
      alarmaProgramada: alarmaProgramada ?? this.alarmaProgramada,
      fechaAlarma: fechaAlarma ?? this.fechaAlarma,
      notificacionProgramada:
          notificacionProgramada ?? this.notificacionProgramada,
      fechaNotificacion: fechaNotificacion ?? this.fechaNotificacion,
      fechaCreacion: fechaCreacion,
      fechaModificacion: DateTime.now(),
    );
  }

  // Calcular fecha del próximo mantenimiento basado en la frecuencia
  static DateTime calcularFechaProximo(
    DateTime fechaServicio,
    String frecuencia,
  ) {
    final dias = calcularDiasFrecuencia(frecuencia);
    return fechaServicio.add(Duration(days: dias));
  }

  // Obtener días de frecuencia
  static int calcularDiasFrecuencia(String frecuencia) {
    switch (frecuencia) {
      // DÍAS
      case '1 día':
        return 1;
      case '2 días':
        return 2;
      case '3 días':
        return 3;
      case '4 días':
        return 4;
      case '5 días':
        return 5;
      case '6 días':
        return 6;
      case '7 días':
        return 7;
      case '8 días':
        return 8;
      case '9 días':
        return 9;
      case '10 días':
        return 10;
      case '11 días':
        return 11;
      case '12 días':
        return 12;
      case '13 días':
        return 13;
      case '14 días':
        return 14;
      case '15 días':
        return 15;

      // MESES (convertir a días aproximados)
      case '1 mes':
        return 30;
      case '2 meses':
        return 60;
      case '3 meses':
        return 90;
      case '4 meses':
        return 120;
      case '5 meses':
        return 150;
      case '6 meses':
        return 180;
      case '7 meses':
        return 210;
      case '8 meses':
        return 240;
      case '9 meses':
        return 270;
      case '10 meses':
        return 300;
      case '11 meses':
        return 330;
      case '1 año':
        return 365;
      case '1.5 años':
        return 548; // 365 * 1.5
      case '2 años':
        return 730; // 365 * 2
      case '2.5 años':
        return 913; // 365 * 2.5
      case '3 años':
        return 1095; // 365 * 3
      default:
        return 30;
    }
  }

  // Verificar si está vencido
  bool estaVencido() {
    final ahora = DateTime.now();

    // Si la fecha próxima es en el futuro (incluso si es hoy), no está vencida
    if (fechaProximoMantenimiento.isAfter(ahora)) {
      return false;
    }

    // Si la fecha próxima es hoy, solo está vencida si ya pasó la hora específica
    if (fechaProximoMantenimiento.day == ahora.day &&
        fechaProximoMantenimiento.month == ahora.month &&
        fechaProximoMantenimiento.year == ahora.year) {
      // Es hoy. Verificar si ya pasó la hora específica en fechaProximoMantenimiento
      return fechaProximoMantenimiento.isBefore(ahora);
    }

    // Si la fecha próxima es antes de hoy, está vencida
    return true;
  }

  // Verificar si es próximo (menos de 7 días)
  bool esProximo() {
    final diferencia = fechaProximoMantenimiento.difference(DateTime.now());
    return diferencia.inDays <= 7 && diferencia.inDays >= 0;
  }

  // Días para el próximo mantenimiento
  int diasParaProximo() {
    final diferencia = fechaProximoMantenimiento.difference(DateTime.now());
    return diferencia.inDays;
  }

  // Calcular fecha de alarma (usar la hora del próximo mantenimiento)
  // Si el usuario definió hora, se usa esa hora.
  // Si la hora es medianoche (00:00), se asume que no se definió hora y se usa 8:00 AM.
  DateTime calcularFechaAlarma() {
    // Si la hora es 0:00 (no se definió hora específica), usar 8:00 AM por defecto
    if (fechaProximoMantenimiento.hour == 0 &&
        fechaProximoMantenimiento.minute == 0) {
      return DateTime(
        fechaProximoMantenimiento.year,
        fechaProximoMantenimiento.month,
        fechaProximoMantenimiento.day,
        8, // 8:00 AM por defecto
        0,
        0,
      );
    }
    // Usar la hora exacta que el usuario seleccionó
    return fechaProximoMantenimiento;
  }

  // Calcular fecha de notificación (1 día antes a las 6:00 PM)
  DateTime calcularFechaNotificacion() {
    final fechaNotificacion = fechaProximoMantenimiento.subtract(
      const Duration(days: 1),
    );
    return DateTime(
      fechaNotificacion.year,
      fechaNotificacion.month,
      fechaNotificacion.day,
      18, // 6:00 PM
      0,
      0,
    );
  }

  // Formatear fechas para mostrar
  String fechaServicioFormateada() {
    return DateFormat('dd/MM/yyyy').format(fechaServicio);
  }

  String fechaProximoFormateada() {
    return DateFormat('dd/MM/yyyy').format(fechaProximoMantenimiento);
  }

  String fechaServicioCompleta() {
    return DateFormat("dd 'de' MMMM 'de' yyyy", 'es_ES').format(fechaServicio);
  }

  String fechaProximoCompleta() {
    return DateFormat(
      "dd 'de' MMMM 'de' yyyy",
      'es_ES',
    ).format(fechaProximoMantenimiento);
  }

  String fechaCreacionFormateada() {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaCreacion);
  }

  String fechaModificacionFormateada() {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaModificacion);
  }

  // Validar datos
  bool esValido() {
    return cliente.isNotEmpty && equipo.isNotEmpty;
  }

  // Obtener estado como texto
  String get estado {
    if (estaVencido()) {
      return 'VENCIDO';
    } else if (esProximo()) {
      return 'PRÓXIMO';
    } else {
      return 'PENDIENTE';
    }
  }

  // Obtener color según estado
  int get colorEstado {
    if (estaVencido()) {
      return 0xFFFF5252; // Rojo
    } else if (esProximo()) {
      return 0xFFFF9800; // Naranja
    } else {
      return 0xFF4CAF50; // Verde
    }
  }

  // Obtener icono según estado
  String get iconoEstado {
    if (estaVencido()) {
      return '⚠️';
    } else if (esProximo()) {
      return '🔔';
    } else {
      return '📅';
    }
  }

  @override
  String toString() {
    return 'Recordatorio{id: $id, cliente: $cliente, equipo: $equipo, fechaProximo: $fechaProximoMantenimiento}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recordatorio &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          cliente == other.cliente &&
          fechaProximoMantenimiento == other.fechaProximoMantenimiento;

  @override
  int get hashCode => Object.hash(id, cliente, fechaProximoMantenimiento);
}
