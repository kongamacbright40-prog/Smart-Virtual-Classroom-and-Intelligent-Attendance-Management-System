import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../errors/error_handler.dart';

/// Miscellaneous UI helpers.
abstract final class Helpers {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : null,
        ),
      );
  }

  static void showError(BuildContext context, Object error) =>
      showSnackBar(context, ErrorHandler.message(error), isError: true);

  static void unfocus(BuildContext context) =>
      FocusScope.of(context).unfocus();

  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= AppDimensions.smallPhoneWidth;

  /// Color used for an attendance percentage (green / amber / red).
  static Color attendanceColor(double percent) {
    if (percent >= 85) return AppColors.success;
    if (percent >= 75) return AppColors.warning;
    return AppColors.error;
  }

  /// Label used next to an attendance percentage in the Stitch designs.
  static String attendanceLabel(double percent) {
    if (percent >= 93) return 'Excellent';
    if (percent >= 85) return 'Good Standing';
    if (percent >= 75) return 'Satisfactory';
    return 'At Risk';
  }
}
