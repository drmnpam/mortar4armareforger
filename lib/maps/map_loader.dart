import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import '../models/models.dart';

/// Map loader for loading offline map files
class MapLoader {
  static final Map<String, MapMetadata> _cachedMetadata = {};
  static final Map<String, String> _customMapImagePaths = {};
  static final List<String> _availableMaps = [];

  /// Initialize and discover available maps
  static Future<void> initialize() async {
    if (_availableMaps.isNotEmpty) return;

    // Try to load from assets
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifest);

      // Find all metadata.json files in maps folder
      for (final key in manifestMap.keys) {
        if (key.startsWith('assets/maps/') && key.endsWith('metadata.json')) {
          final mapName = key.split('/')[2]; // maps/mapname/metadata.json
          if (!_availableMaps.contains(mapName)) {
            _availableMaps.add(mapName);
          }
        }
      }
    } catch (e) {
      // Fallback: load built-in maps
      _loadBuiltInMaps();
    }

    _ensureBuiltInMapsPresent();

    // Load metadata for each map
    final snapshot = List<String>.from(_availableMaps);
    for (final mapName in snapshot) {
      final loaded = await _loadMetadata(mapName);
      if (loaded == null && !_customMapImagePaths.containsKey(mapName)) {
        _availableMaps.remove(mapName);
      }
    }

    if (_availableMaps.isEmpty) {
      _loadBuiltInMaps();
      for (final mapName in _availableMaps) {
        await _loadMetadata(mapName);
      }
    }
  }

  /// Get list of available maps
  static List<String> get availableMaps => List.unmodifiable(_availableMaps);

  /// Get metadata for a specific map
  static MapMetadata? getMetadata(String mapName) {
    return _cachedMetadata[mapName];
  }

  /// Load map metadata from file
  static Future<MapMetadata?> _loadMetadata(String mapName) async {
    if (_cachedMetadata.containsKey(mapName)) {
      return _cachedMetadata[mapName];
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/maps/$mapName/metadata.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = MapMetadata.fromJson(json);

      _cachedMetadata[mapName] = metadata;
      return metadata;
    } catch (e) {
      return null;
    }
  }

  /// Load map image asset path
  static String getMapImagePath(String mapName) {
    final customPath = _customMapImagePaths[mapName];
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    final metadata = _cachedMetadata[mapName];
    if (metadata != null) {
      return 'assets/maps/$mapName/${metadata.image}';
    }
    return 'assets/maps/$mapName/map.png';
  }

  /// Add a custom map from file system (for workshop maps)
  static Future<bool> addCustomMap(String path) async {
    try {
      final metadataFile = File('$path/metadata.json');
      if (!await metadataFile.exists()) {
        return false;
      }

      final jsonString = await metadataFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = MapMetadata.fromJson(json);

      final mapName = metadata.name;
      _cachedMetadata[mapName] = metadata;
      _customMapImagePaths[mapName] = '$path/${metadata.image}';

      if (!_availableMaps.contains(mapName)) {
        _availableMaps.add(mapName);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a map from cache
  static void removeMap(String mapName) {
    _cachedMetadata.remove(mapName);
    _customMapImagePaths.remove(mapName);
    _availableMaps.remove(mapName);
  }

  /// Register runtime custom map (for user-provided image + name).
  static void registerCustomMap({
    required String mapName,
    required MapMetadata metadata,
    required String imagePath,
  }) {
    _cachedMetadata[mapName] = metadata;
    _customMapImagePaths[mapName] = imagePath;
    if (!_availableMaps.contains(mapName)) {
      _availableMaps.add(mapName);
    }
  }

  /// Register multiple custom maps from persisted data.
  static void registerCustomMaps(List<Map<String, dynamic>> maps) {
    for (final item in maps) {
      try {
        final metadataRaw = item['metadata'];
        final imagePath = item['imagePath'] as String?;
        if (metadataRaw is! Map || imagePath == null || imagePath.isEmpty) {
          continue;
        }
        final metadata =
            MapMetadata.fromJson(Map<String, dynamic>.from(metadataRaw));
        registerCustomMap(
          mapName: metadata.name,
          metadata: metadata,
          imagePath: imagePath,
        );
      } catch (_) {
        // Ignore malformed entries.
      }
    }
  }

  /// Serialize currently registered custom maps for persistence.
  static List<Map<String, dynamic>> exportCustomMaps() {
    final result = <Map<String, dynamic>>[];
    for (final entry in _customMapImagePaths.entries) {
      final metadata = _cachedMetadata[entry.key];
      if (metadata == null) {
        continue;
      }
      result.add({
        'metadata': metadata.toJson(),
        'imagePath': entry.value,
      });
    }
    return result;
  }

  /// Built-in maps for when no assets are available
  static void _loadBuiltInMaps() {
    _ensureBuiltInMapsPresent();
  }

  static void _ensureBuiltInMapsPresent() {
    const builtIns = ['everon', 'arland', 'kolguev'];
    for (final mapName in builtIns) {
      if (!_availableMaps.contains(mapName)) {
        _availableMaps.add(mapName);
      }
    }
  }

  /// Create default metadata for a map
  static MapMetadata createDefaultMetadata(String mapName, double worldSize) {
    return MapMetadata(
      name: mapName,
      image: 'map.png',
      worldSize: worldSize,
      gridSize: 100,
      pixelsPerMeter: 0.5,
    );
  }

  /// Validate map structure
  static bool validateMapStructure(MapMetadata metadata) {
    // Check required fields
    if (metadata.name.isEmpty) return false;
    if (metadata.worldSize <= 0) return false;
    if (metadata.gridSize <= 0) return false;
    if (metadata.pixelsPerMeter <= 0) return false;

    // Check reasonable bounds
    if (metadata.worldSize > 100000) return false; // > 100km
    if (metadata.pixelsPerMeter > 10) return false; // Too detailed

    return true;
  }

  /// Get map dimensions in pixels
  static ({double width, double height}) getMapDimensions(
      MapMetadata metadata) {
    final size = metadata.worldSize * metadata.pixelsPerMeter;
    return (width: size, height: size);
  }

  /// Clear cache
  static void clearCache() {
    _cachedMetadata.clear();
    _customMapImagePaths.clear();
    _availableMaps.clear();
  }
}
