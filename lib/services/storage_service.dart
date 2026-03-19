import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recordatorio.dart';
import '../models/alarma_config.dart';
import '../models/usuario.dart';

class StorageService {
  static const String _dbName = 'agenda_teran.db';
  static const int _dbVersion = 1;

  static const String _prefsRecordatorios = 'recordatorios_guardados';
  static const String _prefsConfigAlarma = 'config_alarma';
  static const String _prefsUsuario = 'usuario_actual';

  Database? _database;
  SharedPreferences? _prefs;

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Inicializar servicio
  Future<void> init() async {
    await _initDatabase();
    await _initSharedPreferences();
  }

  // Inicializar base de datos SQLite
  Future<void> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(documentsDirectory.path, _dbName);

      _database = await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      debugPrint('✅ Base de datos inicializada en: $dbPath');
    } catch (e) {
      debugPrint('❌ Error inicializando base de datos: $e');
      rethrow;
    }
  }

  // Crear tablas de la base de datos
  Future<void> _createDatabase(Database db, int version) async {
    // Tabla de recordatorios
    await db.execute('''
      CREATE TABLE recordatorios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        telefono TEXT,
        email TEXT,
        fecha_servicio TEXT NOT NULL,
        frecuencia TEXT NOT NULL,
        equipo TEXT NOT NULL,
        ubicacion TEXT,
        observaciones TEXT,
        fecha_proximo_mantenimiento TEXT NOT NULL,
        dias_frecuencia INTEGER NOT NULL,
        alarma_programada INTEGER DEFAULT 0,
        fecha_alarma TEXT,
        notificacion_programada INTEGER DEFAULT 0,
        fecha_notificacion TEXT,
        fecha_creacion TEXT NOT NULL,
        fecha_modificacion TEXT NOT NULL
      )
    ''');

    // Tabla de configuraciones de alarma
    await db.execute('''
      CREATE TABLE config_alarmas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sonido_seleccionado TEXT,
        vibracion_seleccionada TEXT,
        volumen INTEGER,
        vibrar INTEGER,
        sonido INTEGER,
        pantalla_completa INTEGER,
        despertar_pantalla INTEGER,
        modo_silencioso INTEGER,
        duracion_alarma INTEGER,
        repetir_alarma INTEGER,
        repeticiones_maximas INTEGER,
        prueba_automatica INTEGER,
        notificaciones_push INTEGER,
        recordatorio_previo INTEGER,
        tiempo_recordatorio_previo INTEGER
      )
    ''');

    // Tabla de estadísticas
    await db.execute('''
      CREATE TABLE estadisticas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_alarmas INTEGER DEFAULT 0,
        alarmas_completadas INTEGER DEFAULT 0,
        alarmas_canceladas INTEGER DEFAULT 0,
        alarmas_vencidas INTEGER DEFAULT 0,
        fecha_ultima_alarma TEXT,
        tiempo_promedio_respuesta INTEGER DEFAULT 0
      )
    ''');

    // Insertar configuración por defecto
    final defaultConfig = AlarmaConfig.defaultConfig.toJson();
    await db.insert('config_alarmas', defaultConfig);

    debugPrint('✅ Base de datos creada con éxito');
  }

  // Actualizar base de datos (para futuras versiones)
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('🔄 Actualizando base de datos de $oldVersion a $newVersion');

    if (oldVersion < 2) {
      // Aquí irían las migraciones para la versión 2
      // Ejemplo: await db.execute('ALTER TABLE recordatorios ADD COLUMN nueva_columna TEXT');
    }
  }

  // Inicializar SharedPreferences
  Future<void> _initSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ SharedPreferences inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando SharedPreferences: $e');
    }
  }

  // =================== CRUD Recordatorios ===================

  // Guardar recordatorio
  Future<int> guardarRecordatorio(Recordatorio recordatorio) async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      // Si tiene ID, actualizar; si no, insertar
      if (recordatorio.id != null) {
        final id = await db.update(
          'recordatorios',
          recordatorio.toJson(),
          where: 'id = ?',
          whereArgs: [recordatorio.id],
        );

        debugPrint('✅ Recordatorio actualizado: ${recordatorio.cliente}');
        return id;
      } else {
        final id = await db.insert('recordatorios', recordatorio.toJson());

        // Guardar también en SharedPreferences para compatibilidad
        await _guardarRecordatorioEnPrefs(recordatorio.copyWith(id: id));

        debugPrint(
          '✅ Recordatorio guardado: ${recordatorio.cliente} (ID: $id)',
        );
        return id;
      }
    } catch (e) {
      debugPrint('❌ Error guardando recordatorio: $e');
      rethrow;
    }
  }

  // Obtener todos los recordatorios
  Future<List<Recordatorio>> getRecordatorios() async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      final records = await db.query(
        'recordatorios',
        orderBy: 'fecha_proximo_mantenimiento ASC',
      );

      final recordatorios = records.map((record) {
        return Recordatorio.fromJson(record);
      }).toList();

      debugPrint('📋 Recordatorios cargados: ${recordatorios.length}');
      return recordatorios;
    } catch (e) {
      debugPrint('❌ Error obteniendo recordatorios: $e');

      // Fallback a SharedPreferences
      return await _getRecordatoriosDePrefs();
    }
  }

  // Obtener recordatorio por ID
  Future<Recordatorio?> getRecordatorioPorId(int id) async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      final records = await db.query(
        'recordatorios',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (records.isEmpty) return null;

      return Recordatorio.fromJson(records.first);
    } catch (e) {
      debugPrint('❌ Error obteniendo recordatorio por ID: $e');
      return null;
    }
  }

  // Actualizar recordatorio
  Future<int> actualizarRecordatorio(Recordatorio recordatorio) async {
    return await guardarRecordatorio(recordatorio);
  }

  // Eliminar recordatorio
  Future<int> eliminarRecordatorio(int id) async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      final result = await db.delete(
        'recordatorios',
        where: 'id = ?',
        whereArgs: [id],
      );

      // También eliminar de SharedPreferences
      await _eliminarRecordatorioDePrefs(id);

      debugPrint('🗑️ Recordatorio eliminado: ID $id');
      return result;
    } catch (e) {
      debugPrint('❌ Error eliminando recordatorio: $e');
      rethrow;
    }
  }

  // =================== Configuraciones ===================

  // Guardar configuración de alarma
  Future<void> guardarConfigAlarma(AlarmaConfig config) async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      await db.update('config_alarmas', config.toJson(), where: 'id = 1');

      // Guardar también en SharedPreferences
      await _guardarConfigAlarmaEnPrefs(config);

      debugPrint('✅ Configuración de alarma guardada');
    } catch (e) {
      debugPrint('❌ Error guardando configuración de alarma: $e');
    }
  }

  // Obtener configuración de alarma
  Future<AlarmaConfig> getConfigAlarma() async {
    try {
      // Primero intentar desde SharedPreferences
      final configPrefs = await _getConfigAlarmaDePrefs();
      if (configPrefs != null) return configPrefs;

      // Fallback a base de datos
      final db = _database;
      if (db != null) {
        final records = await db.query('config_alarmas', where: 'id = 1');
        if (records.isNotEmpty) {
          return AlarmaConfig.fromJson(records.first);
        }
      }

      // Si no hay nada, devolver configuración por defecto
      return AlarmaConfig.defaultConfig;
    } catch (e) {
      debugPrint('❌ Error obteniendo configuración de alarma: $e');
      return AlarmaConfig.defaultConfig;
    }
  }

  // =================== Usuario ===================

  // Guardar usuario
  Future<void> guardarUsuario(Usuario usuario) async {
    try {
      await _prefs?.setString(_prefsUsuario, jsonEncode(usuario.toJson()));
      debugPrint('✅ Usuario guardado: ${usuario.nombreCompleto}');
    } catch (e) {
      debugPrint('❌ Error guardando usuario: $e');
    }
  }

  // Obtener usuario
  Future<Usuario?> getUsuario() async {
    try {
      final usuarioJson = _prefs?.getString(_prefsUsuario);
      if (usuarioJson != null) {
        return Usuario.fromJson(jsonDecode(usuarioJson));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  // =================== Estadísticas ===================

  // Guardar estadísticas
  Future<void> guardarEstadisticas(AlarmaEstadisticas estadisticas) async {
    try {
      final db = _database;
      if (db == null) throw Exception('Base de datos no inicializada');

      await db.update('estadisticas', estadisticas.toJson(), where: 'id = 1');

      debugPrint('✅ Estadísticas guardadas');
    } catch (e) {
      debugPrint('❌ Error guardando estadísticas: $e');
    }
  }

  // Obtener estadísticas
  Future<AlarmaEstadisticas> getEstadisticas() async {
    try {
      final db = _database;
      if (db != null) {
        final records = await db.query('estadisticas', where: 'id = 1');
        if (records.isNotEmpty) {
          return AlarmaEstadisticas.fromJson(records.first);
        }
      }

      // Si no hay estadísticas, crear unas nuevas
      return AlarmaEstadisticas();
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return AlarmaEstadisticas();
    }
  }

  // =================== Métodos de compatibilidad (SharedPreferences) ===================

  // Guardar recordatorio en SharedPreferences (para compatibilidad)
  Future<void> _guardarRecordatorioEnPrefs(Recordatorio recordatorio) async {
    try {
      final recordatorios = await _getRecordatoriosDePrefs();
      recordatorios.add(recordatorio);

      final recordatoriosJson = recordatorios.map((r) => r.toJson()).toList();
      await _prefs?.setString(
        _prefsRecordatorios,
        jsonEncode(recordatoriosJson),
      );
    } catch (e) {
      debugPrint('❌ Error guardando recordatorio en prefs: $e');
    }
  }

  // Obtener recordatorios de SharedPreferences
  Future<List<Recordatorio>> _getRecordatoriosDePrefs() async {
    try {
      final recordatoriosJson = _prefs?.getString(_prefsRecordatorios);
      if (recordatoriosJson != null) {
        final List<dynamic> data = jsonDecode(recordatoriosJson);
        return data.map((json) => Recordatorio.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo recordatorios de prefs: $e');
      return [];
    }
  }

  // Eliminar recordatorio de SharedPreferences
  Future<void> _eliminarRecordatorioDePrefs(int id) async {
    try {
      final recordatorios = await _getRecordatoriosDePrefs();
      recordatorios.removeWhere((r) => r.id == id);

      final recordatoriosJson = recordatorios.map((r) => r.toJson()).toList();
      await _prefs?.setString(
        _prefsRecordatorios,
        jsonEncode(recordatoriosJson),
      );
    } catch (e) {
      debugPrint('❌ Error eliminando recordatorio de prefs: $e');
    }
  }

  // Guardar configuración de alarma en SharedPreferences
  Future<void> _guardarConfigAlarmaEnPrefs(AlarmaConfig config) async {
    try {
      await _prefs?.setString(_prefsConfigAlarma, jsonEncode(config.toJson()));
    } catch (e) {
      debugPrint('❌ Error guardando config alarma en prefs: $e');
    }
  }

  // Obtener configuración de alarma de SharedPreferences
  Future<AlarmaConfig?> _getConfigAlarmaDePrefs() async {
    try {
      final configJson = _prefs?.getString(_prefsConfigAlarma);
      if (configJson != null) {
        return AlarmaConfig.fromJson(jsonDecode(configJson));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo config alarma de prefs: $e');
      return null;
    }
  }

  // =================== Utilidades ===================

  // Exportar base de datos
  Future<File?> exportDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbFile = File(path.join(documentsDirectory.path, _dbName));

      if (await dbFile.exists()) {
        final exportDir = await getExternalStorageDirectory();
        if (exportDir != null) {
          final exportFile = File(
            path.join(exportDir.path, 'agenda_teran_backup.db'),
          );
          await dbFile.copy(exportFile.path);
          return exportFile;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error exportando base de datos: $e');
      return null;
    }
  }

  // Importar base de datos
  Future<bool> importDatabase(File file) async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbFile = File(path.join(documentsDirectory.path, _dbName));

      await file.copy(dbFile.path);

      // Reinicializar base de datos
      await _initDatabase();

      return true;
    } catch (e) {
      debugPrint('❌ Error importando base de datos: $e');
      return false;
    }
  }

  // Limpiar todos los datos
  Future<void> clearAllData() async {
    try {
      // Limpiar base de datos
      final db = _database;
      if (db != null) {
        await db.delete('recordatorios');
        await db.delete('config_alarmas');
        await db.delete('estadisticas');
      }

      // Limpiar SharedPreferences
      await _prefs?.clear();

      debugPrint('🧹 Todos los datos limpiados');
    } catch (e) {
      debugPrint('❌ Error limpiando datos: $e');
    }
  }

  // Cerrar base de datos
  Future<void> close() async {
    await _database?.close();
    _database = null;
    debugPrint('🔒 Base de datos cerrada');
  }
}
