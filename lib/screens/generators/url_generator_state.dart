import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

class URLGeneratorState {
  final urlController = TextEditingController();
  bool isDynamicShortLink = false;
  int foregroundColor = 0xFF212121;
  int backgroundColor = 0xFFFFFFFF;
  double correctionLevel = 0.15;
  String? frameText;

  URLQRData? currentQR;
  bool isSaved = false;

  static const int _defaultForegroundColor = 0xFF212121;
  static const int _defaultBackgroundColor = 0xFFFFFFFF;
  static const double _defaultCorrectionLevel = 0.15;

  bool get hasUnsavedChanges => currentQR != null && !isSaved;

  void reset() {
    urlController.clear();
    isDynamicShortLink = false;
    foregroundColor = _defaultForegroundColor;
    backgroundColor = _defaultBackgroundColor;
    correctionLevel = _defaultCorrectionLevel;
    frameText = null;
    currentQR = null;
    isSaved = false;
  }

  void loadFromData(QRData data, {bool markAsSaved = true}) {
    urlController.text = data.content;
    foregroundColor = data.foregroundColor;
    backgroundColor = data.backgroundColor;
    correctionLevel = data.correctionLevel;
    frameText = data.frameText;
    isSaved = markAsSaved;
    currentQR = URLQRData(
      url: data.content,
      foregroundColor: data.foregroundColor,
      backgroundColor: data.backgroundColor,
      correctionLevel: data.correctionLevel,
      frameText: data.frameText,
    );
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

  void generateQR() {
    if (urlController.text.isEmpty) {
      currentQR = null;
      return;
    }
    isSaved = false;
    currentQR = URLQRData(
      url: urlController.text,
      isDynamicShortLink: isDynamicShortLink,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      correctionLevel: correctionLevel,
      frameText: frameText,
    );
  }

  void dispose() {
    urlController.dispose();
  }
}
