import 'package:intl/intl.dart';

class Usuario {
  String nombre;
  String apellido;
  String email;
  String telefono;
  String? fotoUrl;
  String empresa;
  String cargo;
  DateTime fechaRegistro;
  DateTime? ultimoAcceso;
  bool notificacionesActivas;
  String? tokenNotificaciones;
  Map<String, dynamic> preferencias;

  Usuario({
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    this.fotoUrl,
    this.empresa = '',
    this.cargo = '',
    DateTime? fechaRegistro,
    this.ultimoAcceso,
    this.notificacionesActivas = true,
    this.tokenNotificaciones,
    this.preferencias = const {},
  }) : fechaRegistro = fechaRegistro ?? DateTime.now();

  String get nombreCompleto => '$nombre $apellido';

  String get iniciales {
    final nombreInicial = nombre.isNotEmpty ? nombre[0] : '';
    final apellidoInicial = apellido.isNotEmpty ? apellido[0] : '';
    return '$nombreInicial$apellidoInicial'.toUpperCase();
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      telefono: json['telefono'],
      fotoUrl: json['fotoUrl'],
      empresa: json['empresa'] ?? '',
      cargo: json['cargo'] ?? '',
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      ultimoAcceso: json['ultimoAcceso'] != null
          ? DateTime.parse(json['ultimoAcceso'])
          : null,
      notificacionesActivas: json['notificacionesActivas'] ?? true,
      tokenNotificaciones: json['tokenNotificaciones'],
      preferencias: Map<String, dynamic>.from(json['preferencias'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'fotoUrl': fotoUrl,
      'empresa': empresa,
      'cargo': cargo,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'ultimoAcceso': ultimoAcceso?.toIso8601String(),
      'notificacionesActivas': notificacionesActivas,
      'tokenNotificaciones': tokenNotificaciones,
      'preferencias': preferencias,
    };
  }

  Usuario copyWith({
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? fotoUrl,
    String? empresa,
    String? cargo,
    bool? notificacionesActivas,
    String? tokenNotificaciones,
    Map<String, dynamic>? preferencias,
  }) {
    return Usuario(
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      empresa: empresa ?? this.empresa,
      cargo: cargo ?? this.cargo,
      fechaRegistro: fechaRegistro,
      ultimoAcceso: ultimoAcceso,
      notificacionesActivas:
          notificacionesActivas ?? this.notificacionesActivas,
      tokenNotificaciones: tokenNotificaciones ?? this.tokenNotificaciones,
      preferencias: preferencias ?? this.preferencias,
    );
  }

  String fechaRegistroFormateada() {
    return DateFormat('dd/MM/yyyy').format(fechaRegistro);
  }

  String ultimoAccesoFormateado() {
    if (ultimoAcceso == null) return 'Nunca';
    return DateFormat('dd/MM/yyyy HH:mm').format(ultimoAcceso!);
  }

  void actualizarUltimoAcceso() {
    ultimoAcceso = DateTime.now();
  }

  bool esValido() {
    return nombre.isNotEmpty && email.isNotEmpty && telefono.isNotEmpty;
  }

  @override
  String toString() {
    return 'Usuario{nombre: $nombre, email: $email, telefono: $telefono}';
  }
}

// Usuario por defecto para Cutberto Terán Morales
extension UsuarioDefault on Usuario {
  static Usuario get cutbertoTeran {
    return Usuario(
      nombre: 'Cutberto',
      apellido: 'Terán Morales',
      email: 'cutberto@teran.com',
      telefono: '',
      empresa: 'Téran Mantenimientos',
      cargo: 'Técnico Especializado',
      preferencias: {
        'tema': 'oscuro',
        'idioma': 'es',
        'moneda': 'MXN',
        'zonaHoraria': 'America/Mexico_City',
        'formatoFecha': 'dd/MM/yyyy',
        'notificacionesAlarma': true,
        'pantallaCompleta': true,
        'vibracion': true,
        'sonido': true,
      },
    );
  }
}
