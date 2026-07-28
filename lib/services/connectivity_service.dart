import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  static final ConnectivityService _instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastState = true;

  Stream<bool> get onConnectivityChange => _controller.stream;
  bool get isOnline => _lastState;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _lastState = _isConnected(result);
    _controller.add(_lastState);

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final connected = _isConnected(result);
      if (connected != _lastState) {
        _lastState = connected;
        _controller.add(connected);
      }
    });
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _lastState = _isConnected(result);
    return _lastState;
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
