import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import '../models/models.dart';

/// Map loader for loading offline map files
class MapLoader {
  static final Map<String, MapMetadata> _cachedMetadata = {};
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
    
    // Load metadata for each map
    for (final mapName in _availableMaps) {
      await _loadMetadata(mapName);
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
      final jsonString = await rootBundle.loadString(
        'assets/maps/$mapName/metadata.json'
      );
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
    _availableMaps.remove(mapName);
  }
  
  /// Built-in maps for when no assets are available
  static void _loadBuiltInMaps() {
    _availableMaps.addAll([
      'everon',
      'arland',
      'kolguev',
    ]);
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
  static ({double width, double height}) getMapDimensions(MapMetadata metadata) {
    final size = metadata.worldSize * metadata.pixelsPerMeter;
    return (width: size, height: size);
  }
  
  /// Clear cache
  static void clearCache() {
    _cachedMetadata.clear();
    _availableMaps.clear();
  }
}
