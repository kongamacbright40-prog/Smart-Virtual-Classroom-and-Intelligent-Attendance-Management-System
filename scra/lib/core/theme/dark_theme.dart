import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_theme.dart';

/// Dark theme. Stitch only ships light screens (plus the dark splash), so the
/// dark palette is derived from the same brand seed using Material 3 tonal
/// rules, with the splash navy as the base surface.
final ThemeData darkTheme = AppTheme.build(
  ColorScheme.fromSeed(
    seedColor: AppColors.primaryContainer,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryFixedDim,
    primaryContainer: AppColors.primaryContainer,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.darkNavy,
    surfaceContainerLowest: const Color(0xFF070C18),
    surfaceContainerLow: AppColors.splashBackground,
    surfaceContainer: const Color(0xFF151E32),
    surfaceContainerHigh: AppColors.slate800,
    surfaceContainerHighest: AppColors.slate700,
  ),
);
