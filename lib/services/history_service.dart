import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_data.dart';

class HistoryService {
  factory HistoryService() => _instance;

  HistoryService._internal();

  static const String _historyKey = 'qr_history';
  static final HistoryService _instance = HistoryService._internal();

  final StreamController<List<QRData>> _controller =
      StreamController<List<QRData>>.broadcast();

  List<QRData> _history = [];
  SharedPreferences? _prefs;

  List<QRData> get history => List.unmodifiable(_history);
  Stream<List<QRData>> get historyStream => _controller.stream;

  Future<void> init([SharedPreferences? prefs]) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();
    final historyJson = _prefs!.getStringList(_historyKey) ?? [];
    _history = historyJson
        .map((json) => QRData.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addItem(QRData data) async {
    _history.insert(0, data);
    await _save();
    _controller.add(history);
  }

  Future<void> removeItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _save();
    _controller.add(history);
  }

  Future<void> clear() async {
    _history.clear();
    await _save();
    _controller.add(history);
  }

  Future<void> _save() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final historyJson =
        _history.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }

  void dispose() {
    _controller.close();
  }
}
