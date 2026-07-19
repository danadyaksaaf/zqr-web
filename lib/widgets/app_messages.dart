import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppMessages {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppTheme.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppTheme.error);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
