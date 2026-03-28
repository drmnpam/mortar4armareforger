import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../maps/maps.dart';
import '../../ballistics/ballistics.dart';
import '../../storage/storage.dart';

part 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final StorageService _storage;
  final MarkerManager _markerManager = MarkerManager();
  
  MapCubit({required StorageService storageService})
    : _storage = storageService,
      super(MapState.initial()) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await MapLoader.initialize();
    final maps = MapLoader.availableMaps;
    
    // Load preferred map
    final preferred = _storage.getPreferredMap();
    final initialMap = preferred ?? (maps.isNotEmpty ? maps.first : null);
    
    emit(state.copyWith(
      availableMaps: maps,
      selectedMap: initialMap,
    ));
    
    if (initialMap != null) {
      await loadMap(initialMap);
    }
  }
  
  /// Load a map
  Future<void> loadMap(String mapName) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));
    
    final metadata = MapLoader.getMetadata(mapName);
    if (metadata == null) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load map: $mapName',
      ));
      return;
    }
    
    final imagePath = MapLoader.getMapImagePath(mapName);
    
    // Try to restore saved markers
    final savedState = _storage.loadMapState(mapName);
    double restoredZoom = 1.0;
    double restoredPanX = 0.0;
    double restoredPanY = 0.0;
    double restoredCalibrationOffsetX = 0.0;
    double restoredCalibrationOffsetY = 0.0;
    double restoredCalibrationScaleX = 1.0;
    double restoredCalibrationScaleY = 1.0;

    if (savedState != null && savedState['markers'] != null) {
      _markerManager.fromJson(savedState['markers'] as List<dynamic>);
      restoredZoom = (savedState['zoom'] as num?)?.toDouble() ?? restoredZoom;
      restoredPanX = (savedState['panX'] as num?)?.toDouble() ?? restoredPanX;
      restoredPanY = (savedState['panY'] as num?)?.toDouble() ?? restoredPanY;
      restoredCalibrationOffsetX =
          (savedState['calibrationOffsetX'] as num?)?.toDouble() ??
              restoredCalibrationOffsetX;
      restoredCalibrationOffsetY =
          (savedState['calibrationOffsetY'] as num?)?.toDouble() ??
              restoredCalibrationOffsetY;
      restoredCalibrationScaleX =
          (savedState['calibrationScaleX'] as num?)?.toDouble() ??
              restoredCalibrationScaleX;
      restoredCalibrationScaleY =
          (savedState['calibrationScaleY'] as num?)?.toDouble() ??
              restoredCalibrationScaleY;
    }
    
    // Load last mortar position if available
    final lastMortar = _storage.getLastMortarPosition();
    if (lastMortar != null && _markerManager.mortarMarker == null) {
      _markerManager.addMarker(MapMarker.mortar(lastMortar));
    }
    
    emit(state.copyWith(
      selectedMap: mapName,
      currentMetadata: metadata,
      mapImagePath: imagePath,
      isLoading: false,
      markers: List.from(_markerManager.markers),
      hasMortar: _markerManager.mortarMarker != null,
      hasTarget: _markerManager.targetMarker != null,
      zoomLevel: restoredZoom,
      panX: restoredPanX,
      panY: restoredPanY,
      calibrationOffsetX: restoredCalibrationOffsetX,
      calibrationOffsetY: restoredCalibrationOffsetY,
      calibrationScaleX: restoredCalibrationScaleX,
      calibrationScaleY: restoredCalibrationScaleY,
      clearError: true,
      clearSolution: true,
    ));
    
    await _storage.setPreferredMap(mapName);
  }
  
  /// Add mortar marker at position
  void addMortar(Position position) {
    _markerManager.addMarker(MapMarker.mortar(position));
    _saveState();
    _updateState();
    _calculateIfReady();
  }
  
  /// Add target marker at position
  void addTarget(Position position) {
    _markerManager.addMarker(MapMarker.target(position));
    _saveState();
    _updateState();
    _calculateIfReady();
  }
  
  /// Update marker position
  void updateMarker(String id, Position position) {
    _markerManager.updateMarkerPosition(id, position);
    _saveState();
    _updateState();
    _calculateIfReady();
  }
  
  /// Remove a marker
  void removeMarker(String id) {
    _markerManager.removeMarker(id);
    _saveState();
    _updateState();
    emit(state.copyWith(clearSolution: true));
  }
  
  /// Clear all markers
  void clearMarkers() {
    _markerManager.clear();
    _saveState();
    _updateState();
    emit(state.copyWith(
      clearSolution: true,
      clearError: true,
    ));
  }
  
  /// Update map zoom level
  void setZoom(double zoom) {
    emit(state.copyWith(zoomLevel: zoom));
  }
  
  /// Update map pan offset
  void setPan(double x, double y) {
    emit(state.copyWith(
      panX: x,
      panY: y,
    ));
  }
  
  /// Set mortar type for calculations
  void setMortarType(String type) {
    emit(state.copyWith(selectedMortar: type));
    _calculateIfReady();
  }
  
  /// Toggle grid overlay
  void toggleGrid() {
    emit(state.copyWith(showGrid: !state.showGrid));
  }
  
  /// Toggle distance line
  void toggleDistanceLine() {
    emit(state.copyWith(showDistanceLine: !state.showDistanceLine));
  }

  /// Set calibration values for map/grid alignment.
  /// Offset is normalized image shift (0.01 = 1%).
  /// Scale is normalized image stretch (1.0 = default).
  void setCalibration({
    required double offsetX,
    required double offsetY,
    required double scaleX,
    required double scaleY,
  }) {
    final clampedOffsetX = offsetX.clamp(-0.5, 0.5).toDouble();
    final clampedOffsetY = offsetY.clamp(-0.5, 0.5).toDouble();
    final clampedScaleX = scaleX.clamp(0.5, 1.5).toDouble();
    final clampedScaleY = scaleY.clamp(0.5, 1.5).toDouble();

    emit(state.copyWith(
      calibrationOffsetX: clampedOffsetX,
      calibrationOffsetY: clampedOffsetY,
      calibrationScaleX: clampedScaleX,
      calibrationScaleY: clampedScaleY,
    ));
    _saveState();
  }

  /// Reset calibration to default.
  void resetCalibration() {
    emit(state.copyWith(
      calibrationOffsetX: 0,
      calibrationOffsetY: 0,
      calibrationScaleX: 1,
      calibrationScaleY: 1,
    ));
    _saveState();
  }
  
  /// Save current state
  void _saveState() {
    if (state.selectedMap != null) {
      _storage.saveMapState(state.selectedMap!, {
        'markers': _markerManager.toJson(),
        'zoom': state.zoomLevel,
        'panX': state.panX,
        'panY': state.panY,
        'calibrationOffsetX': state.calibrationOffsetX,
        'calibrationOffsetY': state.calibrationOffsetY,
        'calibrationScaleX': state.calibrationScaleX,
        'calibrationScaleY': state.calibrationScaleY,
      });
    }
  }
  
  /// Update state from marker manager
  void _updateState() {
    emit(state.copyWith(
      markers: List.from(_markerManager.markers),
      hasMortar: _markerManager.mortarMarker != null,
      hasTarget: _markerManager.targetMarker != null,
    ));
  }
  
  /// Calculate firing solution if both markers present
  void _calculateIfReady() {
    if (!_markerManager.hasValidSolution) return;
    
    final mortar = _markerManager.mortarMarker!;
    final target = _markerManager.targetMarker!;
    
    try {
      final solution = BallisticSolver.calculate(
        mortarPosition: mortar.position,
        targetPosition: target.position,
        mortarType: state.selectedMortar,
      );
      
      // Update markers with solution
      mortar.updateSolution(solution);
      target.updateSolution(solution);
      
      emit(state.copyWith(
        solution: solution,
        clearError: true,
      ));
      
      // Save to history
      _storage.addToHistory(solution, mortar.position, target.position);
    } on BallisticException catch (e) {
      emit(state.copyWith(
        clearSolution: true,
        error: e.message,
      ));
    }
  }
  
  /// Get available mortar types
  List<String> get availableMortars => BallisticTables.availableMortars;
  
  /// Convert screen coordinates to world coordinates
  Position? screenToWorld(double screenX, double screenY, double imageWidth, double imageHeight) {
    if (state.currentMetadata == null) return null;
    
    // Account for zoom and pan
    final adjustedX = (screenX - state.panX) / state.zoomLevel / imageWidth;
    final adjustedY = (screenY - state.panY) / state.zoomLevel / imageHeight;

    final normalizedX =
        ((adjustedX - state.calibrationOffsetX) / state.calibrationScaleX)
            .clamp(0.0, 1.0);
    final normalizedY =
        ((adjustedY - state.calibrationOffsetY) / state.calibrationScaleY)
            .clamp(0.0, 1.0);

    return Position(
      x: normalizedX * state.currentMetadata!.worldSize,
      y: (1 - normalizedY) * state.currentMetadata!.worldSize,
    );
  }
  
  /// Convert world coordinates to screen coordinates
  ({double x, double y})? worldToScreen(Position position, double imageWidth, double imageHeight) {
    if (state.currentMetadata == null) return null;

    final normalizedX = state.calibrationOffsetX +
        state.calibrationScaleX * (position.x / state.currentMetadata!.worldSize);
    final normalizedY = state.calibrationOffsetY +
        state.calibrationScaleY *
            (1 - (position.y / state.currentMetadata!.worldSize));

    // Account for zoom and pan
    return (
      x: normalizedX * imageWidth * state.zoomLevel + state.panX,
      y: normalizedY * imageHeight * state.zoomLevel + state.panY,
    );
  }
  
  /// Get distance between mortar and target
  double? get distance {
    if (!_markerManager.hasValidSolution) return null;
    return _markerManager.distance;
  }
}
