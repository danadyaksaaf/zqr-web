import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

class WiFiGeneratorState {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  String encryptionType = 'WPA';
  bool isHidden = false;
  bool obscurePassword = true;

  int foregroundColor = 0xFF212121;
  int backgroundColor = 0xFFFFFFFF;
  double correctionLevel = 0.15;
  String? frameText;

  WiFiQRData? currentQR;
  bool isSaved = false;

  static const int _defaultForegroundColor = 0xFF212121;
  static const int _defaultBackgroundColor = 0xFFFFFFFF;
  static const double _defaultCorrectionLevel = 0.15;

  bool get hasUnsavedChanges => currentQR != null && !isSaved;

  void reset() {
    ssidController.clear();
    passwordController.clear();
    encryptionType = 'WPA';
    isHidden = false;
    obscurePassword = true;
    foregroundColor = _defaultForegroundColor;
    backgroundColor = _defaultBackgroundColor;
    correctionLevel = _defaultCorrectionLevel;
    frameText = null;
    currentQR = null;
    isSaved = false;
  }

  void loadFromData(QRData data, {bool markAsSaved = true}) {
    final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(data.content);
    final passMatch = RegExp(r'P:([^;]+)').firstMatch(data.content);
    final typeMatch = RegExp(r'T:([^;]+)').firstMatch(data.content);
    final hiddenMatch = RegExp(r'H:true').firstMatch(data.content);

    ssidController.text = ssidMatch?.group(1) ?? '';
    passwordController.text = passMatch?.group(1) ?? '';
    encryptionType = typeMatch?.group(1) ?? 'WPA';
    isHidden = hiddenMatch != null;
    foregroundColor = data.foregroundColor;
    backgroundColor = data.backgroundColor;
    correctionLevel = data.correctionLevel;
    frameText = data.frameText;
    isSaved = markAsSaved;
    currentQR = WiFiQRData(
      ssid: ssidController.text,
      password: passwordController.text,
      encryptionType: encryptionType,
      isHidden: isHidden,
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
    if (ssidController.text.isEmpty) {
      currentQR = null;
      return;
    }
    isSaved = false;
    currentQR = WiFiQRData(
      ssid: ssidController.text,
      password: passwordController.text,
      encryptionType: encryptionType,
      isHidden: isHidden,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      correctionLevel: correctionLevel,
      frameText: frameText,
    );
  }

  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
  }
}
