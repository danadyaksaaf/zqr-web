import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

abstract class BaseGeneratorState<T extends QRData> {
  static const int defaultForegroundColor = 0xFF212121;
  static const int defaultBackgroundColor = 0xFFFFFFFF;
  static const double defaultCorrectionLevel = 0.15;

  int foregroundColor = defaultForegroundColor;
  int backgroundColor = defaultBackgroundColor;
  double correctionLevel = defaultCorrectionLevel;
  String? frameText;

  T? currentQR;
  bool isSaved = false;

  bool get hasUnsavedChanges => currentQR != null && !isSaved;

  void resetBase() {
    foregroundColor = defaultForegroundColor;
    backgroundColor = defaultBackgroundColor;
    correctionLevel = defaultCorrectionLevel;
    frameText = null;
    currentQR = null;
    isSaved = false;
  }

  void loadBase(QRData data, {bool markAsSaved = true}) {
    foregroundColor = data.foregroundColor;
    backgroundColor = data.backgroundColor;
    correctionLevel = data.correctionLevel;
    frameText = data.frameText;
    isSaved = markAsSaved;
  }

  Future<void> saveToHistory(BuildContext context) async {
    if (currentQR == null) return;
    isSaved = true;
    await HistoryService().addItem(currentQR!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code saved to history'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
