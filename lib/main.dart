import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
// import 'package:workmanager/workmanager.dart'; // Removido: incompatible

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mapas_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'utils/theme.dart';

// Callback para background tasks (NO USADO - workmanager removido por incompatibilidad)
void callbackDispatcher() {
  // Las notificaciones ahora se usan sin workmanager
}

void main() async {
  // Inicialización de zonas horarias
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización
  await initializeDateFormatting('es_ES', null);

  // Inicializar servicios (sin workmanager)
  final alarmService = AlarmService();
  final notificationService = NotificationService();
  final storageService = StorageService();
  final audioService = AudioService();

  await storageService.init();

  // ⚠️ IMPORTANTE: Inicializar los servicios
  await notificationService.initialize();
  await audioService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AlarmService>(create: (_) => alarmService),
        Provider<NotificationService>(create: (_) => notificationService),
        Provider<StorageService>(create: (_) => storageService),
        Provider<AudioService>(create: (_) => audioService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Téran',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
      // Rutas nombradas para navegación
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/mapas': (context) => const MapasScreen(),
      },
    );
  }
}
