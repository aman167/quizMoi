import 'package:flutter/material.dart';

/// Crimson Velocity — the complete color palette for quizMoi.
///
/// Every value maps to a Material 3 color role so the palette can be dropped
/// straight into a [ColorScheme].
class AppColors {
  AppColors._(); // prevent instantiation

  // ──────────────────────────── Primary ────────────────────────────
  static const Color primary = Color(0xFFBC001F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE6192E);
  static const Color onPrimaryContainer = Color(0xFFFFFCFF);

  // ──────────────────────────── Secondary ──────────────────────────
  static const Color secondary = Color(0xFF5F5E5F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE2DFE0);
  static const Color onSecondaryContainer = Color(0xFF636263);

  // ──────────────────────────── Tertiary ───────────────────────────
  static const Color tertiary = Color(0xFFB81231);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDB3247);
  static const Color onTertiaryContainer = Color(0xFFFFFDFF);

  // ──────────────────────────── Error ──────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ──────────────────────────── Surface ────────────────────────────
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color onSurfaceVariant = Color(0xFF5D3F3D);

  // ──────────────────────────── Outline ────────────────────────────
  static const Color outline = Color(0xFF926E6C);
  static const Color outlineVariant = Color(0xFFE7BCB9);

  // ──────────────────────────── Inverse ────────────────────────────
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color inversePrimary = Color(0xFFFFB3AE);

  // ──────────────────────────── Background ─────────────────────────
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);

  // ──────────────────────────── Surface Tint ───────────────────────
  static const Color surfaceTint = Color(0xFFC00020);

  // ──────────────────────────── Primary Fixed ──────────────────────
  static const Color primaryFixed = Color(0xFFFFDAD7);
  static const Color primaryFixedDim = Color(0xFFFFB3AE);
  static const Color onPrimaryFixed = Color(0xFF410005);
  static const Color onPrimaryFixedVariant = Color(0xFF930016);

  // ──────────────────────────── Secondary Fixed ────────────────────
  static const Color secondaryFixed = Color(0xFFE5E2E3);
  static const Color secondaryFixedDim = Color(0xFFC8C6C7);
  static const Color onSecondaryFixed = Color(0xFF1B1B1C);
  static const Color onSecondaryFixedVariant = Color(0xFF474647);

  // ──────────────────────────── Tertiary Fixed ─────────────────────
  static const Color tertiaryFixed = Color(0xFFFFDAD9);
  static const Color tertiaryFixedDim = Color(0xFFFFB3B3);
  static const Color onTertiaryFixed = Color(0xFF400009);
  static const Color onTertiaryFixedVariant = Color(0xFF920022);

  // ──────────────────────────── Custom / Semantic ──────────────────
  static const Color successMint = Color(0xFF2E7D32);
}
