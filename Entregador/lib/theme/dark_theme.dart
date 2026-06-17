import 'package:flutter/material.dart';

ThemeData dark = ThemeData(
  fontFamily: 'Roboto',
  primaryColor: const Color(0xFFF4870C),
  secondaryHeaderColor: const Color(0xFFF4870C),
  disabledColor: const Color(0xFF6f7275),
  brightness: Brightness.dark,
  hintColor: const Color(0xFFbebebe),
  cardColor: Colors.black,
  shadowColor: Colors.white.withOpacity(0.03),
  scaffoldBackgroundColor: const Color(0xFF161617),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFF4870C),
    ),
  ),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFF4870C),
    secondary: Color(0xFFF4870C),
  ).copyWith(
    error: const Color(0xFFdd3135),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFF29292D),
    surfaceTintColor: Color(0xFF29292D),
  ),

  // 🔧 AQUI: usar DialogThemeData em vez de DialogTheme
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Colors.white10,
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(500),
    ),
  ),

  // 🔧 AQUI: usar BottomAppBarThemeData em vez de BottomAppBarTheme
  bottomAppBarTheme: const BottomAppBarThemeData(
    color: Colors.black,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),

  dividerTheme: const DividerThemeData(
    thickness: 0.2,
    color: Color(0xFFA0A4A8),
  ),
);
