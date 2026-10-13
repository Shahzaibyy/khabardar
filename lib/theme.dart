import 'package:flutter/material.dart';

import 'detection/models.dart';

/// Brand colours from the Khabardar brand sheet.
abstract final class KColors {
  static const green = Color(0xFF0A5C45);
  static const deep = Color(0xFF063D2E);
  static const greenMid = Color(0xFF2E7D64);
  static const greenDark = Color(0xFF08503C);
  static const mint = Color(0xFFDCEBE3);
  static const mintText = Color(0xFFD9F2E6);
  static const scam = Color(0xFFC2410C);
  static const scamDark = Color(0xFFA3360A);
  static const scamTint = Color(0xFFFFF4EC);
  static const scamBorder = Color(0xFFF3C9AE);
  static const scamInk = Color(0xFF7C2D12);
  static const alertDot = Color(0xFFE8590C);
  static const suspicious = Color(0xFFA16207);
  static const ground = Color(0xFFF4F7F5);
  static const card = Colors.white;
  static const line = Color(0xFFD5DED9);
  static const lineSoft = Color(0xFFE6ECE9);
  static const ink = Color(0xFF10201A);
  static const ink2 = Color(0xFF3A4B44);
  static const muted = Color(0xFF4A5C55);
  static const callDark = Color(0xFF1B1210);
  static const callMuted = Color(0xFFD6C9C4);

  static Color forRisk(RiskLevel l) => switch (l) {
    RiskLevel.scam => scam,
    RiskLevel.suspicious => suspicious,
    RiskLevel.safe => green,
  };
}

const kUrduFont = 'NotoNastaliqUrdu';

ThemeData buildTheme({required bool urdu}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KColors.green,
      primary: KColors.green,
      error: KColors.scam,
      surface: KColors.ground,
    ),
    scaffoldBackgroundColor: KColors.ground,
    fontFamily: urdu ? kUrduFont : 'Manrope',
    fontFamilyFallback: const ['Manrope', kUrduFont],
  );
  final text = base.textTheme.apply(
    bodyColor: KColors.ink,
    displayColor: KColors.ink,
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: KColors.ground,
      foregroundColor: KColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: KColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: KColors.ink,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: KColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KColors.green, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? KColors.green
            : const Color(0xFFB9CCC3),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KColors.ink,
    ),
  );
}
