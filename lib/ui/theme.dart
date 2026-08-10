import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF3B3663);
  static const Color softGrey = Color(0xFF6B648E);

  static const List<Color> bgGradient = <Color>[
    Color(0xFFFFF6E9),
    Color(0xFFEAF3FF),
  ];

  /// One cheerful gradient per game (order matches the home grid).
  static const List<List<Color>> gameGradients = <List<Color>>[
    <Color>[Color(0xFFFF9A8B), Color(0xFFFF6A88)], // Counting
    <Color>[Color(0xFFFFC3A0), Color(0xFFFFAFBD)], // Tracing
    <Color>[Color(0xFF56CCF2), Color(0xFF2F80ED)], // Add & Subtract
    <Color>[Color(0xFFA18CD1), Color(0xFFFBC2EB)], // Shapes
    <Color>[Color(0xFFFAD961), Color(0xFFF76B1C)], // Patterns
    <Color>[Color(0xFF43E97B), Color(0xFF38B2F9)], // Compare
  ];
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C5CFF)),
    scaffoldBackgroundColor: const Color(0xFFFDFBFF),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
  );
}
