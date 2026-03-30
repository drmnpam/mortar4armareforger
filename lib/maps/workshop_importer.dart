import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';
import 'heightmap.dart';
import 'grid_system.dart';

/// Map workshop import system
/// Handles importing custom maps from Arma Reforger workshop content
class MapWorkshopImporter {
  /// Import map from directory
  /// Expected structure:
  /// /maps/my_map/
  ///   ├── metadata.json
  ///   ├── map.png
  ///   └── heightmap.png (optional)
  static Future<MapImportResult> importFromDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return MapImportResult.error('Directory not found: $path');
      }
      
      // Check for metadata
      final metadataFile = File('$path/metadata.json');
      if (!await metadataFile.exists()) {
        return MapImportResult.error('metadata.json not found');
      }
      
      // Load metadata
      final metadataJson = await metadataFile.readAsString();
      final metadata = MapMetadataExtended.fromJson(
        jsonDecode(metadataJson) as Map<String, dynamic>
      );
      
      // Check for map image
      final mapImageFile = File('$path/${metadata.mapImage}');
      if (!await mapImageFile.exists()) {
        return MapImportResult.error('Map image not found: ${metadata.mapImage}');
      }
      
      // Check for optional heightmap
      Heightmap? heightmap;
      if (metadata.heightmap != null) {
        final hmFile = File('$path/${metadata.heightmap}');
        if (await hmFile.exists()) {
          // Would load heightmap from image here
          // For now, mark as available
        }
      }
      
      // Copy to app storage
      final appDir = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${appDir.path}/maps/${metadata.name}');
      await mapsDir.create(recursive: true);
      
      // Copy files
      await mapImageFile.copy('${mapsDir.path}/${metadata.mapImage}');
      await metadataFile.copy('${mapsDir.path}/metadata.json');
      
      return MapImportResult.success(
        metadata: metadata,
        path: mapsDir.path,
        heightmap: heightmap,
      );
      
    } catch (e) {
      return MapImportResult.error('Import failed: $e');
    }
  }
  
  /// Import from Arma Reforger workshop file
  /// Handles .aio files or extracted workshop content
  static Future<MapImportResult> importFromWorkshopFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return MapImportResult.error('File not found: $filePath');
      }
      
      // Check file extension
      final ext = filePath.split('.').last.toLowerCase();
      
      switch (ext) {
        case 'json':
          // Direct metadata import
          return _importFromJson(file);
        case 'png':
        case 'jpg':
        case 'jpeg':
          // Image-only import, create minimal metadata
          return _importFromImage(file);
        default:
          return MapImportResult.error('Unsupported file format: $ext');
      }
      
    } catch (e) {
      return MapImportResult.error('Import failed: $e');
    }
  }
  
  static Future<MapImportResult> _importFromJson(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    
    final metadata = MapMetadataExtended.fromJson(json);
    
    return MapImportResult.success(
      metadata: metadata,
      path: file.parent.path,
    );
  }
  
  static Future<MapImportResult> _importFromImage(File file) async {
    // Create basic metadata from image
    final name = file.uri.pathSegments.last.split('.').first;
    
    final metadata = MapMetadataExtended(
      name: name,
      mapImage: file.uri.pathSegments.last,
      worldSize: 10240, // Default assumption
      gridSize: 100,
      pixelsPerMeter: 1.0,
    );
    
    return MapImportResult.success(
      metadata: metadata,
      path: file.parent.path,
    );
  }
  
  /// Scan directory for multiple maps
  static Future<List<MapImportResult>> scanForMaps(String directory) async {
    final results = <MapImportResult>[];
    final dir = Directory(directory);
    
    if (!await dir.exists()) return results;
    
    await for (final entity in dir.list()) {
      if (entity is Directory) {
        final result = await importFromDirectory(entity.path);
        results.add(result);
      }
    }
    
    return results;
  }
  
  /// Validate map structure
  static Future<bool> validateMap(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return false;
    
    final metadataFile = File('$path/metadata.json');
    if (!await metadataFile.exists()) return false;
    
    try {
      final content = await metadataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final metadata = MapMetadataExtended.fromJson(json);
      
      final mapFile = File('$path/${metadata.mapImage}');
      return await mapFile.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Get metadata without importing
  static Future<MapMetadataExtended?> peekMetadata(String path) async {
    try {
      final file = File('$path/metadata.json');
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      return MapMetadataExtended.fromJson(
        jsonDecode(content) as Map<String, dynamic>
      );
    } catch (e) {
      return null;
    }
  }
}

/// Import result
class MapImportResult {
  final bool success;
  final String? error;
  final MapMetadataExtended? metadata;
  final String? path;
  final Heightmap? heightmap;
  
  const MapImportResult._({
    required this.success,
    this.error,
    this.metadata,
    this.path,
    this.heightmap,
  });
  
  factory MapImportResult.success({
    required MapMetadataExtended metadata,
    required String path,
    Heightmap? heightmap,
  }) {
    return MapImportResult._(
      success: true,
      metadata: metadata,
      path: path,
      heightmap: heightmap,
    );
  }
  
  factory MapImportResult.error(String message) {
    return MapImportResult._(
      success: false,
      error: message,
    );
  }
  
  bool get hasHeightmap => heightmap != null;
}

/// Extended map metadata for workshop imports
class MapMetadataExtended {
  final String name;
  final String mapImage;
  final double worldSize;
  final double gridSize;
  final double pixelsPerMeter;
  final String? description;
  final double? minX;
  final double? minY;
  final double? maxX;
  final double? maxY;
  final String? heightmap;
  final String? author;
  final String? version;
  final String? workshopId;
  final String? sourceUrl;
  final List<String>? tags;
  final Map<String, dynamic>? customData;
  
  MapMetadataExtended({
    required this.name,
    required this.mapImage,
    required this.worldSize,
    required this.gridSize,
    required this.pixelsPerMeter,
    this.description,
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
    this.heightmap,
    this.author,
    this.version,
    this.workshopId,
    this.sourceUrl,
    this.tags,
    this.customData,
  });
  
  factory MapMetadataExtended.fromJson(Map<String, dynamic> json) {
    return MapMetadataExtended(
      name: json['name'] as String,
      mapImage: json['image'] as String,
      worldSize: (json['worldSize'] as num).toDouble(),
      gridSize: (json['gridSize'] as num).toDouble(),
      pixelsPerMeter: (json['pixelsPerMeter'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      minX: (json['minX'] as num?)?.toDouble(),
      minY: (json['minY'] as num?)?.toDouble(),
      maxX: (json['maxX'] as num?)?.toDouble(),
      maxY: (json['maxY'] as num?)?.toDouble(),
      heightmap: json['heightmap'] as String?,
      author: json['author'] as String?,
      version: json['version'] as String?,
      workshopId: json['workshopId'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'image': mapImage,
    'worldSize': worldSize,
    'gridSize': gridSize,
    'pixelsPerMeter': pixelsPerMeter,
    'description': description,
    'minX': minX,
    'minY': minY,
    'maxX': maxX,
    'maxY': maxY,
    'heightmap': heightmap,
    'author': author,
    'version': version,
    'workshopId': workshopId,
    'sourceUrl': sourceUrl,
    'tags': tags,
    'customData': customData,
  };
}

/// Batch import results
class BatchImportResult {
  final List<MapImportResult> successful;
  final List<MapImportResult> failed;
  
  BatchImportResult({
    required this.successful,
    required this.failed,
  });
  
  int get total => successful.length + failed.length;
  int get successCount => successful.length;
  int get failCount => failed.length;
  
  bool get allSuccessful => failed.isEmpty;
  bool get hasFailures => failed.isNotEmpty;
}
