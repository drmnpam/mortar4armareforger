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
    emit(state.copyWith(isLoading: true, clearError: true));

    await MapLoader.initialize();
    await _storage.initialize();
    final customMaps = _storage.getCustomMaps();
    if (customMaps.isNotEmpty) {
      MapLoader.registerCustomMaps(customMaps);
    }
    final maps = List<String>.from(MapLoader.availableMaps);

    // Load preferred map
    final preferred = _storage.getPreferredMap();
    String? initialMap;
    if (preferred != null) {
      for (final map in maps) {
        if (map.toLowerCase() == preferred.toLowerCase()) {
          initialMap = map;
          break;
        }
      }
    }

    if (initialMap == null && maps.isNotEmpty) {
      initialMap = maps.firstWhere(
        (map) => MapLoader.getMetadata(map) != null,
        orElse: () => maps.first,
      );
    }

    emit(state.copyWith(
      availableMaps: maps,
      selectedMap: initialMap,
      isLoading: false,
    ));

    if (initialMap != null) {
      await loadMap(initialMap);
      return;
    }

    emit(state.copyWith(
      isLoading: false,
      error: 'No maps available',
    ));
  }

  /// Load a map
  Future<void> loadMap(String mapName) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
    ));

    var resolvedMapName = mapName;
    MapMetadata? metadata = MapLoader.getMetadata(resolvedMapName);

    if (metadata == null) {
      for (final candidate in state.availableMaps) {
        final candidateMetadata = MapLoader.getMetadata(candidate);
        if (candidateMetadata != null) {
          resolvedMapName = candidate;
          metadata = candidateMetadata;
          break;
        }
      }
    }

    if (metadata == null) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load map: $mapName',
      ));
      return;
    }

    final imagePath = MapLoader.getMapImagePath(resolvedMapName);

    // Try to restore saved markers
    final savedState = _storage.loadMapState(resolvedMapName);
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
      selectedMap: resolvedMapName,
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

    await _storage.setPreferredMap(resolvedMapName);
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
  void setZoom(double zoom, {bool persist = false}) {
    emit(state.copyWith(zoomLevel: zoom.clamp(0.4, 8.0).toDouble()));
    if (persist) {
      _saveState();
    }
  }

  /// Update map pan offset
  void setPan(double x, double y, {bool persist = false}) {
    emit(state.copyWith(
      panX: x,
      panY: y,
    ));
    if (persist) {
      _saveState();
    }
  }

  /// Update zoom and pan together.
  void setView({
    required double zoom,
    required double panX,
    required double panY,
    bool persist = false,
  }) {
    emit(state.copyWith(
      zoomLevel: zoom.clamp(0.4, 8.0).toDouble(),
      panX: panX,
      panY: panY,
    ));
    if (persist) {
      _saveState();
    }
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

  /// Register user-provided map image with custom name.
  Future<bool> addCustomMap({
    required String name,
    required String imagePath,
    double worldSize = 10240,
    double gridSize = 100,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || imagePath.trim().isEmpty) {
      emit(state.copyWith(error: 'Map name and image are required'));
      return false;
    }

    final safeName = _uniqueMapName(trimmedName);
    final metadata = MapMetadata(
      name: safeName,
      image: imagePath.split(RegExp(r'[\\/]')).last,
      worldSize: worldSize,
      gridSize: gridSize,
      pixelsPerMeter: 1.0,
      description: 'Custom user map',
    );

    MapLoader.registerCustomMap(
      mapName: safeName,
      metadata: metadata,
      imagePath: imagePath,
    );

    await _storage.setCustomMaps(MapLoader.exportCustomMaps());
    emit(state.copyWith(
      availableMaps: MapLoader.availableMaps,
      clearError: true,
    ));
    await loadMap(safeName);
    return true;
  }

  String _uniqueMapName(String baseName) {
    final existing =
        MapLoader.availableMaps.map((e) => e.toLowerCase()).toSet();
    if (!existing.contains(baseName.toLowerCase())) {
      return baseName;
    }
    var i = 2;
    while (existing.contains('$baseName $i'.toLowerCase())) {
      i++;
    }
    return '$baseName $i';
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
  Position? screenToWorld(
      double screenX, double screenY, double imageWidth, double imageHeight) {
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
  ({double x, double y})? worldToScreen(
      Position position, double imageWidth, double imageHeight) {
    if (state.currentMetadata == null) return null;

    final normalizedX = state.calibrationOffsetX +
        state.calibrationScaleX *
            (position.x / state.currentMetadata!.worldSize);
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
