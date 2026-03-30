part of 'map_cubit.dart';

class MapState extends Equatable {
  final List<String> availableMaps;
  final String? selectedMap;
  final MapMetadata? currentMetadata;
  final String? mapImagePath;
  final List<MapMarker> markers;
  final bool isLoading;
  final String? error;
  
  final double zoomLevel;
  final double panX;
  final double panY;
  
  final bool showGrid;
  final bool showDistanceLine;
  
  // Legacy calibration (kept for compatibility)
  final double calibrationOffsetX;
  final double calibrationOffsetY;
  final double calibrationScaleX;
  final double calibrationScaleY;
  
  // New automatic calibration
  final MapCalibration? calibration;
  final CalibrationMode calibrationMode;
  final bool isCalibrating;
  final int? calibrationStep; // 0 = point A, 1 = point B, 2 = adjust, null = done
  final Position? calibPointA;
  final Position? calibPointB;
  final bool isDraggingCalibration; // true when finger is down
  final Offset? dragPosition; // current finger position for magnifier
  
  // Weapon selection
  final String selectedWeapon;
  final String? selectedCharge;
  final String? selectedTrajectory;
  final List<String> availableWeapons;
  final FiringSolution? solution;
  final bool hasMortar;
  final bool hasTarget;
  final double? metersPerPixel;
  
  const MapState({
    required this.availableMaps,
    this.selectedMap,
    this.currentMetadata,
    this.mapImagePath,
    required this.markers,
    required this.isLoading,
    this.error,
    required this.zoomLevel,
    required this.panX,
    required this.panY,
    required this.showGrid,
    required this.showDistanceLine,
    required this.calibrationOffsetX,
    required this.calibrationOffsetY,
    required this.calibrationScaleX,
    required this.calibrationScaleY,
    this.calibration,
    required this.calibrationMode,
    required this.isCalibrating,
    this.calibrationStep,
    this.calibPointA,
    this.calibPointB,
    this.isDraggingCalibration = false,
    this.dragPosition,
    required this.selectedWeapon,
    this.selectedCharge,
    this.selectedTrajectory,
    required this.availableWeapons,
    this.solution,
    required this.hasMortar,
    required this.hasTarget,
    this.metersPerPixel,
  });
  
  factory MapState.initial() {
    return const MapState(
      availableMaps: [],
      selectedMap: null,
      currentMetadata: null,
      mapImagePath: null,
      markers: [],
      isLoading: false,
      error: null,
      zoomLevel: 1.0,
      panX: 0,
      panY: 0,
      showGrid: true,
      showDistanceLine: true,
      calibrationOffsetX: 0,
      calibrationOffsetY: 0,
      calibrationScaleX: 1,
      calibrationScaleY: 1,
      calibration: null,
      calibrationMode: CalibrationMode.automatic,
      isCalibrating: false,
      calibrationStep: null,
      calibPointA: null,
      calibPointB: null,
      isDraggingCalibration: false,
      dragPosition: null,
      selectedWeapon: 'M252',
      selectedCharge: null,
      selectedTrajectory: null,
      availableWeapons: [],
      solution: null,
      hasMortar: false,
      hasTarget: false,
      metersPerPixel: null,
    );
  }
  
  MapState copyWith({
    List<String>? availableMaps,
    String? selectedMap,
    MapMetadata? currentMetadata,
    String? mapImagePath,
    List<MapMarker>? markers,
    bool? isLoading,
    String? error,
    double? zoomLevel,
    double? panX,
    double? panY,
    bool? showGrid,
    bool? showDistanceLine,
    double? calibrationOffsetX,
    double? calibrationOffsetY,
    double? calibrationScaleX,
    double? calibrationScaleY,
    MapCalibration? calibration,
    CalibrationMode? calibrationMode,
    bool? isCalibrating,
    int? calibrationStep,
    Position? calibPointA,
    Position? calibPointB,
    bool? isDraggingCalibration,
    Offset? dragPosition,
    String? selectedWeapon,
    String? selectedCharge,
    String? selectedTrajectory,
    List<String>? availableWeapons,
    FiringSolution? solution,
    bool? hasMortar,
    bool? hasTarget,
    double? metersPerPixel,
    bool clearError = false,
    bool clearSolution = false,
    bool clearCalibPoints = false,
  }) {
    return MapState(
      availableMaps: availableMaps ?? this.availableMaps,
      selectedMap: selectedMap ?? this.selectedMap,
      currentMetadata: currentMetadata ?? this.currentMetadata,
      mapImagePath: mapImagePath ?? this.mapImagePath,
      markers: markers ?? this.markers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      showGrid: showGrid ?? this.showGrid,
      showDistanceLine: showDistanceLine ?? this.showDistanceLine,
      calibrationOffsetX: calibrationOffsetX ?? this.calibrationOffsetX,
      calibrationOffsetY: calibrationOffsetY ?? this.calibrationOffsetY,
      calibrationScaleX: calibrationScaleX ?? this.calibrationScaleX,
      calibrationScaleY: calibrationScaleY ?? this.calibrationScaleY,
      calibration: calibration ?? this.calibration,
      calibrationMode: calibrationMode ?? this.calibrationMode,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      calibrationStep: calibrationStep ?? this.calibrationStep,
      calibPointA: clearCalibPoints ? null : calibPointA ?? this.calibPointA,
      calibPointB: clearCalibPoints ? null : calibPointB ?? this.calibPointB,
      isDraggingCalibration: isDraggingCalibration ?? this.isDraggingCalibration,
      dragPosition: dragPosition ?? this.dragPosition,
      selectedWeapon: selectedWeapon ?? this.selectedWeapon,
      selectedCharge: selectedCharge ?? this.selectedCharge,
      selectedTrajectory: selectedTrajectory ?? this.selectedTrajectory,
      availableWeapons: availableWeapons ?? this.availableWeapons,
      solution: clearSolution ? null : solution ?? this.solution,
      hasMortar: hasMortar ?? this.hasMortar,
      hasTarget: hasTarget ?? this.hasTarget,
      metersPerPixel: metersPerPixel ?? this.metersPerPixel,
    );
  }
  
  @override
  List<Object?> get props => [
    availableMaps,
    selectedMap,
    currentMetadata,
    mapImagePath,
    markers,
    isLoading,
    error,
    zoomLevel,
    panX,
    panY,
    showGrid,
    showDistanceLine,
    calibrationOffsetX,
    calibrationOffsetY,
    calibrationScaleX,
    calibrationScaleY,
    calibration,
    calibrationMode,
    isCalibrating,
    calibrationStep,
    calibPointA,
    calibPointB,
    isDraggingCalibration,
    dragPosition,
    selectedWeapon,
    selectedCharge,
    selectedTrajectory,
    availableWeapons,
    solution,
    hasMortar,
    hasTarget,
    metersPerPixel,
  ];
}
