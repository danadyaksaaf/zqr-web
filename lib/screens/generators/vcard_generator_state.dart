import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import 'base_generator_state.dart';

class VCardGeneratorState extends BaseGeneratorState<VCardQRData> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final organizationController = TextEditingController();
  final websiteController = TextEditingController();

  @override
  void reset() {
    fullNameController.clear();
    phoneController.clear();
    emailController.clear();
    organizationController.clear();
    websiteController.clear();
    resetBase();
  }

  @override
  void loadFromData(QRData data, {bool markAsSaved = true}) {
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
    loadBase(data, markAsSaved: markAsSaved);
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

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    organizationController.dispose();
    websiteController.dispose();
  }
}
