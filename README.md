# Mortar Calculator for Arma Reforger

A cross-platform ballistic calculator for mortar fire missions in Arma Reforger. Built with Flutter for iOS and Android.

## Features

### Calculator Modes
- **Numeric Calculator** - Manual coordinate entry for mortar and target positions
- **Map Calculator** - Visual map interface with draggable markers
- **Ballistic Tables** - Complete firing tables for all supported mortars

### Supported Mortars
- **M252** - 81mm US mortar (Charges 0-3, ranges 100-3600m)
- **2B14 Podnos** - 82mm Russian mortar (Charges 0-3, ranges 100-3600m)
- **M224** - 60mm US mortar (Charges 0-3, ranges 100-3200m)

### Key Features
- Offline operation - no internet required
- Height-adjusted firing solutions
- Auto charge selection
- Save and manage target lists
- Export/import data
- Military-grade dark theme
- Large, readable displays for field use

## Installation

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK
- Android Studio / Xcode (for device deployment)

### Setup
```bash
# Clone repository
git clone <repo-url>
cd mortar_calculator

# Install dependencies
flutter pub get

# Run on device
flutter run
```

### Build Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Usage

### Basic Calculator
1. Select mortar type (M252, 2B14, M224)
2. Enter mortar coordinates (X, Y, altitude)
3. Enter target coordinates (X, Y, altitude)
4. Tap "CALCULATE"
5. Read firing solution:
   - **AZIMUTH** - Direction in mils (0-6400)
   - **ELEVATION** - Barrel elevation in mils
   - **CHARGE** - Propellant charge number
   - **DISTANCE** - Range to target
   - **TOF** - Time of flight

### Map Calculator
1. Select map from dropdown
2. Place mortar marker (green)
3. Place target marker (red)
4. Firing solution auto-calculates
5. Grid overlay and distance line available

### Adding Custom Maps
1. Create folder in `assets/maps/[mapname]/`
2. Add map image as `map.png`
3. Create `metadata.json`:
```json
{
  "name": "MyMap",
  "image": "map.png",
  "worldSize": 10240,
  "gridSize": 100,
  "pixelsPerMeter": 0.5
}
```

## Ballistic Formulas

### Distance
```
distance = sqrt((x2 - x1)^2 + (y2 - y1)^2)
```

### Azimuth (mils)
```
azimuth = atan2(dx, dy) * 1018.5916
if azimuth < 0: azimuth += 6400
```

### Height Correction
```
site = (targetAltitude - mortarAltitude) / distance
correctedElevation = elevation + (site * 1000)
```

### Interpolation
```
y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
```

## Architecture

```
lib/
├── main.dart                 # App entry point
├── app/
│   ├── app.dart             # App widget with BLoC providers
│   ├── routes/              # GoRouter configuration
│   └── theme/               # Military dark theme
├── ballistics/              # Ballistics engine
│   ├── formulas.dart        # Mathematical formulas
│   ├── tables.dart          # Ballistic tables loader
│   ├── interpolation.dart   # Table interpolation
│   ├── solver.dart          # Main solver
│   └── cubit/               # State management
├── maps/                    # Map system
│   ├── map_loader.dart      # Map loading
│   ├── coordinate_converter.dart
│   ├── markers.dart         # Map markers
│   └── cubit/               # Map state management
├── models/                  # Data models
│   ├── position.dart
│   ├── firing_solution.dart
│   ├── ballistic_row.dart
│   └── ...
├── storage/                 # Offline storage
│   └── services/
│       └── storage_service.dart  # Hive storage
└── ui/                      # User interface
    ├── screens/             # All screens
    └── widgets/             # Reusable widgets
```

## Roadmap

### Phase 1 (Complete)
- [x] Ballistic engine
- [x] Numeric calculator
- [x] Map viewer
- [x] Ballistic tables
- [x] Basic storage

### Phase 2 (Planned)
- [ ] Fire missions (multiple targets)
- [ ] Shot correction tracking
- [ ] Wind adjustments
- [ ] Team sharing (local network)
- [ ] Impact radius visualization

### Phase 3 (Future)
- [ ] Workshop map integration
- [ ] Import real Arma maps
- [ ] Moving target prediction
- [ ] Voice announcements

## License

MIT License - See LICENSE file

## Credits

- Arma Reforger by Bohemia Interactive
- Flutter framework by Google

---

**Note**: This is a fan-made tool for Arma Reforger. Not affiliated with Bohemia Interactive.
