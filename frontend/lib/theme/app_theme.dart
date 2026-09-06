import 'package:flutter/material.dart';

import '../models/models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  VisiMed visual language — "warm clinical"
///
///  Refined, unfussy, professional. A warm ivory ground, soft white cards with
///  a single diffuse shadow (no outlines, no ornaments), a muted pine-green
///  brand colour and one warm clay accent used sparingly. Typography is natural:
///  sentence case, moderate weights (nothing heavier than w700), almost no
///  letter-spacing.
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2F5D50); // muted pine green
  static const Color primaryDark = Color(0xFF24463D);
  static const Color jade = Color(0xFF3E7C63); // secondary green
  static const Color accent = Color(0xFFC2795A); // warm clay
  static const Color gold = Color(0xFFB8975F); // soft antique tan (warm hairline)

  // ── Ground & surfaces ──────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF4F1EA); // warm ivory / sand
  static const Color surfaceAlt = Color(0xFFEDE8DD); // grouped sections
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color ricePaper = Color(0xFFFBF9F4); // near-white, for text on green
  static const Color hairline = Color(0xFFE7E2D7);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF2B2A26); // warm near-black
  static const Color inkMuted = Color(0xFF6E6C64);
  static const Color inkFaint = Color(0xFF9C9A8F);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF3E7C63);
  static const Color warning = Color(0xFFC98A3C);
  static const Color danger = Color(0xFFB4472E); // warm brick red
  static const Color vermillion = danger; // legacy alias
  // ignore: constant_identifier_names
  static const Color KOLAccent = danger; // legacy alias

  // ── Visit-type / potential palette ─────────────────────────────────────────
  static const Color medical = primary;
  static const Color pharmaceutical = accent;

  // ── Shape ──────────────────────────────────────────────────────────────────
  static const double rCard = 20;
  static const double rTile = 16;
  static const double rField = 14;
  static const double rPill = 999;

  /// One diffuse, barely-there shadow — the only elevation in the app.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF2B2A26).withAlpha(18),
          blurRadius: 24,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Legacy text style still referenced by a screen ─────────────────────────
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: ink,
  );

  // ── Inputs ─────────────────────────────────────────────────────────────────
  static InputDecorationTheme _inputTheme() {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(rField),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(hairline),
      enabledBorder: border(hairline),
      focusedBorder: border(primary, 1.6),
      errorBorder: border(danger),
      focusedErrorBorder: border(danger, 1.6),
      hintStyle: const TextStyle(color: inkFaint, fontSize: 14),
      labelStyle: const TextStyle(color: inkMuted, fontSize: 14),
      floatingLabelStyle:
          const TextStyle(color: primary, fontWeight: FontWeight.w600),
      prefixIconColor: inkFaint,
    );
  }

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: cardBg,
      error: danger,
      brightness: Brightness.light,
    ).copyWith(
      surfaceContainerLowest: cardBg,
      surfaceContainerLow: surface,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      outlineVariant: hairline,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      splashFactory: InkRipple.splashFactory,
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: 'Roboto',
      ).copyWith(
        titleLarge: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: ink),
        titleMedium: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: ink),
        titleSmall: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: const TextStyle(fontSize: 15, color: ink, height: 1.4),
        bodyMedium: const TextStyle(fontSize: 14, color: ink, height: 1.4),
        labelLarge: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: ink),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: _inputTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withAlpha(90),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(rField)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withAlpha(60)),
          minimumSize: const Size(0, 44),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(rField)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        extendedTextStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 66,
        indicatorColor: primary.withAlpha(28),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected) ? primary : inkFaint,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? primary : inkMuted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withAlpha(16),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
          color: hairline, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
        titleTextStyle: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: inkMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: hairline,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
      splashColor: primary.withAlpha(14),
      highlightColor: primary.withAlpha(10),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color visitTypeColor(VisitType type) =>
      type == VisitType.medical ? medical : pharmaceutical;

  static Color potentialAccent(TargetPotential potential) {
    switch (potential) {
      case TargetPotential.KOL:
        return danger;
      case TargetPotential.A:
        return gold;
      case TargetPotential.B:
        return jade;
      case TargetPotential.C:
        return inkFaint;
    }
  }
}
