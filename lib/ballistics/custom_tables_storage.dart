import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CustomBallisticTablesStorage {
  static const _tablesDirName = 'ballistic_tables';

  static Future<Directory> _tablesDir() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_tablesDirName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String _slug(String value) {
    final normalized =
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
    return safe.isEmpty ? 'custom_mortar' : safe;
  }

  static List<Map<String, dynamic>> _normalizeDecoded(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    if (decoded is Map<String, dynamic>) {
      final mortars = decoded['mortars'];
      if (mortars is List) {
        return mortars
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }
      return [Map<String, dynamic>.from(decoded)];
    }
    return const [];
  }

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final directory = await _tablesDir();
    final tables = <Map<String, dynamic>>[];

    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        final raw = await entity.readAsString();
        final decoded = jsonDecode(raw);
        tables.addAll(_normalizeDecoded(decoded));
      } catch (_) {
        // Ignore malformed files and continue.
      }
    }

    return tables;
  }

  static Future<void> saveTable(Map<String, dynamic> table) async {
    final mortar = (table['mortar'] ?? table['name'])?.toString().trim();
    if (mortar == null || mortar.isEmpty) {
      throw const FormatException('Custom table missing mortar name');
    }
    final directory = await _tablesDir();
    final file = File('${directory.path}/${_slug(mortar)}.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(table));
  }

  static Future<void> saveAll(List<Map<String, dynamic>> tables) async {
    final directory = await _tablesDir();

    await for (final entity in directory.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
        await entity.delete();
      }
    }

    for (final table in tables) {
      await saveTable(table);
    }
  }

  static Future<File> exportToFile({
    required String fileNamePrefix,
    required String jsonPayload,
  }) async {
    final directory = await _tablesDir();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${directory.path}/${_slug(fileNamePrefix)}_$timestamp.json');
    await file.writeAsString(jsonPayload);
    return file;
  }
}
