import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:battery_plus/battery_plus.dart';

/// BLE Key Service — manages GATT server + BLE advertising.
///
/// The phone acts as a BLE Peripheral exposing a standard Battery Service.
/// The Kumpan scooter treats the presence of this BLE device as "key present".
///
/// BLE Protocol:
///   Service:        0x180F (Battery Service)
///   Characteristic: 0x2A19 (Battery Level) — reports phone battery %
///   Descriptor:     0x2902 (CCCD)
class BleKeyService extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final Battery _battery = Battery();

  bool _isAdvertising = false;
  bool _isConnected = false;
  int _batteryLevel = 100;
  StreamSubscription<PeripheralState>? _advertisingSubscription;
  Timer? _batteryTimer;

  bool get isAdvertising => _isAdvertising;
  bool get isConnected => _isConnected;
  int get batteryLevel => _batteryLevel;

  String get statusKey {
    if (_isConnected) return 'connected';
    if (_isAdvertising) return 'advertising';
    return 'inactive';
  }

  /// Initialize the BLE peripheral and start monitoring.
  Future<void> init() async {
    // Listen to advertising state changes
    _advertisingSubscription =
        _blePeripheral.onPeripheralStateChanged?.listen((state) {
      _isAdvertising = state == PeripheralState.advertising;
      _isConnected = state == PeripheralState.connected;
      notifyListeners();
    });

    // Read initial battery level
    await _updateBatteryLevel();
  }

  /// Start BLE advertising and GATT server.
  Future<bool> startAdvertising() async {
    try {
      final isSupported = await _blePeripheral.isSupported;
      if (!isSupported) {
        debugPrint('BLE peripheral mode not supported on this device');
        return false;
      }

      await _updateBatteryLevel();

      // Start native GATT server so the scooter can read Battery Level
      await _channel.invokeMethod('startGattServer', {'batteryLevel': _batteryLevel});

      // Start BLE advertising
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: '0000180F-0000-1000-8000-00805f9b34fb',
          includePowerLevel: false,
          includeDeviceName: true,
        ),
        advertiseSettings: AdvertiseSettings(
          advertiseMode: AdvertiseMode.advertiseModeBalanced,
          connectable: true,
          timeout: 0,
          txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
        ),
      );

      _isAdvertising = true;

      // Periodically refresh battery level in GATT server
      _batteryTimer?.cancel();
      _batteryTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateBatteryLevel(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to start advertising: $e');
      return false;
    }
  }

  /// Stop BLE advertising and tear down the GATT server.
  Future<void> stopAdvertising() async {
    try {
      await _blePeripheral.stop();
      await _channel.invokeMethod('stopGattServer');
      _isAdvertising = false;
      _isConnected = false;
      _batteryTimer?.cancel();
      _batteryTimer = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to stop advertising: $e');
    }
  }

  /// Toggle advertising state.
  Future<bool> toggle() async {
    if (_isAdvertising) {
      await stopAdvertising();
      return true;
    } else {
      return await startAdvertising();
    }
  }

  /// Update the battery level and push it to the GATT server if active.
  Future<void> _updateBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      if (_isAdvertising) {
        await _channel.invokeMethod('updateBatteryLevel', {'level': _batteryLevel});
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to read battery level: $e');
    }
  }

  /// Returns the device's actual Bluetooth adapter name (e.g. "Zenfone 10").
  static const _channel = MethodChannel('org.netlabs.ktk.kumpankey/bluetooth');

  Future<String> getBluetoothName() async {
    try {
      final name = await _channel.invokeMethod<String>('getBluetoothName');
      return name ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if BLE peripheral mode is supported.
  Future<bool> isSupported() async {
    try {
      return await _blePeripheral.isSupported;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _advertisingSubscription?.cancel();
    _batteryTimer?.cancel();
    stopAdvertising();
    super.dispose();
  }
}
