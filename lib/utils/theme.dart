import 'package:flutter/material.dart';

// Tema oscuro en blanco y negro para Agenda Téran
class AppTheme {
  // Paleta de colores
  static const Color primaryColor = Color(0xFFFFFFFF); // Blanco
  static const Color secondaryColor = Color(0xFF000000); // Negro
  static const Color accentColor = Color(0xFF00FF00); // Verde neón para acentos
  static const Color backgroundColor = Color(0xFF000000); // Negro
  static const Color surfaceColor = Color(0xFF121212); // Gris oscuro
  static const Color cardColor = Color(0xFF1E1E1E); // Gris medio oscuro
  static const Color textColor = Color(0xFFFFFFFF); // Blanco
  static const Color textSecondaryColor = Color(0xFFB0B0B0); // Gris claro
  static const Color borderColor = Color(0xFF333333); // Gris oscuro para bordes
  static const Color errorColor = Color(0xFFCF6679); // Rojo suave
  static const Color successColor = Color(0xFF00C853); // Verde éxito
  static const Color warningColor = Color(0xFFFFD600); // Amarillo advertencia
  static const Color infoColor = Color(0xFF2196F3); // Azul información

  // Colores para estados
  static const Color pendingColor = Color(0xFF4CAF50); // Verde
  static const Color upcomingColor = Color(0xFFFF9800); // Naranja
  static const Color overdueColor = Color(0xFFF44336); // Rojo
  static const Color completedColor = Color(0xFF2196F3); // Azul

  // Gradientes
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.4)],
  );

  static LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceColor, cardColor],
  );

  static LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [surfaceColor, backgroundColor],
  );

  // Tema oscuro principal
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: secondaryColor,
      onSecondary: primaryColor,
      onSurface: textColor,
      onError: secondaryColor,
      outline: borderColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: appBarElevation,
      centerTitle: true,
      iconTheme: const IconThemeData(color: primaryColor, size: 24),
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontFamily: 'Montserrat',
      ),
      shape: Border(bottom: BorderSide(color: borderColor, width: 1)),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: const EdgeInsets.all(defaultPadding),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontFamily: 'Montserrat',
      ),
      hintStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontFamily: 'Montserrat',
      ),
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: 12,
        fontFamily: 'Montserrat',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'Montserrat',
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: secondaryColor,
      elevation: 4,
      sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
    ),
    iconTheme: const IconThemeData(color: primaryColor, size: 24),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 20,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: const TextStyle(
        color: textColor,
        fontSize: 14,
        fontFamily: 'Montserrat',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius * 1.5),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Roboto',
      ),
      contentTextStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(defaultBorderRadius * 1.5),
        ),
      ),
      modalBackgroundColor: backgroundColor.withOpacity(0.8),
      modalElevation: 8,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardColor,
      selectedColor: primaryColor,
      disabledColor: surfaceColor,
      labelStyle: const TextStyle(
        color: textColor,
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
      secondaryLabelStyle: const TextStyle(
        color: secondaryColor,
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
        side: const BorderSide(color: borderColor),
      ),
    ),
    listTileTheme: ListTileThemeData(
      tileColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      titleTextStyle: const TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      subtitleTextStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      leadingAndTrailingTextStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.25,
        fontFamily: 'Roboto',
      ),
      displayMedium: const TextStyle(
        color: textColor,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.25,
        fontFamily: 'Roboto',
      ),
      displaySmall: const TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        fontFamily: 'Roboto',
      ),
      headlineMedium: const TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15,
        fontFamily: 'Roboto',
      ),
      headlineSmall: const TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        fontFamily: 'Roboto',
      ),
      titleLarge: const TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        fontFamily: 'Roboto',
      ),
      titleMedium: const TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        fontFamily: 'Roboto',
      ),
      titleSmall: const TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        fontFamily: 'Roboto',
      ),
      bodyLarge: const TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        fontFamily: 'Roboto',
      ),
      bodyMedium: const TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        fontFamily: 'Roboto',
      ),
      bodySmall: const TextStyle(
        color: textSecondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        fontFamily: 'Roboto',
      ),
      labelLarge: const TextStyle(
        color: secondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontFamily: 'Roboto',
      ),
      labelMedium: const TextStyle(
        color: secondaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        fontFamily: 'Roboto',
      ),
      labelSmall: const TextStyle(
        color: secondaryColor,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        fontFamily: 'Roboto',
      ),
    ),
  );

  // Estilos de texto personalizados
  static const TextStyle heading1 = TextStyle(
    color: primaryColor,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.25,
    fontFamily: 'Roboto',
  );

  static const TextStyle heading2 = TextStyle(
    color: primaryColor,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.25,
    fontFamily: 'Roboto',
  );

  static const TextStyle heading3 = TextStyle(
    color: primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    fontFamily: 'Roboto',
  );

  static const TextStyle subtitle1 = TextStyle(
    color: textColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFamily: 'Roboto',
  );

  static const TextStyle subtitle2 = TextStyle(
    color: textSecondaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    fontFamily: 'Roboto',
  );

  static const TextStyle body1 = TextStyle(
    color: textColor,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    fontFamily: 'Roboto',
  );

  static const TextStyle body2 = TextStyle(
    color: textSecondaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    fontFamily: 'Roboto',
  );

  static const TextStyle caption = TextStyle(
    color: textSecondaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    fontFamily: 'Roboto',
  );

  static const TextStyle button = TextStyle(
    color: secondaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFamily: 'Roboto',
  );

  // Estilos para tarjetas
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(defaultBorderRadius),
    border: Border.all(color: borderColor, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(defaultBorderRadius),
    border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.1),
        blurRadius: 12,
        spreadRadius: 2,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get surfaceDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(defaultBorderRadius),
    border: Border.all(color: borderColor, width: 1),
  );

  // Sombreados
  static const double appBarElevation = 0.0;
  static const double cardElevation = 4.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
}
