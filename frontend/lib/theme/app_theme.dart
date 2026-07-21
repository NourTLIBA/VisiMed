import 'package:flutter/material.dart';

import '../models/models.dart';

class AppTheme {
  // Brand palette — The Jade Inari (Traditional, Mystical & Art Deco)
  static const Color primary = Color(0xFF132E27);       // Deep Forest Green
  static const Color primaryDark = Color(0xFF0B1C18);   // Darker Forest Green
  static const Color jade = Color(0xFF2E8B57);          // Polished Jade
  static const Color ricePaper = Color(0xFFF9F7F1);     // Off-White Sketch Paper
  static const Color vermillion = Color(0xFFE82746);    // Vermillion Red
  static const Color gold = Color(0xFFD4AF37);          // Brushed Gold
  static const Color accent = gold;                     // Secondary accent alias

  static const Color medical = jade;
  static const Color pharmaceutical = Color(0xFF1E6B52);
  // ignore: constant_identifier_names
  static const Color KOLAccent = vermillion;

  static const Color surface = ricePaper;
  static const Color cardBg = Colors.white;

  // ── Text styles ────────────────────────────────────────────────────────────
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: primary,
  );

  // ── Input decoration ───────────────────────────────────────────────────────
  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E0D5), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E0D5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: gold, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: vermillion, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: vermillion, width: 1.8),
      ),
      labelStyle: const TextStyle(color: Color(0xFF5A6660), fontSize: 14),
      floatingLabelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w700),
    );
  }

  // ── Main theme ─────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: jade,
      tertiary: gold,
      surface: surface,
      error: vermillion,
    );

    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: ricePaper,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ricePaper,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: primaryDark,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E0D5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: _inputDecorationTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: ricePaper,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: gold, width: 1),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: gold.withAlpha(45),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
        ),
        elevation: 2,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: jade.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E0D5), thickness: 1),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color visitTypeColor(VisitType type) =>
      type == VisitType.medical ? medical : pharmaceutical;

  static Color potentialAccent(TargetPotential potential) =>
      potential == TargetPotential.KOL ? vermillion : jade;
}
