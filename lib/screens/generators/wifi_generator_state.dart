import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import 'base_generator_state.dart';

class WiFiGeneratorState extends BaseGeneratorState<WiFiQRData> {
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  String encryptionType = 'WPA';
  bool isHidden = false;
  bool obscurePassword = true;

  @override
  void reset() {
    ssidController.clear();
    passwordController.clear();
    encryptionType = 'WPA';
    isHidden = false;
    obscurePassword = true;
    resetBase();
  }

  @override
  void loadFromData(QRData data, {bool markAsSaved = true}) {
    final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(data.content);
    final passMatch = RegExp(r'P:([^;]+)').firstMatch(data.content);
    final typeMatch = RegExp(r'T:([^;]+)').firstMatch(data.content);
    final hiddenMatch = RegExp(r'H:true').firstMatch(data.content);

    ssidController.text = ssidMatch?.group(1) ?? '';
    passwordController.text = passMatch?.group(1) ?? '';
    encryptionType = typeMatch?.group(1) ?? 'WPA';
    isHidden = hiddenMatch != null;
    loadBase(data, markAsSaved: markAsSaved);
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

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
  }
}
