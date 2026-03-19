package com.example.agenda_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver de respaldo.
 * La alarma nativa ahora se crea directamente desde MainActivity
 * usando AlarmClock.ACTION_SET_ALARM. Este receiver se mantiene
 * por compatibilidad pero ya no es el flujo principal.
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e("AlarmReceiver", "Context o Intent nulos")
            return
        }
        
        val cliente = intent.getStringExtra("cliente") ?: "Cliente"
        val equipo = intent.getStringExtra("equipo") ?: "Equipo"
        
        Log.d("AlarmReceiver", "🔔 Broadcast recibido (fallback): $cliente - $equipo")
    }
}

