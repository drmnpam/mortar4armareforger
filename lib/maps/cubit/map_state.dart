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
  
  final String selectedMortar;
  final FiringSolution? solution;
  final bool hasMortar;
  final bool hasTarget;
  
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
    required this.selectedMortar,
    this.solution,
    required this.hasMortar,
    required this.hasTarget,
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
      selectedMortar: 'M252',
      solution: null,
      hasMortar: false,
      hasTarget: false,
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
    String? selectedMortar,
    FiringSolution? solution,
    bool? hasMortar,
    bool? hasTarget,
    bool clearError = false,
    bool clearSolution = false,
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
      selectedMortar: selectedMortar ?? this.selectedMortar,
      solution: clearSolution ? null : solution ?? this.solution,
      hasMortar: hasMortar ?? this.hasMortar,
      hasTarget: hasTarget ?? this.hasTarget,
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
    selectedMortar,
    solution,
    hasMortar,
    hasTarget,
  ];
}
