import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import 'base_generator_state.dart';

class URLGeneratorState extends BaseGeneratorState<URLQRData> {
  final urlController = TextEditingController();
  bool isDynamicShortLink = false;

  @override
  void reset() {
    urlController.clear();
    isDynamicShortLink = false;
    resetBase();
  }

  @override
  void loadFromData(QRData data, {bool markAsSaved = true}) {
    urlController.text = data.content;
    loadBase(data, markAsSaved: markAsSaved);
    currentQR = URLQRData(
      url: data.content,
      foregroundColor: data.foregroundColor,
      backgroundColor: data.backgroundColor,
      correctionLevel: data.correctionLevel,
      frameText: data.frameText,
    );
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

  @override
  void dispose() {
    urlController.dispose();
  }
}
