import '../../models/qr_data.dart';

abstract class GeneratorResettable {
  bool get hasUnsavedChanges;
  void reset();
  void loadFromData(QRData data);
  Future<void> saveToHistory();
}
