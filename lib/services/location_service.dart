import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/ubicacion.dart';

class LocationService {
  // Obtener posición actual del usuario
  Future<Position?> obtenerPosicionActual() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servicio de ubicación deshabilitado');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permiso de ubicación denegado');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permiso de ubicación permanentemente denegado');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error al obtener ubicación: $e');
      return null;
    }
  }

  // Convertir dirección a coordenadas (Geocoding)
  Future<Ubicacion?> obtenerCoordenadasDeDir(String direccion) async {
    try {
      List<Location> locations = await locationFromAddress(direccion);

      if (locations.isEmpty) {
        print('No se encontraron coordenadas para: $direccion');
        return null;
      }

      Location location = locations.first;

      // Obtener información de la dirección invertida
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      Placemark? placemark = placemarks.isNotEmpty ? placemarks.first : null;

      return Ubicacion(
        latitud: location.latitude,
        longitud: location.longitude,
        direccion: direccion,
        ciudad: placemark?.locality ?? '',
        pais: placemark?.country ?? '',
        fechaActualizacion: DateTime.now(),
      );
    } catch (e) {
      print('Error en geocoding: $e');
      return null;
    }
  }

  // Convertir coordenadas a dirección (Reverse Geocoding)
  Future<String?> obtenerDireccionDeCoord(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) {
        return null;
      }

      Placemark place = placemarks.first;
      return '${place.street}, ${place.postalCode} ${place.locality}, ${place.country}';
    } catch (e) {
      print('Error en reverse geocoding: $e');
      return null;
    }
  }

  // Calcular distancia entre dos puntos (en metros)
  double calcularDistancia(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
