import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;
  bool _initialized = false;

  // Sonidos disponibles por defecto
  static const Map<String, String> defaultSounds = {
    'alarma_10': 'alarma_10.mp3',
    'bell': 'rs8t6ehpca-bell-1.mp3',
  };

  static const String _prefKeySelectedSound = 'selected_alarm_sound';
  String _selectedSound = 'alarma_10'; // Por defecto

  Future<void> initialize() async {
    if (_initialized) return;

    _audioPlayer = AudioPlayer();

    // Cargar el sonido seleccionado guardado
    final prefs = await SharedPreferences.getInstance();
    _selectedSound = prefs.getString(_prefKeySelectedSound) ?? 'alarma_10';

    _initialized = true;
    debugPrint('✅ Audio Service inicializado');
  }

  // Reproducir sonido de alarma en loop
  Future<void> playAlarmSound() async {
    if (!_initialized) await initialize();

    try {
      final soundPath = defaultSounds[_selectedSound];
      if (soundPath == null) {
        debugPrint('❌ Sonido no encontrado: $_selectedSound');
        debugPrint('   Sonidos disponibles: ${defaultSounds.keys.toList()}');
        return;
      }

      debugPrint('');
      debugPrint('🔊 ═══════════════ INICIANDO REPRODUCCIÓN ═══════════════');
      debugPrint('🔊 Sonido seleccionado: $_selectedSound');
      debugPrint('🔊 Ruta asset: $soundPath');
      debugPrint('🔊 AssetSource path: assets/$soundPath');

      // IMPORTANTE: Reinicializar el AudioPlayer para evitar problemas
      debugPrint('🔊 Reinicializando AudioPlayer...');
      try {
        await _audioPlayer.dispose();
      } catch (e) {
        debugPrint('⚠️ Error disposing anterior: $e');
      }
      _audioPlayer = AudioPlayer();
      debugPrint('🔊 AudioPlayer reinicializado');

      debugPrint('🔊 Estado inicial del player: ${_audioPlayer.state}');

      // Esperar un poco para asegurar que el player está listo
      await Future.delayed(const Duration(milliseconds: 200));

      // Configurar para reproducir en loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      debugPrint('🔊 Release mode configurado: loop');

      // Configurar volumen al máximo
      await _audioPlayer.setVolume(1.0);
      debugPrint('🔊 Volumen configurado: 1.0');

      debugPrint('🔊 Intentando reproducir: AssetSource($soundPath)');

      // Reproducir
      await _audioPlayer.play(AssetSource(soundPath));
      debugPrint('🔊 play() ejecutado');
      debugPrint('🔊 Estado después de play(): ${_audioPlayer.state}');

      // Configurar listeners para debugging
      _audioPlayer.onPlayerStateChanged.listen((state) {
        debugPrint('🔊 [LISTENER] Estado cambió a: $state');
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('🔊 [LISTENER] Sonido completado (loop debería reiniciar)');
      });

      _audioPlayer.onDurationChanged.listen((duration) {
        debugPrint('🔊 [LISTENER] Duración actualizada: $duration');
      });

      // Verificar estado final
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('🔊 Estado final: ${_audioPlayer.state}');

      if (_audioPlayer.state == PlayerState.playing) {
        debugPrint('✅ ✅ ✅ SONIDO REPRODUCIÉNDOSE CORRECTAMENTE ✅ ✅ ✅');
      } else {
        debugPrint('❌ ❌ ❌ ADVERTENCIA: Player NO está en PLAYING ❌ ❌ ❌');
        debugPrint('    Estado actual: ${_audioPlayer.state}');
      }

      debugPrint('🔊 ═══════════════ FIN DE INICIALIZACIÓN ═══════════════');
      debugPrint('');
    } catch (e) {
      debugPrint('');
      debugPrint('❌ ❌ ❌ ERROR REPRODUCIENDO SONIDO ❌ ❌ ❌');
      debugPrint('❌ Mensaje: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      debugPrint('');
    }
  }

  // Detener sonido
  Future<void> stopSound() async {
    if (!_initialized) await initialize();
    await _audioPlayer.stop();
    debugPrint('⏹️ Sonido detenido');
  }

  // Obtener el sonido seleccionado
  String getSelectedSound() => _selectedSound;

  // Cambiar sonido seleccionado
  Future<void> setSelectedSound(String soundKey) async {
    if (!_initialized) await initialize();

    if (!defaultSounds.containsKey(soundKey)) {
      debugPrint('❌ Sonido no válido: $soundKey');
      return;
    }

    _selectedSound = soundKey;

    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySelectedSound, soundKey);

    debugPrint('✅ Sonido seleccionado: $soundKey');
  }

  // Reproducir vista previa del sonido (sin loop)
  Future<void> previewSound(String soundKey) async {
    if (!_initialized) await initialize();

    if (!defaultSounds.containsKey(soundKey)) {
      debugPrint('❌ Sonido no válido: $soundKey');
      return;
    }

    try {
      final soundPath = defaultSounds[soundKey];
      // La vista previa se reproduce una sola vez (sin loop)
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(AssetSource(soundPath!));
      debugPrint('🔊 Vista previa: $soundKey');
    } catch (e) {
      debugPrint('❌ Error en vista previa: $e');
    }
  }

  // Obtener lista de sonidos disponibles
  Map<String, String> getSoundsList() => defaultSounds;

  // Obtener nombre legible del sonido
  String getSoundDisplayName(String soundKey) {
    final names = {'alarma_10': '🔔 Alarma 1', 'bell': '🔊 Campana'};
    return names[soundKey] ?? soundKey;
  }

  // Dispose
  void dispose() {
    if (_initialized) {
      _audioPlayer.dispose();
    }
  }
}
