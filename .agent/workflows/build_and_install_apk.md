---
description: Build and install the Android APK
---

# Build and Install APK

## 1. Build the APK
Run the following command to build a release APK:
```bash
flutter build apk --release
```

## 2. Locate the APK
Once the build completes, the APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## 3. Install on Device
### Option A: Via USB (ADB)
Connect your phone via USB, enable USB Debugging, and run:
```bash
flutter install
```
Or install the specific APK:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Manual Transfer
1.  Copy `app-release.apk` to your phone (via USB, Google Drive, WhatsApp, etc.).
2.  Open the file on your phone and tap **Install**.
    *   *Note: You may need to allow installation from unknown sources.*

## 4. Configure App
1.  Open the app on your phone.
2.  Open the **Sidebar** -> **Settings**.
3.  Enter your PC's Local IP Address (e.g., `http://192.168.1.5:8000`).
    *   *Tip: Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) on your PC to find your IP.*
4.  Tap **Save Configuration**.
