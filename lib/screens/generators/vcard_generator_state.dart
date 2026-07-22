import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';

class VCardGeneratorState {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final organizationController = TextEditingController();
  final websiteController = TextEditingController();

  int foregroundColor = 0xFF212121;
  int backgroundColor = 0xFFFFFFFF;
  double correctionLevel = 0.15;
  String? frameText;

  VCardQRData? currentQR;
  bool isSaved = false;

  static const int _defaultForegroundColor = 0xFF212121;
  static const int _defaultBackgroundColor = 0xFFFFFFFF;
  static const double _defaultCorrectionLevel = 0.15;

  bool get hasUnsavedChanges => currentQR != null && !isSaved;

  void reset() {
    fullNameController.clear();
    phoneController.clear();
    emailController.clear();
    organizationController.clear();
    websiteController.clear();
    foregroundColor = _defaultForegroundColor;
    backgroundColor = _defaultBackgroundColor;
    correctionLevel = _defaultCorrectionLevel;
    frameText = null;
    currentQR = null;
    isSaved = false;
  }

  void loadFromData(QRData data) {
    final fnMatch = RegExp(r'FN:(.+)').firstMatch(data.content);
    final telMatch = RegExp(r'TEL:(.+)').firstMatch(data.content);
    final emailMatch = RegExp(r'EMAIL:(.+)').firstMatch(data.content);
    final orgMatch = RegExp(r'ORG:(.+)').firstMatch(data.content);
    final urlMatch = RegExp(r'URL:(.+)').firstMatch(data.content);

    fullNameController.text = fnMatch?.group(1) ?? '';
    phoneController.text = telMatch?.group(1) ?? '';
    emailController.text = emailMatch?.group(1) ?? '';
    organizationController.text = orgMatch?.group(1) ?? '';
    websiteController.text = urlMatch?.group(1) ?? '';
    foregroundColor = data.foregroundColor;
    backgroundColor = data.backgroundColor;
    correctionLevel = data.correctionLevel;
    frameText = data.frameText;
    isSaved = true;
    currentQR = VCardQRData(
      fullName: fullNameController.text,
      phone: phoneController.text,
      email: emailController.text,
      organization: organizationController.text,
      website: websiteController.text,
      foregroundColor: data.foregroundColor,
      backgroundColor: data.backgroundColor,
      correctionLevel: data.correctionLevel,
      frameText: data.frameText,
    );
  }

  Future<void> saveToHistory(BuildContext context) async {
    if (currentQR == null) return;
    await HistoryService().addItem(currentQR!);
    isSaved = true;
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
    if (fullNameController.text.isEmpty) {
      currentQR = null;
      return;
    }
    isSaved = false;
    currentQR = VCardQRData(
      fullName: fullNameController.text,
      phone: phoneController.text,
      email: emailController.text,
      organization: organizationController.text,
      website: websiteController.text,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      correctionLevel: correctionLevel,
      frameText: frameText,
    );
  }

  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    organizationController.dispose();
    websiteController.dispose();
  }
}
