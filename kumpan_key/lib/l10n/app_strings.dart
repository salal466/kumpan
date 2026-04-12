// Localization strings for the Kumpan Key app.
// Supports English and German.

class AppStrings {
  final String locale;

  AppStrings(this.locale);

  static AppStrings of(String locale) => AppStrings(locale);

  String get appTitle => _get('appTitle');
  String get keyActive => _get('keyActive');
  String get keyInactive => _get('keyInactive');
  String get tapToActivate => _get('tapToActivate');
  String get tapToDeactivate => _get('tapToDeactivate');
  String get deviceName => _get('deviceName');
  String get deviceNameHint => _get('deviceNameHint');
  String get connectionStatus => _get('connectionStatus');
  String get connected => _get('connected');
  String get disconnected => _get('disconnected');
  String get advertising => _get('advertising');
  String get inactive => _get('inactive');
  String get phoneBattery => _get('phoneBattery');
  String get teachingGuide => _get('teachingGuide');
  String get teachingTitle => _get('teachingTitle');
  String get step1 => _get('step1');
  String get step2 => _get('step2');
  String get step3 => _get('step3');
  String get step4 => _get('step4');
  String get step5 => _get('step5');
  String get step6 => _get('step6');
  String get step7 => _get('step7');
  String get permissionsRequired => _get('permissionsRequired');
  String get permissionsMessage => _get('permissionsMessage');
  String get grantPermissions => _get('grantPermissions');
  String get bluetoothOff => _get('bluetoothOff');
  String get bluetoothOffMessage => _get('bluetoothOffMessage');
  String get advertisingStarted => _get('advertisingStarted');
  String get advertisingStopped => _get('advertisingStopped');
  String get advertisingFailed => _get('advertisingFailed');
  String get advertisingAs => _get('advertisingAs');
  String get language => _get('language');

  String _get(String key) {
    final map = locale == 'de' ? _de : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static const Map<String, String> _en = {
    'appTitle': 'Kumpan Key',
    'keyActive': 'Key Active',
    'keyInactive': 'Key Inactive',
    'tapToActivate': 'Tap to activate your scooter key',
    'tapToDeactivate': 'Tap to deactivate',
    'deviceName': 'Device Name',
    'deviceNameHint': 'Name shown on scooter display',
    'connectionStatus': 'Status',
    'connected': 'Connected',
    'disconnected': 'Disconnected',
    'advertising': 'Advertising',
    'inactive': 'Inactive',
    'phoneBattery': 'Phone Battery',
    'teachingGuide': 'How to pair',
    'teachingTitle': 'Key Teaching',
    'step1': 'Turn on your Kumpan scooter',
    'step2': 'Open the Scooter Menu via the display',
    'step3': 'Navigate to "Kumpan Key" → "New Key Search"',
    'step4': 'Activate the key in this app',
    'step5': 'Select your device name on the scooter display',
    'step6': 'Wait for confirmation',
    'step7': 'Done! Your scooter now recognizes your phone as key',
    'permissionsRequired': 'Permissions Required',
    'permissionsMessage':
        'Bluetooth and Location permissions are needed to use your phone as a scooter key.',
    'grantPermissions': 'Grant Permissions',
    'bluetoothOff': 'Bluetooth is off',
    'bluetoothOffMessage': 'Please enable Bluetooth to use the key.',
    'advertisingStarted': 'Key activated',
    'advertisingStopped': 'Key deactivated',
    'advertisingFailed': 'Failed to start BLE advertising',
    'advertisingAs': 'Advertising as',
    'language': 'Language',
  };

  static const Map<String, String> _de = {
    'appTitle': 'Kumpan Key',
    'keyActive': 'Schlüssel aktiv',
    'keyInactive': 'Schlüssel inaktiv',
    'tapToActivate': 'Tippen um den Roller-Schlüssel zu aktivieren',
    'tapToDeactivate': 'Tippen zum Deaktivieren',
    'deviceName': 'Gerätename',
    'deviceNameHint': 'Name auf dem Rollerdisplay',
    'connectionStatus': 'Status',
    'connected': 'Verbunden',
    'disconnected': 'Getrennt',
    'advertising': 'Sendet',
    'inactive': 'Inaktiv',
    'phoneBattery': 'Handy-Akku',
    'teachingGuide': 'Anlernen',
    'teachingTitle': 'Schlüssel anlernen',
    'step1': 'Schalte deinen Kumpan Roller an',
    'step2': 'Öffne das Roller-Menü über das Display',
    'step3': 'Navigiere zu "Kumpan Key" → "Neuen Schlüssel suchen"',
    'step4': 'Aktiviere den Schlüssel in dieser App',
    'step5': 'Wähle deinen Gerätenamen auf dem Rollerdisplay',
    'step6': 'Warte auf die Bestätigung',
    'step7':
        'Fertig! Dein Roller erkennt nun dein Smartphone als Schlüssel',
    'permissionsRequired': 'Berechtigungen erforderlich',
    'permissionsMessage':
        'Bluetooth- und Standort-Berechtigungen werden benötigt, um dein Smartphone als Roller-Schlüssel zu verwenden.',
    'grantPermissions': 'Berechtigungen erteilen',
    'bluetoothOff': 'Bluetooth ist aus',
    'bluetoothOffMessage':
        'Bitte aktiviere Bluetooth, um den Schlüssel zu verwenden.',
    'advertisingStarted': 'Schlüssel aktiviert',
    'advertisingStopped': 'Schlüssel deaktiviert',
    'advertisingFailed': 'BLE-Advertising konnte nicht gestartet werden',
    'advertisingAs': 'Sendet als',
    'language': 'Sprache',
  };
}
