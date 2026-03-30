import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/models.dart';

/// Weapon ballistic tables loader and manager
class WeaponBallisticTables {
  static final Map<String, WeaponBallisticTable> _tables = {};
  static final Set<String> _customWeapons = {};
  static bool _initialized = false;

  /// Initialize with default tables
  static Future<void> initialize() async {
    if (_initialized) return;

    // Load built-in tables
    await _loadBuiltInTables();

    _initialized = true;
  }

  /// Load built-in ballistic tables from assets
  static Future<void> _loadBuiltInTables() async {
    final builtInTables = [
      // Mortars from data_pack
      'assets/data_pack/tables/2b14.json',
      'assets/data_pack/tables/m224.json',
      'assets/data_pack/tables/m252.json',
      // Artillery and angle tables from ballistics
      'assets/ballistics/m107.json',
      'assets/ballistics/2s1.json',
      'assets/ballistics/d30.json',
    ];

    for (final path in builtInTables) {
      try {
        final jsonString = await rootBundle.loadString(path);
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final table = WeaponBallisticTable.fromJson(json);
        _tables[table.weapon] = table;
      } catch (e) {
        // Table not found or invalid, skip
      }
    }
  }

  /// Get table for a weapon
  static WeaponBallisticTable? getTable(String weapon) {
    if (!_initialized) {
      // Return table if already loaded, otherwise null
      return _tables[weapon];
    }
    return _tables[weapon];
  }

  /// Get all available weapons
  static List<String> get availableWeapons => _tables.keys.toList()..sort();

  /// Get weapons by type
  static List<String> getWeaponsByType(WeaponType type) {
    return _tables.values
        .where((t) => t.type == type)
        .map((t) => t.weapon)
        .toList()
      ..sort();
  }

  /// Check if weapon is custom
  static bool isCustomWeapon(String weapon) => _customWeapons.contains(weapon);

  /// Add custom table from JSON string
  static Future<bool> importTable(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final table = WeaponBallisticTable.fromJson(json);

      // Validate table has data
      if (table.charges.isEmpty && (table.data?.isEmpty ?? true)) {
        return false;
      }

      _tables[table.weapon] = table;
      _customWeapons.add(table.weapon);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add custom table from file
  static Future<bool> importTableFromFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      return importTable(jsonString);
    } catch (e) {
      return false;
    }
  }

  /// Export table to JSON string
  static String? exportTable(String weapon) {
    final table = _tables[weapon];
    if (table == null) return null;

    final json = table.toJson();
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Remove custom table
  static void removeCustomTable(String weapon) {
    if (_customWeapons.contains(weapon)) {
      _tables.remove(weapon);
      _customWeapons.remove(weapon);
    }
  }

  /// Get interpolated firing solution
  /// Returns elevation (mils), time of flight, etc.
  static Map<String, double>? getFiringSolution(
    String weapon,
    double range,
    String charge,
  ) {
    final table = _tables[weapon];
    if (table == null) return null;

    final row = table.interpolate(range, charge);
    if (row == null) return null;

    return {
      'elevation': row.elevation ?? 0,
      'angle': row.angle ?? 0,
      'timeOfFlight': row.timeOfFlight ?? 0,
      'fuze': row.fuzeSetting ?? 0,
      'range': row.range,
    };
  }

  /// For angle tables - get angle for range
  static double? getAngle(String weapon, double range) {
    final table = _tables[weapon];
    if (table == null || table.type != WeaponType.angleTable) return null;

    final data = table.data;
    if (data == null || data.isEmpty) return null;

    // Find bounding rows
    WeaponBallisticRow? lower;
    WeaponBallisticRow? upper;

    for (int i = 0; i < data.length; i++) {
      if (data[i].range <= range) lower = data[i];
      if (data[i].range >= range && upper == null) upper = data[i];
    }

    if (lower == null) return data.first.angle;
    if (upper == null || lower.range == range) return lower.angle;
    if (upper.range == range) return upper.angle;

    // Interpolate
    final t = (range - lower.range) / (upper.range - lower.range);
    final angle = lower.angle! + t * (upper.angle! - lower.angle!);
    return angle;
  }

  /// Clear all custom tables
  static void clearCustomTables() {
    for (final weapon in _customWeapons.toList()) {
      _tables.remove(weapon);
    }
    _customWeapons.clear();
  }

  /// Get all custom tables for persistence
  static List<Map<String, dynamic>> exportCustomTables() {
    return _customWeapons
        .map((w) => _tables[w]?.toJson())
        .where((j) => j != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Import multiple custom tables (for persistence restore)
  static void importCustomTables(List<Map<String, dynamic>> tables) {
    for (final json in tables) {
      try {
        final table = WeaponBallisticTable.fromJson(json);
        _tables[table.weapon] = table;
        _customWeapons.add(table.weapon);
      } catch (_) {
        // Skip invalid tables
      }
    }
  }

  /// Select best charge for range (artillery tables)
  static String? selectCharge(String weapon, double range) {
    final table = _tables[weapon];
    if (table == null) return null;

    // Find charge that can reach this range with lowest elevation
    String? bestCharge;
    double? bestElevation;

    for (final entry in table.charges.entries) {
      final rows = entry.value;
      if (rows.isEmpty) continue;

      final minRange = rows.first.range;
      final maxRange = rows.last.range;

      if (range >= minRange && range <= maxRange * 1.05) {
        final row = table.interpolate(range, entry.key);
        final elevation = row?.elevation;
        if (elevation != null) {
          if (bestElevation == null || elevation < bestElevation) {
            bestElevation = elevation;
            bestCharge = entry.key;
          }
        }
      }
    }

    // If no charge can reach, use max charge
    if (bestCharge == null && table.charges.isNotEmpty) {
      final maxCharge = table.charges.keys
          .map((k) => int.tryParse(k) ?? 0)
          .reduce((a, b) => a > b ? a : b);
      bestCharge = maxCharge.toString();
    }

    return bestCharge;
  }

  /// Get table info for display
  static Map<String, dynamic>? getWeaponInfo(String weapon) {
    final table = _tables[weapon];
    if (table == null) return null;

    return {
      'weapon': table.weapon,
      'type': table.type.displayName,
      'description': table.description,
      'charges': table.availableCharges,
      'trajectories': table.trajectories,
      'minRange': table.minRange,
      'maxRange': table.maxRange,
      'isCustom': _customWeapons.contains(weapon),
    };
  }
}
