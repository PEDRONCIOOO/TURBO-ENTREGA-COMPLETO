import 'package:flutter/material.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData light({Color color = const Color(0xFFF4870C)}) => ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: color,
  secondaryHeaderColor: const Color(0xFFF4870C),
  disabledColor: const Color(0xFFBABFC4),
  brightness: Brightness.light,
  hintColor: const Color(0xFF9F9F9F),
  cardColor: Colors.white,
  shadowColor: Colors.black.withOpacity(0.03),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: color),
  ),
  colorScheme: ColorScheme.light(primary: color, secondary: color)
      .copyWith(surface: const Color(0xFFFCFCFC))
      .copyWith(error: const Color(0xFFF4870C)),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.white,
  ),

  // 👇 tipos atualizados
  dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
  ),

  bottomAppBarTheme: const BottomAppBarThemeData(
    surfaceTintColor: Colors.white,
    height: 60,
    padding: EdgeInsets.symmetric(vertical: 5),
  ),

  dividerTheme: const DividerThemeData(
    thickness: 0.2,
    color: Color(0xFFA0A4A8),
  ),

  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
  ),
);
