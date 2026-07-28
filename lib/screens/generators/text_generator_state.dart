import 'package:flutter/material.dart';
import '../../models/qr_data.dart';
import 'base_generator_state.dart';

class TextGeneratorState extends BaseGeneratorState<TextQRData> {
  final textController = TextEditingController();

  @override
  void reset() {
    textController.clear();
    resetBase();
  }

  @override
  void loadFromData(QRData data, {bool markAsSaved = true}) {
    textController.text = data.content;
    loadBase(data, markAsSaved: markAsSaved);
    currentQR = TextQRData(
      text: data.content,
      foregroundColor: data.foregroundColor,
      backgroundColor: data.backgroundColor,
      correctionLevel: data.correctionLevel,
      frameText: data.frameText,
    );
  }

  void generateQR() {
    if (textController.text.isEmpty) {
      currentQR = null;
      return;
    }
    isSaved = false;
    currentQR = TextQRData(
      text: textController.text,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      correctionLevel: correctionLevel,
      frameText: frameText,
    );
  }

  @override
  void dispose() {
    textController.dispose();
  }
}
