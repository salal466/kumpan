import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

/// Handles BLE-related permission requests for Android 12+ and iOS.
class BlePermissions {
  /// Check if all required BLE permissions are granted.
  static Future<bool> areGranted() async {
    if (Platform.isAndroid) {
      final bluetoothAdvertise =
          await Permission.bluetoothAdvertise.isGranted;
      final bluetoothConnect =
          await Permission.bluetoothConnect.isGranted;
      final location = await Permission.locationWhenInUse.isGranted;
      return bluetoothAdvertise && bluetoothConnect && location;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.isGranted;
      return bluetooth;
    }
    return false;
  }

  /// Request all required BLE permissions.
  /// Returns true if all permissions were granted.
  static Future<bool> request() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.locationWhenInUse,
      ].request();

      return statuses.values.every(
        (status) => status.isGranted || status.isLimited,
      );
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }

  /// Check if any permission is permanently denied.
  static Future<bool> isPermanentlyDenied() async {
    if (Platform.isAndroid) {
      return await Permission.bluetoothAdvertise.isPermanentlyDenied ||
          await Permission.bluetoothConnect.isPermanentlyDenied ||
          await Permission.locationWhenInUse.isPermanentlyDenied;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isPermanentlyDenied;
    }
    return false;
  }

  /// Open app settings so user can manually grant permissions.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
