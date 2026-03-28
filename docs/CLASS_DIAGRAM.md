# Ballistic Calculator - Class Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        BALLISTICS ENGINE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐         │
│  │ BallisticSolver      │──────│ RefactoredBallistic  │         │
│  │ - calculate()        │      │ Solver               │         │
│  │ - calculateAll()     │      │ - calculate()         │         │
│  └──────────────────────┘      │ - calculateAll()     │         │
│          │                      └──────────────────────┘         │
│          │                                                         │
│          ▼                                                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    CALCULATORS                              │  │
│  ├────────────────────────────────────────────────────────────┤  │
│  │                                                             │  │
│  │  ┌──────────────────┐      ┌──────────────────┐             │  │
│  │  │DistanceCalculator│      │AzimuthCalculator │             │  │
│  │  │- calculate()     │      │- calculate()     │             │  │
│  │  │- slantRange()    │      │- normalize()     │             │  │
│  │  └──────────────────┘      │- format()        │             │  │
│  │                            └──────────────────┘             │  │
│  │                                                             │  │
│  │  ┌──────────────────┐      ┌──────────────────┐             │  │
│  │  │ChargeSelector    │      │ElevationInterpolator            │  │
│  │  │- selectOptimal() │      │- interpolate()   │             │  │
│  │  │- selectFlattest()│      │- linearInterpolate│             │  │
│  │  │- canReach()      │      │- cosineInterpolate│             │  │
│  │  └──────────────────┘      └──────────────────┘             │  │
│  │                                                             │  │
│  │  ┌──────────────────┐      ┌──────────────────┐             │  │
│  │  │HeightCorrector   │      │TimeOfFlightCalculator           │  │
│  │  │- calculateSite() │      │- getTimeOfFlight()│             │  │
│  │  │- applyCorrection()│    │- calculate()     │             │  │
│  │  │- needsCorrection()│    └──────────────────┘             │  │
│  │  └──────────────────┘                                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐          │
│  │ ShotCorrector        │      │ FireMissionManager   │          │
│  │ - applyCorrection()  │      │ - createMission()    │          │
│  │ - parseObserverCall()│      │ - addTarget()        │          │
│  │ - estimateCorrection()│     │ - fireNext()         │          │
│  └──────────────────────┘      └──────────────────────┘          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         MAP SYSTEM                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐            │
│  │ GridCoordinateSystem │      │ CoordinateConverter  │            │
│  │ - worldToGrid()     │      │ - gridToMeters()     │            │
│  │ - gridToWorld()     │      │ - metersToPixels()   │            │
│  │ - getGridLabel()    │      │ - pixelsToGrid()     │            │
│  └──────────────────────┘      └──────────────────────┘            │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐            │
│  │ MapLoader           │      │ WorkshopImporter     │            │
│  │ - initialize()      │      │ - importDirectory()   │            │
│  │ - getMetadata()     │      │ - importWorkshopFile()│            │
│  │ - loadMap()         │      │ - validateMap()       │            │
│  └──────────────────────┘      └──────────────────────┘            │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐            │
│  │ Heightmap           │      │ ImpactVisualizer     │            │
│  │ - getElevation()    │      │ - calculateRadius()   │            │
│  │ - getGradient()     │      │ - getImpactCircles()  │            │
│  │ - hasLineOfSight()  │      │ - calculateCEP()      │            │
│  └──────────────────────┘      └──────────────────────┘            │
│                                                                   │
│  ┌──────────────────────┐                                          │
│  │ MarkerManager       │                                          │
│  │ - addMarker()       │                                          │
│  │ - updatePosition()  │                                          │
│  │ - hasValidSolution  │                                          │
│  └──────────────────────┘                                          │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        DATA MODELS                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────┐                                          │
│  │ Position            │                                          │
│  │ - x: double         │                                          │
│  │ - y: double         │                                          │
│  │ - altitude: double  │                                          │
│  └──────────────────────┘                                          │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐          │
│  │ FiringSolution      │      │ BallisticTable       │            │
│  │ - azimuth: double   │      │ - mortar: String     │            │
│  │ - elevation: double │      │ - charge: int        │            │
│  │ - charge: int       │      │ - table: List<Row>   │            │
│  │ - distance: double  │      │ - minRange: double   │            │
│  │ - timeOfFlight: dbl │      │ - maxRange: double   │            │
│  │ - correction: String│      └──────────────────────┘            │
│  └──────────────────────┘                                          │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐          │
│  │ FireMission         │      │ MapMetadata          │            │
│  │ - id: String        │      │ - name: String       │            │
│  │ - name: String      │      │ - worldSize: double  │            │
│  │ - targets: List     │      │ - gridSize: double   │            │
│  │ - status: Enum      │      │ - pixelsPerMeter: dbl│            │
│  │ - currentTarget: int│      └──────────────────────┘            │
│  └──────────────────────┘                                          │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐          │
│  │ MapMarker           │      │ SavedTarget          │            │
│  │ - id: String        │      │ - id: String         │            │
│  │ - type: Enum        │      │ - name: String       │            │
│  │ - position: Pos     │      │ - position: Pos      │            │
│  │ - solution: Sol     │      │ - solution: Sol      │            │
│  └──────────────────────┘      └──────────────────────┘            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          UI LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Screens:                                                         │
│  ├── MainScreen                                                   │
│  ├── NumericCalculatorScreen                                      │
│  ├── MapCalculatorScreen ──────── MarkerMap, ImpactPainter     │
│  ├── FireMissionScreen                                            │
│  ├── TablesScreen                                                 │
│  ├── SavedTargetsScreen                                           │
│  └── SettingsScreen                                               │
│                                                                   │
│  Widgets:                                                         │
│  ├── FiringSolutionCard                                           │
│  ├── CoordinateInput                                              │
│  ├── BallisticTableView                                           │
│  └── ImpactCircle (visual)                                        │
│                                                                   │
│  State Management:                                                │
│  ├── BallisticsCubit                                              │
│  ├── MapCubit                                                     │
│  └── FireMissionCubit                                             │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```
