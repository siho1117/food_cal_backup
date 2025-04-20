import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Color Constants
  static const Color primaryBlue = Color(0xFF0052CC);
  static const Color secondaryBeige = Color(0xFFF5EFE0);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Colors.white;
  static const Color accentColor = Color(0xFF00A3FF);

  // Font Constants
  static const String fontFamily = 'Montserrat';

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryBlue,
    letterSpacing: 1.2,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: primaryBlue,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textDark,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  // The main theme
  static final ThemeData lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBeige,
      background: secondaryBeige,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: secondaryBeige,
    textTheme: const TextTheme(
      headlineLarge: headingStyle,
      titleLarge: titleStyle,
      bodyLarge: bodyStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: textLight,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: buttonStyle,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: primaryBlue,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(
        color: primaryBlue,
      ),
    ),
  );
}
