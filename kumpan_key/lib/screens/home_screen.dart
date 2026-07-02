import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/ble_key_service.dart';
import '../utils/permissions.dart';
import '../widgets/key_toggle.dart';
import '../widgets/status_card.dart';
import '../widgets/teaching_guide.dart';

/// Main screen of the Kumpan Key app.
///
/// Single-screen layout with:
/// - Language toggle (top right)
/// - Key toggle button (center)
/// - Status card (connection, battery, device name)
/// - Teaching guide (expandable)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleKeyService _bleService = BleKeyService();
  String _locale = 'en';
  String _bluetoothName = '';
  bool _permissionsGranted = false;
  bool _isLoading = true;

  AppStrings get _strings => AppStrings.of(_locale);

  @override
  void initState() {
    super.initState();
    _init();
  }

Future<void> _init() async {
    _locale = _detectSystemLocale();

    // Check permissions
    _permissionsGranted = await BlePermissions.areGranted();

    // Initialize BLE service and fetch real BT name
    await _bleService.init();
    _bleService.addListener(_onBleStateChanged);
    _bluetoothName = await _bleService.getBluetoothName();

    setState(() {
      _isLoading = false;
    });

    // NEU: Automatisch das Advertising starten, wenn Berechtigungen da sind
    if (_permissionsGranted) {
      await _onToggleKey();
    }
  }

  String _detectSystemLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return locale.languageCode == 'de' ? 'de' : 'en';
  }

  void _onBleStateChanged() {
    if (mounted) setState(() {});
  }

  void _toggleLanguage() {
    setState(() {
      _locale = _locale == 'en' ? 'de' : 'en';
    });
  }

  Future<void> _onToggleKey() async {
    // Request permissions if needed
    if (!_permissionsGranted) {
      _permissionsGranted = await BlePermissions.request();
      if (_permissionsGranted) {
        // Refresh BT name now that BLUETOOTH_CONNECT is granted
        final name = await _bleService.getBluetoothName();
        setState(() => _bluetoothName = name);
      }
      if (!_permissionsGranted) {
        final isPermanentlyDenied =
            await BlePermissions.isPermanentlyDenied();
        if (isPermanentlyDenied && mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }
    }

    final success = await _bleService.toggle();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_strings.advertisingFailed),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bleService.isAdvertising
                ? _strings.advertisingStarted
                : _strings.advertisingStopped,
          ),
          backgroundColor: _bleService.isAdvertising
              ? const Color(0xFF2E7D32)
              : const Color(0xFF616161),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          _strings.permissionsRequired,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          _strings.permissionsMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              BlePermissions.openSettings();
            },
            child: Text(_strings.grantPermissions),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bleService.removeListener(_onBleStateChanged);
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1565C0),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Key toggle
                    KeyToggle(
                      isActive: _bleService.isAdvertising,
                      isConnected: _bleService.isConnected,
                      onToggle: _onToggleKey,
                      label: _bleService.isAdvertising
                          ? _strings.keyActive
                          : _strings.keyInactive,
                      sublabel: _bleService.isAdvertising
                          ? _strings.tapToDeactivate
                          : _strings.tapToActivate,
                    ),
                    const SizedBox(height: 40),
                    // Status card
                    StatusCard(
                      statusKey: _bleService.statusKey,
                      batteryLevel: _bleService.batteryLevel,
                      bluetoothName: _bluetoothName,
                      strings: _strings,
                    ),
                    const SizedBox(height: 16),
                    // Teaching guide
                    TeachingGuide(strings: _strings),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          // App title
          const Text(
            'Kumpan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          const Text(
            ' Key',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Status dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bleService.isConnected
                  ? const Color(0xFF4CAF50)
                  : _bleService.isAdvertising
                      ? const Color(0xFF2196F3)
                      : Colors.white24,
              boxShadow: [
                if (_bleService.isAdvertising || _bleService.isConnected)
                  BoxShadow(
                    color: (_bleService.isConnected
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3))
                        .withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Language toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _locale == 'en' ? '🇬🇧 EN' : '🇩🇪 DE',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
