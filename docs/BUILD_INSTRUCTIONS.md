# Build Instructions

## Android Release Build

### Prerequisites
```bash
# Install Android Studio
# Install Flutter SDK 3.0+
flutter doctor
```

### Build Steps

1. **Update version in pubspec.yaml**
```yaml
version: 1.0.0+1
```

2. **Create keystore** (first time only)
```bash
cd android
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mortar
```

3. **Configure signing** (android/key.properties)
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=mortar
storeFile=key.jks
```

4. **Build APK**
```bash
flutter build apk --release
```

5. **Build App Bundle (Play Store)**
```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## iOS TestFlight Build

### Prerequisites
- macOS with Xcode 14+
- Apple Developer Account ($99/year)
- Registered iOS device for testing

### Build Steps

1. **Open iOS project**
```bash
cd ios
open Runner.xcworkspace
```

2. **Configure signing in Xcode**
- Select Runner target
- Signing & Capabilities
- Select your Team
- Set Bundle Identifier: `com.mortarcalculator.app`

3. **Archive for distribution**
- Product → Archive
- Wait for build
- Select archive → Distribute App
- Choose "App Store Connect"

4. **Upload to TestFlight**
- Follow prompts in Xcode
- App will appear in App Store Connect
- Add beta testers in App Store Connect

---

## Build Configurations

### Debug (Development)
```bash
flutter run
```

### Profile (Performance testing)
```bash
flutter run --profile
```

### Release (Production)
```bash
flutter run --release
```

---

## Optimization Flags

### Android
```bash
flutter build apk --release \
  --target-platform android-arm,android-arm64,android-x64 \
  --split-per-abi
```

### iOS
Enable in Xcode:
- Strip Debug Symbols: Yes
- Optimization Level: -Os
- Bitcode: No (deprecated)

---

## Release Checklist

### Before Building
- [ ] Update version number
- [ ] Run `flutter test`
- [ ] Test on physical device
- [ ] Check all assets included
- [ ] Verify offline functionality

### After Building
- [ ] Test install on clean device
- [ ] Verify splash screen
- [ ] Check all screens load
- [ ] Test calculations
- [ ] Confirm map displays

### Distribution
- [ ] Write release notes
- [ ] Update screenshots
- [ ] Prepare description
- [ ] Set privacy policy URL
- [ ] Configure age rating
