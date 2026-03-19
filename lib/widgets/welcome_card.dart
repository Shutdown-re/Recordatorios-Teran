import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/theme.dart';

class WelcomeCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? userCompany;
  final VoidCallback? onProfileTap;
  final bool showStats;
  final int pendingCount;
  final int upcomingCount;
  final int totalCount;

  const WelcomeCard({
    super.key,
    required this.userName,
    this.userRole = 'Técnico Especializado',
    this.userCompany,
    this.onProfileTap,
    this.showStats = true,
    this.pendingCount = 0,
    this.upcomingCount = 0,
    this.totalCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.defaultPadding),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con información del usuario
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar del usuario
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      FontAwesomeIcons.userTie,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido,',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppTheme.textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (userCompany != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          userCompany!,
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de hora/estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FontAwesomeIcons.solidCircle,
                        size: 8,
                        color: AppTheme.accentColor,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        'Activo',
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Estadísticas (si están habilitadas)
          if (showStats) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: FontAwesomeIcons.calendarCheck,
                    value: pendingCount,
                    label: 'Pendientes',
                    color: AppTheme.successColor,
                  ),

                  _buildStatItem(
                    icon: FontAwesomeIcons.clock,
                    value: upcomingCount,
                    label: 'Próximos',
                    color: AppTheme.warningColor,
                  ),

                  _buildStatItem(
                    icon: FontAwesomeIcons.users,
                    value: totalCount,
                    label: 'Total',
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],

          // Mensaje motivacional
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.defaultBorderRadius),
                bottomRight: Radius.circular(AppTheme.defaultBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.lightbulb,
                  color: AppTheme.accentColor,
                  size: 16,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    '¡Mantén tus equipos en perfecto estado!',
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 22),
        ),

        const SizedBox(height: 8),

        Text(
          value.toString(),
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Tarjeta de bienvenida compacta para app bar
class CompactWelcomeCard extends StatelessWidget {
  final String userName;
  final String? userInitials;
  final VoidCallback? onProfileTap;

  const CompactWelcomeCard({
    super.key,
    required this.userName,
    this.userInitials,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar pequeño
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  userInitials ?? _getInitials(userName),
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Nombre truncado
            SizedBox(
              width: 100,
              child: Text(
                userName.split(' ').first,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 4),

            const Icon(
              FontAwesomeIcons.chevronDown,
              size: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, 1);
    }
    return 'CT'; // Default para Cutberto Terán
  }
}

// Tarjeta de bienvenida con fecha y hora
class WelcomeDateTimeCard extends StatelessWidget {
  final String userName;
  final DateTime currentDateTime;
  final VoidCallback? onDateTimeTap;

  const WelcomeDateTimeCard({
    super.key,
    required this.userName,
    required this.currentDateTime,
    this.onDateTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(currentDateTime);
    final formattedTime = _formatTime(currentDateTime);
    final weekday = _getWeekday(currentDateTime);

    return GestureDetector(
      onTap: onDateTimeTap,
      child: Container(
        margin: const EdgeInsets.all(AppTheme.defaultPadding),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration.copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.surfaceColor, AppTheme.cardColor],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(
              _getGreeting(currentDateTime),
              style: TextStyle(
                color: AppTheme.textColor.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              userName,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 20),

            // Fecha y hora
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekday,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    formattedTime,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 12) {
      return '¡Buenos días,';
    } else if (hour < 19) {
      return '¡Buenas tardes,';
    } else {
      return '¡Buenas noches,';
    }
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day;
    final month = _getMonthName(dateTime.month);
    final year = dateTime.year;
    return '$day de $month de $year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekday(DateTime dateTime) {
    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return weekdays[dateTime.weekday - 1];
  }

  String _getMonthName(int month) {
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
}
