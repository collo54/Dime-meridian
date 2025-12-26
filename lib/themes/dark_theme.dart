import 'package:flutter/material.dart';

import '../constants/colors.dart';

final ThemeData oneChatDarkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  primaryColor: financePrimary,
  scaffoldBackgroundColor: const Color(0xFF0F172A),

  colorScheme: ColorScheme.dark(
    primary: financePrimary,
    secondary: financeGold,
    surface: financeSurfaceDark,
    error: financeDanger,
    onPrimary: Colors.white,
    onSurface: Colors.white,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: financeSurfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: financePrimary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: Colors.white),
    hintStyle: const TextStyle(color: Colors.white70),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: financePrimary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: financeGold,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: financeSurfaceDark,
    selectedColor: financeSuccess.withOpacity(0.2),
    labelStyle: const TextStyle(color: Colors.white),
    secondarySelectedColor: financeSuccess,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),

  iconTheme: const IconThemeData(color: financeGold),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
  ),
);
