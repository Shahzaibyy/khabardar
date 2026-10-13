# Khabardar · خبردار

**Fraud se pehle, Khabardar.** An offline-first Android app that catches scam calls and SMS in Pakistan (fake BISP payouts, bank OTP fraud, prize and courier scams) before the user loses money.

The UI is Flutter. Everything that has to run when the app is closed is native Kotlin: call screening, the SMS check and the warning overlay over banking apps. Detection runs entirely on the phone. The sync backend is not built yet. The app ships with a demo threat list until it is.

## What works today

| Feature | Where | How |
| --- | --- | --- |
| Scam call screening | `ScamCallScreeningService.kt` | Android's Call Screening role (Android 10+). Known scam numbers are blocked silently, or ring with a warning banner, depending on settings. |
| SMS check | `SmsShieldReceiver.kt` | Each incoming SMS is scored on the device. Only a masked preview is stored, with OTPs, CNICs and account numbers removed. |
| Banking-app alert | `BankingGuardService.kt`, `OverlayController.kt` | After a scam call or SMS, the app watches for 10 minutes. If a wallet or banking app opens in that time, a full-screen warning appears, with a forced 5-second pause before the user can continue. |
| Check a number, link or message | `check_screen.dart` | Offline lookup with a risk score and the reasons behind it. |
| Report a scam | `report_screen.dart` | Blocks the number on the phone and queues a hashed, masked report for the future backend. |
| Activity history | `activity_screen.dart` | Lists flagged SMS, warned or blocked calls and banking alerts, with the reasons for each. |
| English and Urdu | `l10n.dart`, `NativeStrings.kt` | Full right-to-left (RTL) layout, using Noto Nastaliq Urdu. |
| Privacy | `ShieldStore.kt`, `data_extraction_rules.xml` | No contacts, call log or messages are uploaded. Nothing is included in cloud backups. Numbers are compared as HMAC-SHA-256 hashes. |

Screens: splash, onboarding (3 slides with a language switch), permissions, home dashboard, activity, check, report, event detail (call, SMS or banking alert), and settings with a privacy promise, test alerts and data deletion.

## Project layout

```
lib/
  main.dart                  app shell, splash -> onboarding -> home, opens alerts from notifications
  app_state.dart             settings, permissions, history, block/report
  detection/                 offline engine (shared logic with Kotlin)
    engine.dart              keyed-hash number lookup + weighted regex rules
    normalizer.dart          +92 E.164 normalisation
    masking.dart             removes OTPs, CNICs, account numbers
  native/bridge.dart         MethodChannel / EventChannel to Kotlin
  screens/                   every screen from the design
  widgets/logo.dart          the Khabardar shield, drawn in code
  l10n.dart                  English + Urdu copy
assets/
  threat/threat_set.json     demo threat list (shared by Dart and Kotlin)
  fonts/                     Manrope, Noto Nastaliq Urdu (SIL OFL)
  brand/                     512 px store icon
android/app/src/main/kotlin/pk/khabardar/app/
  MainActivity.kt            channel handlers, permission requests
  detection/                 Kotlin port of the engine
  call/                      CallScreeningService
  sms/                       SMS_RECEIVED receiver
  guard/                     banking guard foreground service
  alerts/                    notifications, overlays, native copy
  data/ShieldStore.kt        on-device storage
```

## How detection works

1. Numbers are normalised to `+92…` and hashed with HMAC-SHA-256, then looked up in the threat list.
2. Messages are scored against weighted rules covering BISP mentions, fee requests, OTP requests, account threats, prizes, urgency, impersonation of officials, courier fees and risky links. A sender that imitates `8171` adds weight.
3. A score of 60 or more counts as **scam**. A score of 30 or more counts as **suspicious**.
4. Dart and Kotlin read the same `threat_set.json` file. Tests on both sides check that they produce the same hashes and the same verdicts.

> The numbers in `threat_set.json` are fake placeholders, and the HMAC key is a development key. The backend should replace both through signed sync. Do not ship them as they are.

## Run it

Requirements: Flutter 3.47+ (Dart 3.13+), the Android SDK (installed with Android Studio), and a phone running Android 8 or newer. Call screening needs Android 10 or newer.

```bash
flutter pub get
flutter test                       # Dart engine + widget tests
flutter run                        # on a connected Android phone
cd android && ./gradlew test       # Kotlin engine tests
```

To try the alerts without a real scam call: open the **Settings** tab, then **Test alerts**. You can also use **Check** with `0300 0000111` (a demo scam number).

## Permissions and Google Play

| Permission | Why | Play note |
| --- | --- | --- |
| Call Screening role | Screen calls before they ring | Preferred over `READ_CALL_LOG` |
| `RECEIVE_SMS` | Check new SMS | Restricted. Needs the Permissions Declaration Form. Publishing may require becoming the default SMS app, or switching to a notification-listener approach. |
| `SYSTEM_ALERT_WINDOW` | Warning over the call screen and wallet apps | Requires prominent disclosure |
| `PACKAGE_USAGE_STATS` | Know which app is in front (package name only) | User grants it in Settings |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Banking guard for 10 minutes after a scam | Needs a justification in Play Console |

No Accessibility Service is used.

## Not built yet

- Sync backend (Go or FastAPI): signed threat-list updates, k-anonymity lookups, report upload.
- An encrypted database (SQLCipher/Room). Data currently lives in app-private SharedPreferences, which is enough for the hashes and masked text stored today.
- Real package IDs for every wallet and bank app. The list in `threat_set.json` needs checking against the Play Store.
- The NCCIA complaint URL in `report_screen.dart` needs checking before release.
- Release signing and the Play Store listing.
