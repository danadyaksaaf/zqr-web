import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_data.dart';

class HistoryService {
  static const String _historyKey = 'qr_history';
  static final HistoryService _instance = HistoryService._internal();
  
  factory HistoryService() => _instance;
  HistoryService._internal();

  List<QRData> _history = [];
  
  List<QRData> get history => List.unmodifiable(_history);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _history = historyJson
        .map((json) => QRData.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addItem(QRData data) async {
    _history.insert(0, data);
    await _save();
  }

  Future<void> removeItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _save();
  }

  Future<void> clear() async {
    _history.clear();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }
}
