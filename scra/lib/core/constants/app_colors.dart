import 'package:flutter/material.dart';

/// Color tokens extracted from the Smart Class Stitch design system
/// (Material 3 palette generated from the `#2563EB` brand blue).
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF004AC6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF2563EB);
  static const Color onPrimaryContainer = Color(0xFFEEEFFF);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB4C5FF);
  static const Color onPrimaryFixed = Color(0xFF00174B);
  static const Color onPrimaryFixedVariant = Color(0xFF003EA8);
  static const Color inversePrimary = Color(0xFFB4C5FF);
  static const Color surfaceTint = Color(0xFF0053DB);

  // Secondary
  static const Color secondary = Color(0xFF006591);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF39B8FD);
  static const Color onSecondaryContainer = Color(0xFF004666);
  static const Color secondaryFixed = Color(0xFFC9E6FF);
  static const Color secondaryFixedDim = Color(0xFF89CEFF);
  static const Color onSecondaryFixed = Color(0xFF001E2F);
  static const Color onSecondaryFixedVariant = Color(0xFF004C6E);

  // Tertiary
  static const Color tertiary = Color(0xFF4D556B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF656D84);
  static const Color onTertiaryContainer = Color(0xFFEEF0FF);
  static const Color tertiaryFixed = Color(0xFFDAE2FD);
  static const Color tertiaryFixedDim = Color(0xFFBEC6E0);

  // Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surfaces
  static const Color background = Color(0xFFF7F9FB);
  static const Color onBackground = Color(0xFF191C1E);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color surfaceVariant = Color(0xFFE0E3E5);
  static const Color onSurfaceVariant = Color(0xFF434655);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color outline = Color(0xFF737686);
  static const Color outlineVariant = Color(0xFFC3C6D7);

  // Splash / dark brand surfaces
  static const Color splashBackground = Color(0xFF0F172A);
  static const Color darkNavy = Color(0xFF0B1120);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);

  // Semantic status colors
  static const Color success = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);
  static const Color live = Color(0xFF38BDF8);
  static const Color liveRed = Color(0xFFDC2626);
}
