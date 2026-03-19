package com.example.agenda_flutter

import android.content.Intent
import android.os.Build
import android.provider.AlarmClock
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.agenda_flutter/alarm"
    private val TAG = "AgendaTeran"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setNativeAlarm" -> {
                        val cliente = call.argument<String>("cliente") ?: "Cliente"
                        val equipo = call.argument<String>("equipo") ?: "Equipo"
                        val hora = call.argument<Int>("hora") ?: 0
                        val minuto = call.argument<Int>("minuto") ?: 0
                        
                        val success = setNativeAlarm(cliente, equipo, hora, minuto)
                        result.success(success)
                    }
                    "dismissNativeAlarm" -> {
                        val cliente = call.argument<String>("cliente") ?: "Cliente"
                        val equipo = call.argument<String>("equipo") ?: "Equipo"
                        
                        val success = dismissNativeAlarm(cliente, equipo)
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    /**
     * Crea una alarma directamente en la app Reloj nativa del teléfono.
     * El label muestra: "Servicio: NombreCliente - Equipo"
     * Se usa EXTRA_SKIP_UI=true para no abrir la UI del Reloj.
     */
    private fun setNativeAlarm(cliente: String, equipo: String, hora: Int, minuto: Int): Boolean {
        val label = "Servicio: $cliente - $equipo"
        Log.d(TAG, "╔════════════════════════════════════════╗")
        Log.d(TAG, "║ ⏰ CREANDO ALARMA NATIVA")
        Log.d(TAG, "║ Label: $label")
        Log.d(TAG, "║ Hora: $hora:${minuto.toString().padStart(2, '0')}")
        Log.d(TAG, "╚════════════════════════════════════════╝")
        
        val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
            putExtra(AlarmClock.EXTRA_HOUR, hora)
            putExtra(AlarmClock.EXTRA_MINUTES, minuto)
            putExtra(AlarmClock.EXTRA_MESSAGE, label)
            putExtra(AlarmClock.EXTRA_SKIP_UI, true)  // No abrir la UI del Reloj
            putExtra(AlarmClock.EXTRA_VIBRATE, true)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        
        return try {
            startActivity(intent)
            Log.d(TAG, "✅ Alarma nativa creada: $label a las $hora:${minuto.toString().padStart(2, '0')}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error creando alarma nativa: ${e.message}", e)
            false
        }
    }

    /**
     * Elimina la alarma nativa del Reloj buscándola por su label.
     * Requiere API 23+ (Android 6.0).
     * Se llama cuando el usuario acepta/descarta la alarma en la app.
     */
    private fun dismissNativeAlarm(cliente: String, equipo: String): Boolean {
        val label = "Servicio: $cliente - $equipo"
        Log.d(TAG, "╔════════════════════════════════════════╗")
        Log.d(TAG, "║ 🗑️ ELIMINANDO ALARMA NATIVA")
        Log.d(TAG, "║ Label: $label")
        Log.d(TAG, "╚════════════════════════════════════════╝")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            Log.w(TAG, "⚠️ ACTION_DISMISS_ALARM requiere API 23+. Versión actual: ${Build.VERSION.SDK_INT}")
            return false
        }

        val intent = Intent(AlarmClock.ACTION_DISMISS_ALARM).apply {
            putExtra(AlarmClock.EXTRA_ALARM_SEARCH_MODE, AlarmClock.ALARM_SEARCH_MODE_LABEL)
            putExtra(AlarmClock.EXTRA_MESSAGE, label)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        
        return try {
            startActivity(intent)
            Log.d(TAG, "✅ Alarma nativa eliminada: $label")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error eliminando alarma nativa: ${e.message}", e)
            false
        }
    }
}
