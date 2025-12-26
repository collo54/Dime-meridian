import 'package:flutter/material.dart';

import '../constants/colors.dart';

final ThemeData oneChatTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  primaryColor: financePrimary,
  scaffoldBackgroundColor: Colors.white,

  colorScheme: ColorScheme.light(
    primary: financePrimary,
    secondary: financeGold,
    surface: financeSurfaceLight,
    error: financeDanger,
    onPrimary: Colors.white,
    onSurface: Colors.black87,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: financeSurfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: financePrimary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: Colors.black87),
    hintStyle: const TextStyle(color: Colors.black45),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: financePrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: financePrimary,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: financeSurfaceLight,
    selectedColor: financeSuccess.withOpacity(0.15),
    labelStyle: const TextStyle(color: Colors.black),
    secondaryLabelStyle: const TextStyle(color: Colors.white),
    secondarySelectedColor: financeSuccess,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),

  iconTheme: const IconThemeData(color: financePrimary),

  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
  ),
);
