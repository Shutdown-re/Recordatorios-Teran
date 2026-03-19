// Constantes de la aplicación Agenda Téran
class AppConstants {
  // Nombre de la aplicación
  static const String appName = 'Agenda Téran';
  static const String appVersion = '1.0.0';
  static const String developer = 'Cutberto Terán Morales';

  // Rutas de navegación
  static const String routeHome = '/home';
  static const String routeWelcome = '/welcome';
  static const String routeAddRecordatorio = '/add-recordatorio';
  static const String routeEditRecordatorio = '/edit-recordatorio';
  static const String routeRecordatoriosList = '/recordatorios-list';
  static const String routeMapa = '/mapa';
  static const String routeAlarmaFull = '/alarma-full';
  static const String routeConfiguracion = '/configuracion';
  static const String routeEstadisticas = '/estadisticas';

  // Preferencias de almacenamiento
  static const String prefUsuario = 'usuario_preferences';
  static const String prefTema = 'theme_preferences';
  static const String prefIdioma = 'language_preferences';
  static const String prefNotificaciones = 'notification_preferences';
  static const String prefPrimerUso = 'first_use_preferences';

  // Constantes de tiempo
  static const Duration defaultAlarmDuration = Duration(minutes: 5);
  static const Duration defaultNotificationDelay = Duration(hours: 24);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration vibrationPatternDuration = Duration(milliseconds: 1000);

  // Constantes de UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;
  static const double appBarElevation = 0.0;

  // Constantes de validación
  static const int minNombreLength = 2;
  static const int maxNombreLength = 100;
  static const int minTelefonoLength = 7;
  static const int maxTelefonoLength = 15;
  static const int maxObservacionesLength = 500;

  // URLs y APIs
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const String googleMapsUrl = 'https://maps.google.com';

  // Email de contacto
  static const String contactEmail = 'cutberto@teran.com';
  static const String supportEmail = 'soporte@agendateran.com';

  // Mensajes predeterminados
  static const String defaultWelcomeMessage =
      'Bienvenido al sistema de gestión de mantenimientos';
  static const String defaultErrorMessage =
      'Ocurrió un error. Por favor, inténtalo de nuevo.';
  static const String defaultSuccessMessage = 'Operación completada con éxito';
  static const String defaultLoadingMessage = 'Cargando...';
  static const String defaultEmptyMessage = 'No hay elementos para mostrar';

  // Patrones de regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp phoneRegex = RegExp(r'^[+]?[\d\s\-\(\)]{7,15}$');

  // Listas de opciones
  static const List<String> frecuencias = [
    '1 día',
    '2 días',
    '3 días',
    '4 días',
    '5 días',
    '6 días',
    '7 días',
    '8 días',
    '9 días',
    '10 días',
    '11 días',
    '12 días',
    '13 días',
    '14 días',
    '15 días',
    '1 mes',
    '2 meses',
    '3 meses',
    '4 meses',
    '5 meses',
    '6 meses',
    '7 meses',
    '8 meses',
    '9 meses',
    '10 meses',
    '11 meses',
    '1 año',
    '1.5 años',
    '2 años',
    '2.5 años',
    '3 años',
  ];

  static const List<String> equipos = [
    'Aire Acondicionado Split',
    'Aire Acondicionado Mini Split',
    'Aire Acondicionado Central',
    'Aire Acondicionado Portátil',
    'Aire Acondicionado de Ventana',
    'Mantenimiento Preventivo A/A',
    'Limpieza de Evaporador',
    'Limpieza de Condensador',
    'Limpieza de Ductos',
    'Recarga de Gas Refrigerante',
    'Reparación Eléctrica',
    'Mantenimiento y Diagnóstico',
    'Reparación de Tarjeta Electrónica',
    'Cambio de Tubería de Cobre',
    'Cambio de Compresor',
    'Reparación de Equipo Completo',
    'Falla de Equipo Eléctrico',
    'Falla Mecánica',
    'Instalación Nuevo Equipo',
    'Revisión General Anual',
    'Calibración de Termostatos',
    'Cambio de Filtros',
    'Prueba de Presiones',
  ];

  // Iconos por tipo de equipo
  static const Map<String, String> equipoIconos = {
    'Aire Acondicionado Split': '❄️',
    'Aire Acondicionado Mini Split': '🌬️',
    'Aire Acondicionado Central': '🏢',
    'Aire Acondicionado Portátil': '🔄',
    'Aire Acondicionado de Ventana': '🪟',
    'Mantenimiento Preventivo A/A': '🔧',
    'Limpieza de Evaporador': '🧼',
    'Limpieza de Condensador': '💧',
    'Limpieza de Ductos': '🌀',
    'Recarga de Gas Refrigerante': '⛽',
    'Reparación Eléctrica': '⚡',
    'Mantenimiento y Diagnóstico': '🔍',
    'Reparación de Tarjeta Electrónica': '💻',
    'Cambio de Tubería de Cobre': '🔩',
    'Cambio de Compresor': '⚙️',
    'Reparación de Equipo Completo': '🛠️',
    'Falla de Equipo Eléctrico': '⚠️',
    'Falla Mecánica': '🔨',
    'Instalación Nuevo Equipo': '📦',
    'Revisión General Anual': '📋',
    'Calibración de Termostatos': '🌡️',
    'Cambio de Filtros': '🧹',
    'Prueba de Presiones': '📊',
  };

  // Colores de estado
  static const Map<String, int> estadoColores = {
    'PENDIENTE': 0xFF4CAF50, // Verde
    'PRÓXIMO': 0xFFFF9800, // Naranja
    'VENCIDO': 0xFFF44336, // Rojo
    'COMPLETADO': 0xFF2196F3, // Azul
  };

  // Sonidos disponibles
  static const List<Map<String, dynamic>> sonidosDisponibles = [
    {
      'id': 'default',
      'nombre': 'Sonido por defecto',
      'asset': 'audio/alarma_default.mp3',
    },
    {
      'id': 'urgent',
      'nombre': 'Alarma urgente',
      'asset': 'audio/alarma_urgente.mp3',
    },
    {'id': 'soft', 'nombre': 'Tono suave', 'asset': 'audio/tono_suave.mp3'},
    {'id': 'bell', 'nombre': 'Campana', 'asset': 'audio/campana.mp3'},
    {'id': 'digital', 'nombre': 'Digital', 'asset': 'audio/digital.mp3'},
  ];

  // Patrones de vibración
  static const List<Map<String, dynamic>> vibracionesDisponibles = [
    {'id': 'none', 'nombre': 'Sin vibración', 'pattern': []},
    {
      'id': 'short',
      'nombre': 'Corta',
      'pattern': [0, 500],
    },
    {
      'id': 'long',
      'nombre': 'Larga',
      'pattern': [0, 1000],
    },
    {
      'id': 'alarm',
      'nombre': 'Patrón de alarma',
      'pattern': [0, 1000, 500, 1000, 500, 1000],
    },
    {
      'id': 'constant',
      'nombre': 'Constante',
      'pattern': [0, 1000],
    },
  ];

  // Mensajes de error
  static const Map<String, String> errorMessages = {
    'network': 'Error de conexión. Verifica tu internet.',
    'permission': 'Permiso denegado. Configura los permisos en ajustes.',
    'location': 'No se pudo obtener la ubicación.',
    'database': 'Error en la base de datos.',
    'unknown': 'Error desconocido. Contacta al soporte.',
  };

  // Textos para la UI
  static const Map<String, String> uiTexts = {
    'add': 'Agregar',
    'edit': 'Editar',
    'delete': 'Eliminar',
    'save': 'Guardar',
    'cancel': 'Cancelar',
    'confirm': 'Confirmar',
    'search': 'Buscar',
    'filter': 'Filtrar',
    'sort': 'Ordenar',
    'details': 'Detalles',
    'close': 'Cerrar',
    'back': 'Atrás',
    'next': 'Siguiente',
    'previous': 'Anterior',
    'loading': 'Cargando...',
    'noData': 'No hay datos disponibles',
    'retry': 'Reintentar',
  };

  // Configuración de mapas
  static const double defaultMapZoom = 12.0;
  static const double detailMapZoom = 16.0;
  static const double initialLatitude = 19.432608; // CDMX
  static const double initialLongitude = -99.133209;
}
