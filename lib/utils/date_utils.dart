import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DateUtils {
  // Formatos de fecha
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String displayLongDateFormat = "dd 'de' MMMM 'de' yyyy";
  static const String displayTimeFormat = 'HH:mm';
  static const String displayDayMonthFormat = 'dd MMM';
  static const String displayWeekdayFormat = 'EEEE';

  // Formatear fecha para mostrar
  static String formatDate(DateTime date, {String format = displayDateFormat}) {
    return DateFormat(format, 'es_ES').format(date);
  }

  // Formatear fecha larga (con texto)
  static String formatDateLong(DateTime date) {
    return DateFormat(displayLongDateFormat, 'es_ES').format(date);
  }

  // Formatear fecha y hora
  static String formatDateTime(DateTime date) {
    return DateFormat(displayDateTimeFormat, 'es_ES').format(date);
  }

  // Formatear solo hora
  static String formatTime(DateTime date) {
    return DateFormat(displayTimeFormat, 'es_ES').format(date);
  }

  // Formatear día y mes (ej: "15 Mar")
  static String formatDayMonth(DateTime date) {
    return DateFormat(displayDayMonthFormat, 'es_ES').format(date);
  }

  // Formatear día de la semana (ej: "Lunes")
  static String formatWeekday(DateTime date) {
    return DateFormat(displayWeekdayFormat, 'es_ES').format(date);
  }

  // Parsear fecha desde string
  static DateTime? parseDate(String dateString, {String format = dateFormat}) {
    try {
      return DateFormat(format, 'es_ES').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Obtener diferencia en días entre dos fechas
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Verificar si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Verificar si una fecha es mañana
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Verificar si una fecha es ayer
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Obtener fecha de inicio de semana (Lunes)
  static DateTime startOfWeek(DateTime date) {
    final day = date.weekday;
    return date.subtract(Duration(days: day - 1));
  }

  // Obtener fecha de fin de semana (Domingo)
  static DateTime endOfWeek(DateTime date) {
    final day = date.weekday;
    return date.add(Duration(days: 7 - day));
  }

  // Obtener fecha de inicio de mes
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // Obtener fecha de fin de mes
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // Calcular edad a partir de fecha de nacimiento
  static int calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    final month1 = currentDate.month;
    final month2 = birthDate.month;

    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      final day1 = currentDate.day;
      final day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }

    return age;
  }

  // Formatear duración en texto legible
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'día' : 'días'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'segundo' : 'segundos'}';
    }
  }

  // Obtener fecha relativa (Hoy, Mañana, Ayer, o fecha)
  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Hoy';
    } else if (isTomorrow(date)) {
      return 'Mañana';
    } else if (isYesterday(date)) {
      return 'Ayer';
    } else {
      return formatDate(date);
    }
  }

  // Verificar si una fecha está dentro de un rango
  static bool isWithinRange(DateTime date, DateTime start, DateTime end) {
    return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
        (date.isAtSameMomentAs(end) || date.isBefore(end));
  }

  // Obtener lista de días entre dos fechas
  static List<DateTime> getDaysInBetween(DateTime startDate, DateTime endDate) {
    List<DateTime> days = [];
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    return days;
  }

  // Formatear fecha para input de fecha
  static String formatForDateInput(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatear fecha para input de hora
  static String formatForTimeInput(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Obtener color según proximidad de fecha
  static Color getDateColor(DateTime date, {DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    final difference = date.difference(reference).inDays;

    if (difference < 0) {
      return const Color(0xFFF44336); // Rojo - vencido
    } else if (difference == 0) {
      return const Color(0xFFFF9800); // Naranja - hoy
    } else if (difference <= 7) {
      return const Color(0xFFFFC107); // Amarillo - próxima semana
    } else {
      return const Color(0xFF4CAF50); // Verde - futuro
    }
  }

  // Obtener icono según proximidad de fecha
  static IconData getDateIcon(DateTime date, {DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    final difference = date.difference(reference).inDays;

    if (difference < 0) {
      return Icons.warning; // Vencido
    } else if (difference == 0) {
      return Icons.today; // Hoy
    } else if (difference <= 7) {
      return Icons.notifications_active; // Próximo
    } else {
      return Icons.calendar_today; // Futuro
    }
  }

  // Calcular próxima fecha basada en frecuencia
  static DateTime calculateNextDate(DateTime startDate, String frequency) {
    final days = _getDaysFromFrequency(frequency);
    return startDate.add(Duration(days: days));
  }

  // Obtener días desde frecuencia
  static int _getDaysFromFrequency(String frequency) {
    switch (frequency) {
      case '1 día':
        return 1;
      case '2 días':
        return 2;
      case '3 días':
        return 3;
      case '4 días':
        return 4;
      case '5 días':
        return 5;
      case '6 días':
        return 6;
      case '7 días':
        return 7;
      case '8 días':
        return 8;
      case '9 días':
        return 9;
      case '10 días':
        return 10;
      case '11 días':
        return 11;
      case '12 días':
        return 12;
      case '13 días':
        return 13;
      case '14 días':
        return 14;
      case '15 días':
        return 15;
      case '1 mes':
        return 30;
      case '2 meses':
        return 60;
      case '3 meses':
        return 90;
      case '4 meses':
        return 120;
      case '5 meses':
        return 150;
      case '6 meses':
        return 180;
      case '7 meses':
        return 210;
      case '8 meses':
        return 240;
      case '9 meses':
        return 270;
      case '10 meses':
        return 300;
      case '11 meses':
        return 330;
      case '1 año':
        return 365;
      case '1.5 años':
        return 548;
      case '2 años':
        return 730;
      case '2.5 años':
        return 913;
      case '3 años':
        return 1095;
      default:
        return 30;
    }
  }

  // Validar si una fecha es válida para selección (no en pasado)
  static bool isValidFutureDate(DateTime date) {
    return date.isAfter(DateTime.now()) || isToday(date);
  }

  // Obtener nombre del mes
  static String getMonthName(int month) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month - 1];
  }

  // Obtener nombre corto del mes
  static String getShortMonthName(int month) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  // Obtener nombre del día de la semana
  static String getWeekdayName(int weekday) {
    final days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }

  // Obtener nombre corto del día de la semana
  static String getShortWeekdayName(int weekday) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }
}
