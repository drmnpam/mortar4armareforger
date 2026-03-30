import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';
import '../../app/theme/app_theme.dart';
import '../../ballistics/ballistics.dart';
import '../../maps/maps.dart';
import '../../ballistics/weapon_tables.dart';
import '../../storage/storage.dart';
import '../../weapons/weapon_registry.dart';

part 'map_state.dart';

// Simple file logger for debugging crashes
class _CrashLogger {
  static final _CrashLogger _instance = _CrashLogger._internal();
  factory _CrashLogger() => _instance;
  _CrashLogger._internal();

  File? _logFile;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/crash_log.txt');
      await log('=== Logger initialized ===');
    } catch (e) {
      debugPrint('Failed to init logger: $e');
    }
  }

  Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[$timestamp] $message\n';
    debugPrint(line);
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString(line, mode: FileMode.append);
      } catch (e) {
        debugPrint('Failed to write log: $e');
      }
    }
  }
}

final _logger = _CrashLogger();

class MapCubit extends Cubit<MapState> {
  final StorageService _storage;
  final MarkerManager _markerManager = MarkerManager();

  MapCubit({required StorageService storageService})
      : _storage = storageService,
        super(MapState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _logger.init();
    await _logger.log('Starting initialization...');
    try {
      emit(state.copyWith(isLoading: true, clearError: true));
      await _logger.log('Emitted loading state');

      await MapLoader.initialize();
      await _logger.log('MapLoader initialized');
      
      await _storage.initialize();
      await _logger.log('Storage initialized');
      
      // Initialize weapon tables
      await WeaponBallisticTables.initialize();
      await _logger.log('Weapon tables initialized');
      
      // Load custom weapons from storage
      final customWeapons = _storage.getCustomWeapons();
      if (customWeapons.isNotEmpty) {
        WeaponBallisticTables.importCustomTables(customWeapons);
      }
      
      final customMaps = _storage.getCustomMaps();
      if (customMaps.isNotEmpty) {
        MapLoader.registerCustomMaps(customMaps);
      }
      final maps = List<String>.from(MapLoader.availableMaps);
      final weapons = WeaponBallisticTables.availableWeapons;

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
        availableWeapons: weapons,
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
    } catch (e, stackTrace) {
      await _logger.log('INIT ERROR: $e');
      await _logger.log('Stack: $stackTrace');
      emit(state.copyWith(
        isLoading: false,
        error: 'Init error: $e',
      ));
    }
  }

  /// Load a map
  Future<void> loadMap(String mapName) async {
    await _logger.log('loadMap called: $mapName');
    try {
      emit(state.copyWith(
        isLoading: true,
        clearError: true,
      ));
      await _logger.log('Loading state emitted');

      var resolvedMapName = mapName;
      MapMetadata? metadata = MapLoader.getMetadata(resolvedMapName);
      await _logger.log('Got metadata: ${metadata != null}');

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
        await _logger.log('ERROR: No metadata found');
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to load map: $mapName',
        ));
        return;
      }

      await _logger.log('Metadata OK: ${metadata.name}, imageWidth=${metadata.imageWidth}, imageHeight=${metadata.imageHeight}');

      final imagePath = MapLoader.getMapImagePath(resolvedMapName);
      await _logger.log('Image path: $imagePath');

      // Load calibration for this map BEFORE emitting ready state
      final modeJson = _storage.getCalibrationMode();
      final calibrationMode = CalibrationModeExtension.fromJson(modeJson ?? 'automatic');
      
      MapCalibration? calibration;
      final calibJson = _storage.loadMapCalibration(resolvedMapName);
      if (calibJson != null) {
        calibration = MapCalibration.fromJson(calibJson);
      }

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

      // Calculate metersPerPixel from metadata
      // Formula: metersPerPixel = worldWidthMeters / imageWidthPixels
      double? metersPerPixel;
      if (calibration != null && calibration.metersPerPixel > 0) {
        metersPerPixel = calibration.metersPerPixel;
      } else if (metadata.imageWidth > 0 && metadata.worldSize > 0) {
        metersPerPixel = metadata.worldSize / metadata.imageWidth;
      }

      emit(state.copyWith(
        selectedMap: resolvedMapName,
        currentMetadata: metadata,
        mapImagePath: imagePath,
        calibration: calibration,
        calibrationMode: calibrationMode,
        metersPerPixel: metersPerPixel,
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
      await _logger.log('Map loaded successfully: $resolvedMapName');
    } catch (e, stackTrace) {
      await _logger.log('LOADMAP ERROR: $e');
      await _logger.log('Stack: $stackTrace');
      emit(state.copyWith(
        isLoading: false,
        error: 'LoadMap error: $e',
      ));
    }
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
    emit(state.copyWith(selectedWeapon: type));
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
    bool persist = true,
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
    if (persist) {
      _saveState();
    }
  }

  /// Reset calibration to default.
  void resetCalibration({bool persist = true}) {
    emit(state.copyWith(
      calibrationOffsetX: 0,
      calibrationOffsetY: 0,
      calibrationScaleX: 1,
      calibrationScaleY: 1,
    ));
    if (persist) {
      _saveState();
    }
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
    final imageDimensions = await _resolveImageDimensions(imagePath);
    final pixelsPerMeter = 1.0;
    final metadata = MapMetadata(
      name: safeName,
      description: 'Custom user map',
      worldSize: worldSize,
      gridSize: gridSize,
      pixelsPerMeter: pixelsPerMeter,
      origin: [0, 0],
      heightmapPath: null,
      mapImage: 'map.png',
      imageWidth: imageDimensions.width.round(),
      imageHeight: imageDimensions.height.round(),
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
        mortarType: state.selectedWeapon,
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

  /// Get available mortar types (as strings for backward compatibility)
  List<String> get availableMortars => BallisticTables.availableMortars;

  /// Get available weapons as Weapon objects
  List<Weapon> get availableWeapons => allWeapons;

  /// Convert screen coordinates to world coordinates
  Position? screenToWorld(
      double screenX, double screenY, double imageWidth, double imageHeight) {
    final metadata = state.currentMetadata;
    if (metadata == null) return null;

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
      x: normalizedX * metadata.worldSize,
      y: (1 - normalizedY) * metadata.worldHeight,
    );
  }

  /// Convert world coordinates to screen coordinates
  ({double x, double y})? worldToScreen(
      Position position, double imageWidth, double imageHeight) {
    final metadata = state.currentMetadata;
    if (metadata == null) return null;

    final normalizedX = state.calibrationOffsetX +
        state.calibrationScaleX * (position.x / metadata.worldSize);
    final normalizedY = state.calibrationOffsetY +
        state.calibrationScaleY * (1 - (position.y / metadata.worldHeight));

    // Account for zoom and pan
    return (
      x: normalizedX * imageWidth * state.zoomLevel + state.panX,
      y: normalizedY * imageHeight * state.zoomLevel + state.panY,
    );
  }

  Future<({double width, double height})> _resolveImageDimensions(
      String imagePath) async {
    try {
      Uint8List bytes;
      if (imagePath.startsWith('assets/')) {
        final data = await rootBundle.load(imagePath);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(imagePath);
        if (!await file.exists()) {
          return (width: 4096.0, height: 4096.0);
        }
        bytes = await file.readAsBytes();
      }

      final decoded = await _decodeImage(bytes);
      return (
        width: decoded.width.toDouble(),
        height: decoded.height.toDouble(),
      );
    } catch (_) {
      return (width: 4096.0, height: 4096.0);
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  /// Get distance between mortar and target
  double? get distance {
    if (!_markerManager.hasValidSolution) return null;
    return _markerManager.distance;
  }

  // ============ NEW CALIBRATION SYSTEM (Drag-based with magnifier) ============
  
  // Track which point is being dragged in adjust mode (step 2)
  bool _draggingCalibPointIsA = true;

  /// Start calibration mode
  void startCalibration() {
    emit(state.copyWith(
      isCalibrating: true,
      calibrationStep: 0,
      clearCalibPoints: true,
    ));
  }

  /// Cancel calibration mode
  void cancelCalibration() {
    emit(state.copyWith(
      isCalibrating: false,
      calibrationStep: null,
      isDraggingCalibration: false,
      dragPosition: null,
      clearCalibPoints: true,
    ));
  }

  /// Place point A (step 0) or point B (step 1) via simple tap
  void placeCalibrationPoint(Position worldPosition) {
    final currentStep = state.calibrationStep;
    debugPrint('TAP: placeCalibrationPoint at step=$currentStep, world=$worldPosition');
    
    if (currentStep == 0) {
      emit(state.copyWith(
        calibPointA: worldPosition,
        calibrationStep: 1,
      ));
    } else if (currentStep == 1) {
      emit(state.copyWith(
        calibPointB: worldPosition,
        calibrationStep: 2,
      ));
    }
  }

  /// Start dragging for adjustment mode (step 2 only) - detect which point
  void calibrationAdjustStart(Offset contentPosition, double zoomLevel) {
    final pointA = state.calibPointA;
    final pointB = state.calibPointB;
    final metadata = state.currentMetadata;
    if (pointA == null || pointB == null || metadata == null) {
      debugPrint('DRAG ADJUST: Cannot start - A=$pointA, B=$pointB, meta=$metadata');
      return;
    }

    // contentPosition is in content coordinates (0..mapWidth) from GestureDetector inside InteractiveViewer
    // _worldToScreenUnzoomed also returns content coordinates
    debugPrint('DRAG ADJUST: contentPosition=$contentPosition, zoom=$zoomLevel');
    debugPrint('DRAG ADJUST: pointA world=$pointA, pointB world=$pointB');

    // Convert world positions to content coordinates
    final aScreen = _worldToScreenUnzoomed(pointA, metadata);
    final bScreen = _worldToScreenUnzoomed(pointB, metadata);

    debugPrint('DRAG ADJUST: aScreen=$aScreen, bScreen=$bScreen');

    // Determine which point is closer to touch
    final distA = (contentPosition - aScreen).distance;
    final distB = (contentPosition - bScreen).distance;
    
    debugPrint('DRAG ADJUST: distA=$distA, distB=$distB');
    
    _draggingCalibPointIsA = distA <= distB;

    debugPrint('DRAG ADJUST: Start dragging point ${_draggingCalibPointIsA ? "A" : "B"} at content=$contentPosition');
    emit(state.copyWith(
      isDraggingCalibration: true,
      dragPosition: contentPosition,
    ));
  }

  /// Convert world to screen coordinates (unzoomed - content space)
  Offset _worldToScreenUnzoomed(Position world, MapMetadata metadata) {
    final x = (world.x / metadata.worldSize) * metadata.imageWidth;
    final y = (1 - world.y / metadata.worldHeight) * metadata.imageHeight;
    return Offset(x, y);
  }

  /// Update drag in adjust mode - move the selected point
  void calibrationAdjustUpdate(Offset contentPosition, double zoomLevel) {
    if (!state.isDraggingCalibration) return;

    final metadata = state.currentMetadata;
    if (metadata == null) return;

    // contentPosition is in content coordinates (0..mapWidth)
    // Convert directly to world position
    final worldPos = _contentToWorld(contentPosition, metadata);

    emit(state.copyWith(
      dragPosition: contentPosition,
      calibPointA: _draggingCalibPointIsA ? worldPos : state.calibPointA,
      calibPointB: _draggingCalibPointIsA ? state.calibPointB : worldPos,
    ));
  }

  /// Convert content coordinates to world position (without zoom)
  Position _contentToWorld(Offset content, MapMetadata metadata) {
    final x = (content.dx / metadata.imageWidth) * metadata.worldSize;
    final y = (1 - content.dy / metadata.imageHeight) * metadata.worldHeight;
    return Position(x: x, y: y);
  }

  /// End adjustment drag
  void calibrationAdjustEnd() {
    debugPrint('DRAG ADJUST: End dragging point ${_draggingCalibPointIsA ? "A" : "B"}');
    emit(state.copyWith(
      isDraggingCalibration: false,
      dragPosition: null,
    ));
  }

  Offset _worldToScreen(Position world, MapMetadata metadata, double zoom) {
    final x = (world.x / metadata.worldSize) * metadata.imageWidth * zoom;
    final y = (1 - world.y / metadata.worldHeight) * metadata.imageHeight * zoom;
    return Offset(x, y);
  }

  Position _screenToWorld(Offset screen, MapMetadata metadata, double zoom) {
    final x = (screen.dx / zoom / metadata.imageWidth) * metadata.worldSize;
    final y = (1 - screen.dy / zoom / metadata.imageHeight) * metadata.worldHeight;
    return Position(x: x, y: y);
  }

  /// Calculate and apply calibration from the two points
  void applyCalibration() {
    final pointA = state.calibPointA;
    final pointB = state.calibPointB;
    
    if (pointA == null || pointB == null) return;

    final metadata = state.currentMetadata;
    if (metadata == null) return;

    // Calculate pixel distance between points in image coordinates
    final normAX = pointA.x / metadata.worldSize;
    final normAY = 1 - (pointA.y / metadata.worldHeight);
    final normBX = pointB.x / metadata.worldSize;
    final normBY = 1 - (pointB.y / metadata.worldHeight);

    final pixelDx = (normBX - normAX) * metadata.imageWidth;
    final pixelDy = (normBY - normAY) * metadata.imageHeight;
    final pixelDistance = math.sqrt(pixelDx * pixelDx + pixelDy * pixelDy);

    if (pixelDistance <= 0) {
      emit(state.copyWith(error: 'Invalid reference line'));
      return;
    }

    // Calculate scale: how many world meters per image pixel
    // User drew 100m in the real world, which corresponds to pixelDistance on image
    final metersPerPixel = 100.0 / pixelDistance;
    
    // Grid cell size in meters (e.g., 100m)
    final gridSizeMeters = metadata.gridSize;
    
    // Calculate scale factors: 
    // scaleX = worldSize / (imageWidth * metersPerPixel * (worldSize/gridSize))
    // Simplified: we want scale such that grid lines appear at correct intervals
    final scaleX = (pixelDistance / metadata.imageWidth) * (metadata.worldSize / 100.0);
    final scaleY = (pixelDistance / metadata.imageHeight) * (metadata.worldHeight / 100.0);

    // Calculate offsets to align point A to grid
    // offset = normalizedPos - (normalizedPos * scale) modulo grid interval
    final gridIntervalX = gridSizeMeters / metadata.worldSize;
    final gridIntervalY = gridSizeMeters / metadata.worldHeight;
    
    // Offset aligns the reference point to the nearest grid intersection
    final offsetX = normAX - (normAX * scaleX) % gridIntervalX;
    final offsetY = normAY - (normAY * scaleY) % gridIntervalY;

    // Create calibration
    final calib = MapCalibration.fromReferenceLine(
      pixelDistance: pixelDistance,
      referenceMeters: 100.0,
      refPointAX: normAX,
      refPointAY: normAY,
      refPointBX: normBX,
      refPointBY: normBY,
      gridSizeMeters: gridSizeMeters,
    );

    emit(state.copyWith(
      calibration: calib,
      calibrationOffsetX: offsetX,
      calibrationOffsetY: offsetY,
      calibrationScaleX: scaleX,
      calibrationScaleY: scaleY,
      calibrationMode: CalibrationMode.automatic,
      isCalibrating: false,
      calibrationStep: null,
      isDraggingCalibration: false,
      dragPosition: null,
      clearError: true,
    ));

    saveCalibration();
  }

  /// Reset calibration to defaults (for new calibration flow)
  void resetCalibrationNew() {
    emit(state.copyWith(
      calibrationOffsetX: 0,
      calibrationOffsetY: 0,
      calibrationScaleX: 1,
      calibrationScaleY: 1,
      calibration: null,
      calibrationStep: 0,
      clearCalibPoints: true,
    ));
  }

  /// Move mortar to new position
  void moveMortar(Position position) {
    _markerManager.moveMarker(MarkerType.mortar, position);
    _updateState();
    _calculateIfReady();
    _saveState();
  }
  void setCalibrationMode(CalibrationMode mode) {
    emit(state.copyWith(calibrationMode: mode));
    _storage.setCalibrationMode(mode.jsonValue);
  }

  /// Save calibration to storage
  void saveCalibration() {
    if (state.selectedMap != null && state.calibration != null) {
      _storage.saveMapCalibration(state.selectedMap!, state.calibration!.toJson());
    }
  }

  /// Load calibration for current map
  void _loadCalibration() {
    if (state.selectedMap == null) return;

    final modeJson = _storage.getCalibrationMode();
    final mode = CalibrationModeExtension.fromJson(modeJson ?? 'automatic');

    final calibJson = _storage.loadMapCalibration(state.selectedMap!);
    if (calibJson != null) {
      final calib = MapCalibration.fromJson(calibJson);
      emit(state.copyWith(
        calibration: calib,
        calibrationMode: mode,
      ));
    } else {
      emit(state.copyWith(calibrationMode: mode));
    }
  }

  // ============ WEAPON SELECTION ============

  /// Set selected weapon
  void setWeapon(String weapon) {
    final table = WeaponBallisticTables.getTable(weapon);
    String? charge;
    String? trajectory;

    if (table != null) {
      // Auto-select first charge if available
      if (table.availableCharges.isNotEmpty) {
        charge = table.availableCharges.first;
      }
      // Auto-select default trajectory if available
      if (table.trajectories != null && table.trajectories!.isNotEmpty) {
        trajectory = table.defaultTrajectory ?? table.trajectories!.first;
      }
    }

    emit(state.copyWith(
      selectedWeapon: weapon,
      selectedCharge: charge,
      selectedTrajectory: trajectory,
      clearSolution: true,
    ));

    _calculateIfReady();
  }

  /// Set selected charge (for artillery tables)
  void setCharge(String charge) {
    emit(state.copyWith(selectedCharge: charge));
    _calculateIfReady();
  }

  /// Set selected trajectory (for angle tables)
  void setTrajectory(String trajectory) {
    emit(state.copyWith(selectedTrajectory: trajectory));
    _calculateIfReady();
  }

  /// Refresh available weapons list
  void refreshWeapons() {
    final weapons = WeaponBallisticTables.availableWeapons;
    emit(state.copyWith(availableWeapons: weapons));
  }

  /// Import weapon table from file
  Future<bool> importWeaponTable(String filePath) async {
    final success = await WeaponBallisticTables.importTableFromFile(filePath);
    if (success) {
      refreshWeapons();
      await _storage.setCustomWeapons(WeaponBallisticTables.exportCustomTables());
    }
    return success;
  }

  /// Export weapon table to file
  Future<String?> exportWeaponTable(String weapon, String directory) async {
    final json = WeaponBallisticTables.exportTable(weapon);
    if (json == null) return null;

    final fileName = '${weapon.toLowerCase().replaceAll(' ', '_')}.json';
    final filePath = '$directory/$fileName';

    try {
      final file = File(filePath);
      await file.writeAsString(json);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Remove custom weapon table
  void removeWeaponTable(String weapon) {
    WeaponBallisticTables.removeCustomTable(weapon);
    refreshWeapons();
  }
}

