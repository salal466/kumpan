import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';

/// BLE Key Service — manages native GATT server + BLE advertising
/// through platform channels.
///
/// The phone acts as a BLE Peripheral exposing a standard Battery Service.
/// The Kumpan scooter treats the presence of this BLE device as "key present".
///
/// All BLE work (GATT server + advertising) is done natively in Kotlin
/// to ensure they are properly coordinated by Android's BLE stack.
///
/// BLE Protocol:
///   Service:        0x180F (Battery Service)
///   Characteristic: 0x2A19 (Battery Level) — reports phone battery %
///   Descriptor:     0x2902 (CCCD)
class BleKeyService extends ChangeNotifier {
  static const _channel =
      MethodChannel('org.netlabs.ktk.kumpankey/bluetooth');
  static const _stateChannel =
      EventChannel('org.netlabs.ktk.kumpankey/state');

  final Battery _battery = Battery();

  bool _isAdvertising = false;
  bool _isConnected = false;
  int _batteryLevel = 100;
  StreamSubscription? _stateSubscription;
  Timer? _batteryTimer;

  bool get isAdvertising => _isAdvertising;
  bool get isConnected => _isConnected;
  int get batteryLevel => _batteryLevel;

  String get statusKey {
    if (_isConnected) return 'connected';
    if (_isAdvertising) return 'advertising';
    return 'inactive';
  }

  /// Initialize: listen to native BLE state events and read battery.
  Future<void> init() async {
    // Listen to state updates from native side
    _stateSubscription = _stateChannel
        .receiveBroadcastStream()
        .listen(_onStateUpdate, onError: (e) {
      debugPrint('BLE state stream error: $e');
    });

    // Sync initial state
    try {
      final state = await _channel.invokeMapMethod<String, dynamic>('getState');
      if (state != null) _applyState(state);
    } catch (e) {
      debugPrint('Failed to get initial state: $e');
    }

    await _updateBatteryLevel();
  }

  void _onStateUpdate(dynamic event) {
    if (event is Map) {
      _applyState(Map<String, dynamic>.from(event));
    }
  }

  void _applyState(Map<String, dynamic> state) {
    _isAdvertising = state['isAdvertising'] as bool? ?? false;
    _isConnected = state['isConnected'] as bool? ?? false;
    notifyListeners();
  }

  /// Start native GATT server + BLE advertising.
  Future<bool> start() async {
    try {
      await _updateBatteryLevel();

      final success = await _channel.invokeMethod<bool>(
        'start',
        {'batteryLevel': _batteryLevel},
      );

      if (success == true) {
        _isAdvertising = true;

        // Periodically refresh battery level
        _batteryTimer?.cancel();
        _batteryTimer = Timer.periodic(
          const Duration(seconds: 30),
          (_) => _pushBatteryLevel(),
        );

        notifyListeners();
      }

      return success == true;
    } catch (e) {
      debugPrint('Failed to start: $e');
      return false;
    }
  }

  /// Stop native GATT server + BLE advertising.
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
      _isAdvertising = false;
      _isConnected = false;
      _batteryTimer?.cancel();
      _batteryTimer = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop: $e');
    }
  }

  /// Toggle advertising state.
  Future<bool> toggle() async {
    if (_isAdvertising) {
      await stop();
      return true;
    } else {
      return await start();
    }
  }

  /// Read battery level and update native GATT server.
  Future<void> _updateBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to read battery level: $e');
    }
  }

  /// Push current battery level to the native GATT server.
  Future<void> _pushBatteryLevel() async {
    await _updateBatteryLevel();
    if (_isAdvertising) {
      try {
        await _channel.invokeMethod(
          'updateBatteryLevel',
          {'level': _batteryLevel},
        );
      } catch (e) {
        debugPrint('Failed to push battery level: $e');
      }
    }
  }

  /// Returns the device's actual Bluetooth adapter name.
  Future<String> getBluetoothName() async {
    try {
      final name = await _channel.invokeMethod<String>('getBluetoothName');
      return name ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _batteryTimer?.cancel();
    stop();
    super.dispose();
  }
}
