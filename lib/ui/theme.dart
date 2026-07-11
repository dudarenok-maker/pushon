import 'package:flutter/material.dart';

const kSunshine = Color(0xFFFFD23F);
const kInk = Color(0xFF1B2A4A);
const kCoral = Color(0xFFFF5A36);
const kCream = Color(0xFFFFFDF4);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kCoral,
    primary: kInk,
    secondary: kCoral,
    surface: kCream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: kSunshine, foregroundColor: kInk, elevation: 0, centerTitle: false,
      titleTextStyle: TextStyle(color: kInk, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kCream,
      indicatorColor: kSunshine,
      iconTheme: WidgetStateProperty.all(const IconThemeData(color: kInk)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: kCoral, foregroundColor: Colors.white),
    ),
  );
}
