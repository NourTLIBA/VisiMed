import 'package:flutter/material.dart';

import '../models/models.dart';

class AppTheme {
  // Brand palette — extracted from other.png logo
  static const Color primary = Color(0xFF2B3A8F);    // deep navy blue
  static const Color primaryDark = Color(0xFF1A2468);
  static const Color accent = Color(0xFFF5A623);     // warm amber/orange
  static const Color accentLight = Color(0xFFFFCC70);

  static const Color medical = Color(0xFF2979FF);
  static const Color pharmaceutical = Color(0xFF00C853);
  static const Color kolAccent = Color(0xFFE53935);

  static const Color surface = Color(0xFFF4F6FB);
  static const Color cardBg = Colors.white;

  // ── Text styles ────────────────────────────────────────────────────────────
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFF8A94B0),
  );

  // ── Input decoration ───────────────────────────────────────────────────────
  static InputDecorationTheme _inputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F3FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kolAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kolAccent, width: 1.8),
      ),
      labelStyle: const TextStyle(color: Color(0xFF6B748F)),
      floatingLabelStyle: const TextStyle(color: primary, fontWeight: FontWeight.w600),
    );
  }

  // ── Main theme ─────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: surface,
    );

    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE8ECF5), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: _inputDecorationTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withAlpha(25),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE8ECF5), thickness: 1),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color visitTypeColor(VisitType type) =>
      type == VisitType.medical ? medical : pharmaceutical;

  static Color potentialAccent(TargetPotential potential) =>
      potential == TargetPotential.kol ? kolAccent : primary;
}
