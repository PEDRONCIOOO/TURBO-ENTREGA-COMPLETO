import 'package:flutter/material.dart';

ThemeData light = ThemeData(
  fontFamily: 'Roboto',
  primaryColor: const Color(0xFFF4870C),
  secondaryHeaderColor: const Color(0xFFF4870C),
  disabledColor: const Color(0xFFA0A4A8),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.white,
  shadowColor: Colors.black.withOpacity(0.03),
  scaffoldBackgroundColor: const Color(0xFFFCFCFC),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFF4870C),
    ),
  ),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFF4870C),
    secondary: Color(0xFFF4870C),
  ).copyWith(
    error: const Color(0xFFE84D4F),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.white,
  ),

  // 🔧 AQUI: usar DialogThemeData
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Colors.white,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(500),
    ),
  ),

  // 🔧 AQUI: usar BottomAppBarThemeData
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: Colors.white,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),

  dividerTheme: const DividerThemeData(
    thickness: 0.2,
    color: Color(0xFFA0A4A8),
  ),
);
