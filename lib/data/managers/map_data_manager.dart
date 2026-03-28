import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';

/// Manages map data loading from assets and device storage
class MapDataManager {
  static final MapDataManager _instance = MapDataManager._internal();
  factory MapDataManager() => _instance;
  MapDataManager._internal();

  final List<MapData> _availableMaps = [];
  MapData? _activeMap;
  HeightmapData? _activeHeightmap;

  List<MapData> get availableMaps => List.unmodifiable(_availableMaps);
  MapData? get activeMap => _activeMap;
  HeightmapData? get activeHeightmap => _activeHeightmap;

  /// Initialize and load all maps
  Future<void> initialize() async {
    await _loadDefaultMaps();
    await _loadUserMaps();
  }

  /// Load default maps from assets
  Future<void> _loadDefaultMaps() async {
    final defaultMaps = ['everon', 'arland', 'kolguev'];
    
    for (final mapName in defaultMaps) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/data_pack/maps/$mapName/metadata.json'
        );
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final mapData = MapData.fromJson(json);
        
        if (!_availableMaps.any((m) => m.name == mapData.name)) {
          _availableMaps.add(mapData);
        }
      } catch (e) {
        debugPrint('Failed to load default map $mapName: $e');
      }
    }
  }

  /// Load user-imported maps from device storage
  Future<void> _loadUserMaps() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory('${appDir.path}/maps');
    
    if (!await mapsDir.exists()) return;

    await for (final entity in mapsDir.list()) {
      if (entity is Directory) {
        final metadataFile = File('${entity.path}/metadata.json');
        if (await metadataFile.exists()) {
          try {
            final jsonString = await metadataFile.readAsString();
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final mapData = MapData.fromJson(json);
            
            if (!_availableMaps.any((m) => m.name == mapData.name)) {
              _availableMaps.add(mapData);
            }
          } catch (e) {
            debugPrint('Failed to load user map ${entity.path}: $e');
          }
        }
      }
    }
  }

  /// Select active map
  Future<void> selectMap(String mapName) async {
    final map = _availableMaps.firstWhere(
      (m) => m.name == mapName,
      orElse: () => throw Exception('Map not found: $mapName'),
    );
    
    _activeMap = map;
    
    // Load heightmap if available
    if (map.hasHeightmap) {
      await _loadHeightmap(map);
    }
  }

  /// Load heightmap for active map
  Future<void> _loadHeightmap(MapData map) async {
    try {
      // Try device storage first
      final appDir = await getApplicationDocumentsDirectory();
      final heightmapPath = '${appDir.path}/maps/${map.name.toLowerCase()}/heightmap.png';
      final heightmapFile = File(heightmapPath);
      
      if (await heightmapFile.exists()) {
        // Load from device
        final bytes = await heightmapFile.readAsBytes();
        _activeHeightmap = await _parseHeightmap(bytes, map);
      } else {
        // Try assets
        final byteData = await rootBundle.load(
          'assets/data_pack/maps/${map.name.toLowerCase()}/heightmap.png'
        );
        _activeHeightmap = await _parseHeightmap(byteData.buffer.asUint8List(), map);
      }
    } catch (e) {
      debugPrint('Failed to load heightmap for ${map.name}: $e');
      _activeHeightmap = null;
    }
  }

  /// Parse heightmap PNG to elevation data
  Future<HeightmapData> _parseHeightmap(List<int> bytes, MapData map) async {
    // This would use image processing library to parse PNG
    // For now, return placeholder
    return HeightmapData(
      width: (map.worldSizeM / map.heightmapResolutionM).round(),
      height: (map.worldSizeM / map.heightmapResolutionM).round(),
      worldSizeM: map.worldSizeM,
      minElevationM: map.elevationMinM,
      maxElevationM: map.elevationMaxM,
    );
  }

  /// Get elevation at world position
  double? getElevation(double x, double y) {
    if (_activeHeightmap == null) return null;
    return _activeHeightmap!.getElevation(x, y);
  }

  /// Import map from ZIP file
  Future<bool> importMapPack(String zipPath) async {
    // Implementation for importing map pack ZIP
    // Extract to device storage/maps/
    return true;
  }

  /// Copy default assets to device storage on first run
  Future<void> copyDefaultsToDevice() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory('${appDir.path}/maps');
    
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }

    // Check if already copied
    final markerFile = File('${appDir.path}/.data_initialized');
    if (await markerFile.exists()) return;

    // Copy each default map
    final defaultMaps = ['everon', 'arland', 'kolguev'];
    
    for (final mapName in defaultMaps) {
      final targetDir = Directory('${appDir.path}/maps/$mapName');
      await targetDir.create(recursive: true);

      try {
        // Copy metadata
        final metadataData = await rootBundle.load(
          'assets/data_pack/maps/$mapName/metadata.json'
        );
        final metadataFile = File('${targetDir.path}/metadata.json');
        await metadataFile.writeAsBytes(metadataData.buffer.asUint8List());

        // Copy map image if exists
        try {
          final mapImageData = await rootBundle.load(
            'assets/data_pack/maps/$mapName/map.png'
          );
          final mapImageFile = File('${targetDir.path}/map.png');
          await mapImageFile.writeAsBytes(mapImageData.buffer.asUint8List());
        } catch (_) {
          // Map image might not exist in assets
        }
      } catch (e) {
        debugPrint('Failed to copy map $mapName: $e');
      }
    }

    // Create marker file
    await markerFile.writeAsString(DateTime.now().toIso8601String());
  }

  /// Get map image path
  Future<String?> getMapImagePath(String mapName) async {
    final appDir = await getApplicationDocumentsDirectory();
    
    // Check device storage first
    final devicePath = '${appDir.path}/maps/${mapName.toLowerCase()}/map.png';
    if (await File(devicePath).exists()) {
      return devicePath;
    }

    // Return asset path
    return 'assets/data_pack/maps/${mapName.toLowerCase()}/map.png';
  }
}

/// Map data model
class MapData {
  final String name;
  final String description;
  final String terrainType;
  final String biome;
  final double worldSizeM;
  final double gridSizeM;
  final double pixelsPerMeter;
  final List<double> origin;
  final Map<String, double> bounds;
  final double elevationMinM;
  final double elevationMaxM;
  final double waterLevelM;
  final double heightmapResolutionM;
  final String mapImageFile;
  final String? heightmapFile;
  final String? thumbnailFile;
  final Map<String, dynamic> metadata;
  final Map<String, bool> features;

  MapData({
    required this.name,
    required this.description,
    required this.terrainType,
    required this.biome,
    required this.worldSizeM,
    required this.gridSizeM,
    required this.pixelsPerMeter,
    required this.origin,
    required this.bounds,
    required this.elevationMinM,
    required this.elevationMaxM,
    required this.waterLevelM,
    required this.heightmapResolutionM,
    required this.mapImageFile,
    this.heightmapFile,
    this.thumbnailFile,
    required this.metadata,
    required this.features,
  });

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      name: json['name'] as String,
      description: json['description'] as String,
      terrainType: json['terrain_type'] as String,
      biome: json['biome'] as String,
      worldSizeM: (json['world_size_m'] as num).toDouble(),
      gridSizeM: (json['grid_size_m'] as num).toDouble(),
      pixelsPerMeter: (json['pixels_per_meter'] as num).toDouble(),
      origin: (json['origin'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      bounds: (json['bounds'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble())
      ),
      elevationMinM: (json['elevation']['min_m'] as num).toDouble(),
      elevationMaxM: (json['elevation']['max_m'] as num).toDouble(),
      waterLevelM: (json['elevation']['water_level_m'] as num).toDouble(),
      heightmapResolutionM: (json['elevation']['heightmap_resolution_m'] as num).toDouble(),
      mapImageFile: json['files']['map_image'] as String,
      heightmapFile: json['files']['heightmap'] as String?,
      thumbnailFile: json['files']['thumbnail'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>,
      features: (json['features'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as bool)
      ),
    );
  }

  bool get hasHeightmap => heightmapFile != null && features['has_heightmap'] == true;
  
  int get imageWidth => (worldSizeM * pixelsPerMeter).round();
  int get imageHeight => (worldSizeM * pixelsPerMeter).round();
}

/// Heightmap data model
class HeightmapData {
  final int width;
  final int height;
  final double worldSizeM;
  final double minElevationM;
  final double maxElevationM;
  final List<double>? _data;

  HeightmapData({
    required this.width,
    required this.height,
    required this.worldSizeM,
    required this.minElevationM,
    required this.maxElevationM,
    List<double>? data,
  }) : _data = data;

  /// Get elevation at world coordinates
  double? getElevation(double x, double y) {
    if (_data == null) return null;
    
    // Convert world to pixel
    final pixelX = ((x / worldSizeM) * width).clamp(0, width - 1).toInt();
    final pixelY = ((1 - y / worldSizeM) * height).clamp(0, height - 1).toInt();
    
    final index = pixelY * width + pixelX;
    if (index < 0 || index >= _data.length) return null;
    
    return _data[index];
  }

  /// Sample with bilinear interpolation
  double sampleBilinear(double x, double y) {
    if (_data == null) return 0;
    
    final scaleX = width / worldSizeM;
    final scaleY = height / worldSizeM;
    
    final fx = (x * scaleX).clamp(0, width - 1);
    final fy = ((worldSizeM - y) * scaleY).clamp(0, height - 1);
    
    final x0 = fx.floor().clamp(0, width - 2);
    final y0 = fy.floor().clamp(0, height - 2);
    final x1 = x0 + 1;
    final y1 = y0 + 1;
    
    final tx = fx - x0;
    final ty = fy - y0;
    
    final q00 = _getRaw(x0, y0);
    final q01 = _getRaw(x0, y1);
    final q10 = _getRaw(x1, y0);
    final q11 = _getRaw(x1, y1);
    
    return q00 * (1 - tx) * (1 - ty) +
           q10 * tx * (1 - ty) +
           q01 * (1 - tx) * ty +
           q11 * tx * ty;
  }

  double _getRaw(int x, int y) {
    if (_data == null) return 0;
    final index = y * width + x;
    if (index < 0 || index >= _data.length) return 0;
    return _data[index];
  }
}
