import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// Status card showing connection state, battery level, and device name.
class StatusCard extends StatelessWidget {
  final String statusKey;
  final int batteryLevel;
  final String bluetoothName;
  final AppStrings strings;

  const StatusCard({
    super.key,
    required this.statusKey,
    required this.batteryLevel,
    required this.bluetoothName,
    required this.strings,
  });

  Color get _statusColor {
    switch (statusKey) {
      case 'connected':
        return const Color(0xFF4CAF50);
      case 'advertising':
        return const Color(0xFF2196F3);
      default:
        return Colors.white38;
    }
  }

  IconData get _statusIcon {
    switch (statusKey) {
      case 'connected':
        return Icons.link_rounded;
      case 'advertising':
        return Icons.bluetooth_searching_rounded;
      default:
        return Icons.bluetooth_disabled_rounded;
    }
  }

  String get _statusText {
    switch (statusKey) {
      case 'connected':
        return strings.connected;
      case 'advertising':
        return strings.advertising;
      default:
        return strings.inactive;
    }
  }

  Color get _batteryColor {
    if (batteryLevel > 60) return const Color(0xFF4CAF50);
    if (batteryLevel > 20) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  IconData get _batteryIcon {
    if (batteryLevel > 80) return Icons.battery_full_rounded;
    if (batteryLevel > 60) return Icons.battery_5_bar_rounded;
    if (batteryLevel > 40) return Icons.battery_4_bar_rounded;
    if (batteryLevel > 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Status row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(_statusIcon, color: _statusColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  strings.connectionStatus,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          // Battery row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Icon(_batteryIcon, color: _batteryColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  strings.phoneBattery,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '$batteryLevel%',
                  style: TextStyle(
                    color: _batteryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          // Device name row (read-only — shows actual BT adapter name)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth_rounded,
                  color: Colors.white38,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  strings.advertisingAs,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  bluetoothName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
