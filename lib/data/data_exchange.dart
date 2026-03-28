import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Data export/import manager
class DataExchangeManager {
  static final DataExchangeManager _instance = DataExchangeManager._internal();
  factory DataExchangeManager() => _instance;
  DataExchangeManager._internal();

  /// Export map pack as ZIP
  Future<String> exportMapPack(String mapName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapDir = Directory('${appDir.path}/maps/$mapName');
    
    if (!await mapDir.exists()) {
      throw Exception('Map not found: $mapName');
    }

    final archive = Archive();
    
    // Add all files from map directory
    await for (final entity in mapDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(mapDir.path.length + 1);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    // Encode to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    // Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/${mapName}_map_pack.zip');
    await zipFile.writeAsBytes(zipBytes!);

    return zipFile.path;
  }

  /// Import map pack from ZIP
  Future<bool> importMapPack(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final appDir = await getApplicationDocumentsDirectory();
      
      // Extract files
      String? mapName;
      for (final file in archive) {
        if (file.isFile) {
          final parts = file.name.split('/');
          if (parts.isEmpty) continue;
          
          mapName ??= parts.first;
          final path = '${appDir.path}/maps/${file.name}';
          final outputFile = File(path);
          await outputFile.parent.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      return mapName != null;
    } catch (e) {
      debugPrint('Failed to import map pack: $e');
      return false;
    }
  }

  /// Export ballistic table
  Future<String> exportBallisticTable(String mortar) async {
    final appDir = await getApplicationDocumentsDirectory();
    final tableFile = File('${appDir.path}/tables/${mortar.toLowerCase()}.json');
    
    if (!await tableFile.exists()) {
      throw Exception('Table not found: $mortar');
    }

    return tableFile.path;
  }

  /// Import ballistic table
  Future<bool> importBallisticTable(String jsonPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tablesDir = Directory('${appDir.path}/tables');
      await tablesDir.create(recursive: true);

      // Copy file to tables directory
      final sourceFile = File(jsonPath);
      final fileName = jsonPath.split('/').last;
      final targetFile = File('${tablesDir.path}/$fileName');
      
      await sourceFile.copy(targetFile.path);
      return true;
    } catch (e) {
      debugPrint('Failed to import ballistic table: $e');
      return false;
    }
  }

  /// Export fire mission
  Future<String> exportFireMission(Map<String, dynamic> mission) async {
    final jsonString = jsonEncode(mission);
    
    final tempDir = await getTemporaryDirectory();
    final fileName = 'fire_mission_${mission['name']}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    
    await file.writeAsString(jsonString);
    return file.path;
  }

  /// Import fire mission
  Future<Map<String, dynamic>?> importFireMission(String jsonPath) async {
    try {
      final file = File(jsonPath);
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to import fire mission: $e');
      return null;
    }
  }

  /// Export targets list
  Future<String> exportTargets(List<Map<String, dynamic>> targets) async {
    final exportData = {
      'format': 'targets_v1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'targets': targets,
    };
    
    final jsonString = jsonEncode(exportData);
    
    final tempDir = await getTemporaryDirectory();
    final fileName = 'targets_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    
    await file.writeAsString(jsonString);
    return file.path;
  }

  /// Import targets
  Future<List<Map<String, dynamic>>> importTargets(String jsonPath) async {
    try {
      final file = File(jsonPath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return (data['targets'] as List<dynamic>)
          .map((t) => t as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Failed to import targets: $e');
      return [];
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath, String subject) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
    );
  }

  /// Export firing solution as text
  String exportFiringSolution(
    Map<String, dynamic> solution,
    Map<String, dynamic> mortar,
    Map<String, dynamic> target, {
    ExportFormat format = ExportFormat.military,
  }) {
    switch (format) {
      case ExportFormat.military:
        return _toMilitaryFormat(solution, mortar, target);
      case ExportFormat.compact:
        return _toCompactFormat(solution);
      case ExportFormat.json:
        return jsonEncode({
          'solution': solution,
          'mortar': mortar,
          'target': target,
          'exported_at': DateTime.now().toIso8601String(),
        });
    }
  }

  String _toMilitaryFormat(
    Map<String, dynamic> solution,
    Map<String, dynamic> mortar,
    Map<String, dynamic> target,
  ) {
    return '''FIRING SOLUTION
MORTAR: ${solution['mortar_type']}
AZIMUTH: ${solution['azimuth'].toStringAsFixed(0).padLeft(4, '0')}
ELEVATION: ${solution['elevation'].toStringAsFixed(1)}
CHARGE: ${solution['charge']}
DISTANCE: ${solution['distance'].toStringAsFixed(0)}m
TOF: ${solution['time_of_flight'].toStringAsFixed(1)}s

MORTAR POS: ${mortar['x'].toStringAsFixed(0)} ${mortar['y'].toStringAsFixed(0)}
TARGET POS: ${target['x'].toStringAsFixed(0)} ${target['y'].toStringAsFixed(0)}

${solution['correction'] ?? ''}'''.trim();
  }

  String _toCompactFormat(Map<String, dynamic> solution) {
    final az = solution['azimuth'].toStringAsFixed(0).padLeft(4, '0');
    final el = solution['elevation'].toStringAsFixed(0);
    final ch = solution['charge'].toString();
    return 'AZ:$az EL:$el CH:$ch';
  }
}

enum ExportFormat {
  military,
  compact,
  json,
}
