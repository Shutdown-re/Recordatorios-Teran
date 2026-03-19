<div align="center">

# 📋 Recordatorios Terán

### Sistema de Gestión de Mantenimientos Preventivos

[![Flutter](https://img.shields.io/badge/Flutter-3.10.7+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API_36-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License](https://img.shields.io/badge/Licencia-Privada-red?style=for-the-badge)](LICENSE)

*Aplicación móvil desarrollada para **Terán Mantenimientos** que permite gestionar, programar y dar seguimiento a servicios de mantenimiento preventivo de equipos, con sistema de alarmas inteligentes integradas al reloj nativo de Android.*

---

</div>

## 🎯 Descripción General

**Recordatorios Terán** es una aplicación Flutter diseñada específicamente para técnicos de mantenimiento que necesitan llevar un control preciso de sus servicios programados. La app permite registrar clientes, equipos, ubicaciones y frecuencias de mantenimiento, generando automáticamente recordatorios y alarmas para que ningún servicio se pase por alto.

### ¿Para quién es?

- 🔧 **Técnicos de mantenimiento** que manejan múltiples clientes
- 🏢 **Empresas de servicios** que necesitan agendar visitas recurrentes
- 📅 **Profesionales independientes** que requieren un sistema confiable de recordatorios

---

## ✨ Características Principales

### 📝 Gestión de Recordatorios
- **Crear, editar y eliminar** recordatorios de mantenimiento
- Campos detallados: cliente, teléfono, email, equipo, ubicación, observaciones
- **Frecuencias configurables**: semanal, quincenal, mensual, bimestral, trimestral, semestral, anual
- Cálculo automático de la **próxima fecha de mantenimiento**
- Estados visuales con colores: 🟢 Pendiente, 🟠 Próximo, 🔴 Vencido

### ⏰ Sistema de Alarmas Inteligente
- **Integración con el Reloj nativo de Android** — las alarmas se registran directamente en la app de Reloj del teléfono
- Etiqueta personalizada: *"Servicio: NombreCliente - Equipo"*
- **Eliminación automática** de la alarma nativa al ser atendida
- **Snooze (posponer)** con cuenta atrás visual en la pantalla principal
- Banner animado que muestra el tiempo restante en formato `MM:SS` con barra de progreso
- Notificaciones locales como respaldo

### 🗺️ Mapa de Ubicaciones
- Mapa interactivo con **OpenStreetMap** (sin necesidad de API key)
- **Marcadores** para cada cliente con geocodificación automática
- **Panel lateral filtrable** con lista de todos los recordatorios
- Filtros por estado: Todos, Pendientes, Próximos, Vencidos
- **Búsqueda por nombre** de cliente, equipo o dirección
- Toca un recordatorio en la lista y el mapa **navega automáticamente** a su ubicación
- Marcadores resaltados con glow del color de estado
- Bottom sheet con detalles completos del servicio
- Modo selección para elegir ubicaciones al crear recordatorios

### 🏠 Pantalla Principal
- **Tarjeta de bienvenida** personalizada con el perfil del técnico
- **Dashboard de estadísticas** en tiempo real (pendientes, próximos, vencidos)
- **Acciones rápidas**: Nuevo recordatorio, Ver lista, Mapa, Configuración de sonido
- **Banner de snooze** con cuenta atrás cuando hay una alarma pospuesta
- Búsqueda y filtrado instantáneo
- Próximos servicios destacados

### 🔔 Notificaciones
- Notificaciones locales programadas
- Notificación previa (1 día antes del servicio)
- Acciones directas desde la notificación: **Aceptar** o **Posponer**
- Canal dedicado con sonido personalizado

### 🎵 Configuración de Sonidos
- Selección de tono de alarma desde la app
- Vista previa de sonidos antes de seleccionar
- Sonidos incluidos: Alarma clásica y Campana

### 💾 Almacenamiento
- Base de datos **SQLite** local para máxima velocidad
- Respaldo automático en **SharedPreferences**
- Persistencia completa sin necesidad de internet

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, configuración de providers
├── models/
│   ├── recordatorio.dart              # Modelo principal de recordatorio
│   ├── alarma_config.dart             # Configuración de alarmas
│   ├── ubicacion.dart                 # Modelo de ubicación (lat, lng, dirección)
│   └── usuario.dart                   # Modelo de usuario
├── screens/
│   ├── home_screen.dart               # Pantalla principal con dashboard
│   ├── welcome_screen.dart            # Pantalla de bienvenida
│   ├── add_recordatorio_screen.dart   # Crear nuevo recordatorio
│   ├── edit_recordatorio_screen.dart  # Editar recordatorio existente
│   ├── recordatorios_list_screen.dart # Lista completa de recordatorios
│   ├── mapas_screen.dart              # Mapa interactivo con panel filtrable
│   └── alarm_sound_settings_screen.dart # Configuración de sonidos
├── services/
│   ├── alarm_service.dart             # Gestión de alarmas + reloj nativo + snooze
│   ├── notification_service.dart      # Notificaciones locales
│   ├── storage_service.dart           # SQLite + SharedPreferences
│   ├── location_service.dart          # GPS + geocodificación
│   └── audio_service.dart             # Reproducción de sonidos
├── utils/
│   ├── theme.dart                     # Tema oscuro personalizado
│   ├── constants.dart                 # Constantes de la app
│   └── date_utils.dart                # Utilidades de fechas en español
└── widgets/
    ├── custom_app_bar.dart            # AppBar personalizado
    ├── recordatorio_card.dart         # Tarjeta de recordatorio reutilizable
    ├── welcome_card.dart              # Tarjeta de bienvenida
    ├── equipment_picker.dart          # Selector de equipos
    └── frequency_picker.dart          # Selector de frecuencia
```

---

## 🛠️ Tecnologías Utilizadas

| Categoría | Tecnología | Descripción |
|-----------|-----------|-------------|
| **Framework** | Flutter 3.10+ | Desarrollo multiplataforma |
| **Lenguaje** | Dart 3.10+ | Lenguaje principal |
| **Estado** | Provider | Gestión de estado reactivo |
| **Base de datos** | SQLite (sqflite) | Almacenamiento local |
| **Mapas** | flutter_map + OpenStreetMap | Sin API key necesaria |
| **Geocodificación** | geocoding + latlong2 | Conversión dirección ↔ coordenadas |
| **Ubicación** | geolocator | GPS del dispositivo |
| **Notificaciones** | flutter_local_notifications | Notificaciones programadas |
| **Audio** | audioplayers | Sonidos de alarma |
| **Vibración** | vibration | Feedback háptico |
| **Nativo Android** | Kotlin + MethodChannel | Integración con Reloj nativo |
| **Permisos** | permission_handler | Gestión de permisos del sistema |

---

## 📱 Capturas de Pantalla

> *Pendiente: Agregar capturas de pantalla de la aplicación*

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- **Flutter SDK** >= 3.10.7
- **Dart SDK** >= 3.10.7
- **Android SDK** con API 36
- **Android Studio** o **VS Code** con extensiones de Flutter

### Pasos de instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/Shutdown-re/Recordatorios-Teran.git

# 2. Entrar al directorio
cd Recordatorios-Teran

# 3. Instalar dependencias
flutter pub get

# 4. Verificar que todo esté correcto
flutter doctor

# 5. Ejecutar en un dispositivo/emulador
flutter run
```

### Compilar APK de producción

```bash
# Generar APK release
flutter build apk --release

# El APK estará en: build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚙️ Configuración de Android

La app requiere los siguientes permisos (ya configurados en `AndroidManifest.xml`):

| Permiso | Uso |
|---------|-----|
| `SET_ALARM` | Crear alarmas en el Reloj nativo |
| `SCHEDULE_EXACT_ALARM` | Notificaciones programadas |
| `ACCESS_FINE_LOCATION` | GPS para ubicación del técnico |
| `ACCESS_COARSE_LOCATION` | Ubicación aproximada |
| `VIBRATE` | Vibración al sonar alarma |
| `RECEIVE_BOOT_COMPLETED` | Re-programar alarmas al reiniciar |
| `POST_NOTIFICATIONS` | Mostrar notificaciones |

---

## 🎨 Diseño y Tema

La aplicación utiliza un **tema oscuro profesional** con la siguiente paleta:

| Color | Hex | Uso |
|-------|-----|-----|
| ⬜ Blanco | `#FFFFFF` | Color primario, textos principales |
| ⬛ Negro profundo | `#0A0A0A` | Fondo de la aplicación |
| 🟢 Verde neón | `#00E676` | Acentos y elementos interactivos |
| 🟢 Verde | `#4CAF50` | Estado: Pendiente |
| 🟠 Naranja | `#FF9800` | Estado: Próximo |
| 🔴 Rojo | `#F44336` | Estado: Vencido |

---

## 🔄 Flujo de la Aplicación

```
Bienvenida → Pantalla Principal → Crear Recordatorio → Programar Alarma
                  ↓                       ↓
            Ver en Mapa              Editar/Eliminar
                  ↓                       ↓
          Filtrar por estado      Alarma suena en Reloj
                                         ↓
                                  Aceptar / Posponer
                                         ↓
                                  (Si pospone: Countdown 5 min)
```

---

## 👨‍💻 Desarrollado por

**Terán Mantenimientos** — Sistema interno de gestión de servicios preventivos.

---

## 📄 Licencia

Este proyecto es de uso **privado** y pertenece a Terán Mantenimientos. Todos los derechos reservados.

---

<div align="center">

*Hecho con ❤️ usando Flutter*

</div>