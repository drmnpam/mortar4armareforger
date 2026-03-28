# API Reference - Mortar Calculator

## Ballistics API

### RefactoredBallisticSolver

```dart
// Calculate firing solution
FiringSolution calculate({
  required Position mortarPosition,
  required Position targetPosition,
  required String mortarType,
  int? preferredCharge,
  bool autoSelectCharge = true,
})

// Calculate all charge options
List<FiringSolution> calculateAllOptions({
  required Position mortarPosition,
  required Position targetPosition,
  required String mortarType,
})
```

### DistanceCalculator

```dart
double calculateDistance(Position from, Position to)
double calculateDistance3D(Position from, Position to)
double calculateSlantRange(Position from, Position to, {double? elevation})
```

### AzimuthCalculator

```dart
double calculateAzimuth(Position from, Position to)
double normalize(double azimuthMils)
double calculateDifference(double azimuth1, double azimuth2)
double addOffset(double azimuth, double offset)
String format(double azimuthMils)
```

### ChargeSelector

```dart
int selectOptimalCharge(String mortarType, double distance)
int selectFlattestCharge(String mortarType, double distance)
bool canReach(String mortarType, int charge, double distance)
```

### HeightCorrector

```dart
HeightCorrectionResult calculate(
  double elevation,
  double timeOfFlight,
  double heightDifference,
  double groundDistance,
)
```

## Maps API

### GridCoordinateSystem

```dart
String worldToGrid(Position position)
Position gridToWorld(String gridReference)
({int col, int row}) worldToGridCell(Position position)
```

### CoordinateConverter

```dart
Position gridToMeters(String grid)
String metersToGrid(Position position)
Offset metersToPixels(Position position, Size imageSize, double worldSize)
Position pixelsToMeters(Offset pixel, Size imageSize, double worldSize)
```

### ImpactVisualizer

```dart
double calculateImpactRadius(double distance, int charge)
List<ImpactCircle> getImpactCircles(double distance, int charge)
bool isInImpactZone(Position point, Position impact, double distance, int charge)
```

### Heightmap

```dart
double getElevationAt(Position position)
double getElevationAtXY(double x, double y)
({double dx, double dy}) getGradientAt(Position position)
bool hasLineOfSight(Position from, Position to)
```

### WorkshopImporter

```dart
Future<MapImportResult> importFromDirectory(String path)
Future<MapImportResult> importFromWorkshopFile(String filePath)
Future<List<MapImportResult>> scanForMaps(String directory)
```

## Fire Mission API

### FireMissionManager

```dart
FireMission createMission({
  required String name,
  required Position mortarPosition,
  required String mortarType,
})

void addTarget(FireMissionTarget target)
void removeTarget(String targetId)
bool fireNext()
```

### ShotCorrector

```dart
ShotCorrectionResult applyCorrection({
  required FiringSolution originalSolution,
  required Position mortarPosition,
  required Position targetPosition,
  double? addMeters,
  double? dropMeters,
  double? leftMils,
  double? rightMils,
})

ShotCorrectionResult? parseObserverCall({
  required FiringSolution solution,
  required Position mortar,
  required Position target,
  required String call,
})
```

## Storage API

### StorageService

```dart
Future<void> saveTarget(SavedTarget target)
Future<List<SavedTarget>> getSavedTargets()
Future<void> deleteTarget(String id)

String getPreferredMortar()
Future<void> setPreferredMortar(String mortar)

Future<void> addToHistory(FiringSolution solution, Position mortar, Position target)
List<Map<String, dynamic>> getHistory()

Future<String> exportData()
Future<void> importData(String jsonData)
```

## Constants

```dart
// Azimuth
const double totalMils = 6400.0;
const double radiansToMils = 1018.5916;

// Impact zones
const double defaultKillRadius = 25.0;
const double defaultCasualtyRadius = 50.0;

// Height correction
const double defaultHeightCorrectionFactor = 1000.0;

// Elevation interpolation
const double elevationToRangeFactor = 0.5;
const double milsPerMeterRange = 2.0;
```
