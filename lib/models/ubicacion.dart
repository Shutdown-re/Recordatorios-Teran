class Ubicacion {
  double latitud;
  double longitud;
  String direccion;
  String? ciudad;
  String? pais;
  DateTime? fechaActualizacion;

  Ubicacion({
    required this.latitud,
    required this.longitud,
    required this.direccion,
    this.ciudad,
    this.pais,
    this.fechaActualizacion,
  });

  // Constructor desde JSON
  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      pais: json['pais'],
      fechaActualizacion: json['fechaActualizacion'] != null
          ? DateTime.parse(json['fechaActualizacion'])
          : null,
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
      'ciudad': ciudad,
      'pais': pais,
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Ubicacion($latitud, $longitud, $direccion)';
}
