# Kumpan Key — Replacement BLE Key App

A replacement for the defunct Kumpan e-scooter key app, built with Flutter.

The original Kumpan Key app stopped working on Android 12+ due to new Bluetooth permission requirements that were never addressed. This replacement implements the correct permissions and works on modern Android (15+).

## In Plain English

The Kumpan scooter won't start unless it detects its key nearby over Bluetooth — similar to how a modern car won't start without its key fob in your pocket. This app does exactly that: it makes your phone broadcast a specific Bluetooth signal that the scooter recognises as "key present".

**What the app does:** Makes your phone continuously broadcast a Bluetooth signal (specifically, a standard Battery Service identifier). As long as your phone is within ~25 metres and the signal is on, the scooter thinks its key is nearby and lets you start it. Turn the signal off and the scooter locks.

**Nothing is installed on the scooter.** The scooter just listens for the signal. The one-time teach-in process (Menu → Kumpan Key → New Key Search) tells the scooter which specific phone to listen for.

## How It Works (Technical)

The phone acts as a **BLE Peripheral** (GATT Server) — the reverse of the usual phone-as-client setup. It advertises a standard Bluetooth Battery Service, which the Kumpan scooter's ECU detects as "key present".

### BLE Components

| Component | UUID | What it is |
|---|---|---|
| **Battery Service** | `0000180F-0000-1000-8000-00805f9b34fb` | A standard Bluetooth SIG service, used here as the key identifier the scooter looks for. The scooter treats presence of this service as authentication. |
| **Battery Level** | `00002A19-0000-1000-8000-00805f9b34fb` | A characteristic inside the Battery Service. Holds the phone's current battery percentage (0–100). The scooter can read this and display it. |
| **CCCD** | `00002902-0000-1000-8000-00805f9b34fb` | Client Characteristic Configuration Descriptor. A standard BLE descriptor that tells the scooter it can subscribe to Battery Level notifications — i.e. get updated automatically when the value changes rather than polling. |

All three UUIDs are part of the official Bluetooth SIG specification, not custom or proprietary.

## Setup

### Prerequisites
- [Flutter SDK 3.27+](https://docs.flutter.dev/get-started/install) — on macOS: `brew install --cask flutter`
- [Android Studio](https://developer.android.com/studio) with Android SDK (API 36) and Command-line Tools installed via SDK Manager → SDK Tools
- After installing Android Studio, point Flutter at the SDK:
  ```bash
  flutter config --android-sdk ~/Library/Android/sdk
  flutter doctor --android-licenses   # accept all with 'y'
  ```
- A physical Android device — BLE peripheral mode does not work in emulators

### Build & Run (development)

```bash
cd kumpan_key
flutter pub get
flutter run          # builds, installs, and launches on a connected device
```

### Build Release APK

```bash
cd kumpan_key
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install the APK on your phone

**Via USB (technical):**
```bash
# macOS — adb is bundled with Android Studio
~/Library/Android/sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-release.apk

# If upgrading from a previous install with the same package ID:
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Without USB (non-technical):**
1. Copy `app-release.apk` to your phone via AirDrop, Google Drive, email, or a USB cable in file-transfer mode
2. Open the file on your phone — Android will prompt you to install it
3. If prompted, allow "Install from unknown sources" in Settings → Security (one-time)

### Generate Icons (after modifying `assets/icon.png`)

```bash
dart run flutter_launcher_icons
flutter build apk --release   # rebuild after icon change
```

## Pairing with Your Scooter

1. Open the Kumpan Key app
2. Tap the key button to activate — your phone's Bluetooth name will be shown on the scooter display
3. On the scooter: go to Menu → Kumpan Key → New Key Search
4. Select your device name on the scooter display
5. Wait for confirmation
6. Done — your phone is now a key

## Features

- One-tap key activation
- Works on Android 12+
- Reports phone battery level to scooter
- English/German language support
- Connection status indicator
- Built-in pairing guide

## Tested With

- Kumpan 54i
- Android 15

## Security

**Is this a security risk?** Honestly, yes — but no more so than the original Kumpan system. The scooter uses *presence-based* authentication: it checks whether the right Bluetooth signal is nearby, not whether the sender is cryptographically authenticated. There is no PIN, no encrypted handshake, no challenge-response.

What this means in practice:

| Scenario | Risk |
|---|---|
| Random person downloads this app | Low — the scooter is paired to your specific device during teach-in. A stranger's phone won't be recognised. |
| Someone physically accesses your scooter's menu | High — they can teach their own phone as a key in ~30 seconds, just like adding a spare car key. |
| Someone within 25m with a paired device | Medium — they could start it remotely, same as with the original app or a key fob. |
| Phone Bluetooth left on while parked | Low-medium — tap the key button to stop advertising when parked, or disable Bluetooth. |

The bottom line: the security model is equivalent to a traditional physical key. Guard access to your scooter's menu the same way you'd guard a spare key.

**To lock when parked:** Tap the key button in the app to stop advertising, or turn off Bluetooth. The scooter won't start without the signal.

## License

Apache 2

Built with Claude by Adrian Gschwend
