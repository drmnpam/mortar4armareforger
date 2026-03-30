import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/models.dart';

/// Manages ballistic table data
class BallisticDataManager {
  static final BallisticDataManager _instance = BallisticDataManager._internal();
  factory BallisticDataManager() => _instance;
  BallisticDataManager._internal();

  final Map<String, BallisticTableData> _tables = {};
  String _activeMortar = 'M252';

  List<String> get availableMortars => _tables.keys.toList();
  String get activeMortar => _activeMortar;

  /// Initialize and load all tables
  Future<void> initialize() async {
    await _loadDefaultTables();
    await _loadUserTables();
  }

  /// Load default tables from assets
  Future<void> _loadDefaultTables() async {
    final defaultTables = ['m252', '2b14', 'm224'];
    
    for (final tableName in defaultTables) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/data_pack/tables/$tableName.json'
        );
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final table = BallisticTableData.fromJson(json);
        
        _tables[table.mortar] = table;
      } catch (e) {
        debugPrint('Failed to load ballistic table $tableName: $e');
      }
    }
  }

  /// Load user tables from device storage
  Future<void> _loadUserTables() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tablesDir = Directory('${appDir.path}/tables');
    
    if (!await tablesDir.exists()) return;

    await for (final entity in tablesDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final jsonString = await entity.readAsString();
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final table = BallisticTableData.fromJson(json);
          
          _tables[table.mortar] = table;
        } catch (e) {
          debugPrint('Failed to load user table ${entity.path}: $e');
        }
      }
    }
  }

  /// Select active mortar
  void selectMortar(String mortar) {
    if (_tables.containsKey(mortar)) {
      _activeMortar = mortar;
    } else {
      throw Exception('Mortar not found: $mortar');
    }
  }

  /// Get table for active or specified mortar
  BallisticTableData? getTable([String? mortar]) {
    return _tables[mortar ?? _activeMortar];
  }

  /// Get charge data for specific charge
  ChargeData? getChargeData(int charge, [String? mortar]) {
    final table = getTable(mortar);
    if (table == null) return null;
    
    try {
      return table.charges.firstWhere((c) => c.charge == charge);
    } catch (_) {
      return null;
    }
  }

  /// Get all charges for mortar
  List<ChargeData> getAllCharges([String? mortar]) {
    final table = getTable(mortar);
    return table?.charges ?? [];
  }

  /// Find optimal charge for distance
  int? findOptimalCharge(double distance, [String? mortar]) {
    final table = getTable(mortar);
    if (table == null) return null;

    // Find lowest charge that can reach this distance
    for (final charge in table.charges) {
      if (distance >= charge.minRangeM && distance <= charge.maxRangeM * 1.02) {
        return charge.charge;
      }
    }

    // Return highest charge if beyond max
    return table.charges.lastOrNull?.charge;
  }

  /// Validate all loaded tables
  List<String> validateTables() {
    final issues = <String>[];

    for (final entry in _tables.entries) {
      final mortar = entry.key;
      final table = entry.value;

      for (final charge in table.charges) {
        // Check ranges are sorted
        for (int i = 1; i < charge.table.length; i++) {
          if (charge.table[i].rangeM <= charge.table[i - 1].rangeM) {
            issues.add('$mortar CH${charge.charge}: Range not sorted at row $i');
          }
        }

        // Check elevation decreases with range
        int decreasingCount = 0;
        for (int i = 1; i < charge.table.length; i++) {
          if (charge.table[i].elevationMil < charge.table[i - 1].elevationMil) {
            decreasingCount++;
          }
        }
        if (decreasingCount < charge.table.length ~/ 2) {
          issues.add('$mortar CH${charge.charge}: Elevation trend unusual');
        }

        // Check TOF increases with range
        for (int i = 1; i < charge.table.length; i++) {
          if (charge.table[i].tofS < charge.table[i - 1].tofS) {
            issues.add('$mortar CH${charge.charge}: TOF decreases at row $i');
          }
        }

        // Check min/max range matches table
        if (charge.table.first.rangeM != charge.minRangeM) {
          issues.add('$mortar CH${charge.charge}: minRange mismatch');
        }
        if (charge.table.last.rangeM != charge.maxRangeM) {
          issues.add('$mortar CH${charge.charge}: maxRange mismatch');
        }
      }
    }

    return issues;
  }

  /// Interpolate elevation from table
  BallisticRowData? interpolate(int charge, double distance, [String? mortar]) {
    final chargeData = getChargeData(charge, mortar);
    if (chargeData == null) return null;

    // Find surrounding rows
    BallisticRowData? lower;
    BallisticRowData? upper;

    for (final row in chargeData.table) {
      if (row.rangeM <= distance) lower = row;
      if (row.rangeM >= distance && upper == null) upper = row;
    }

    if (lower == null && upper == null) return null;
    if (lower == null) return upper;
    if (upper == null) return lower;
    if (lower == upper) return lower;

    // Linear interpolation
    final t = (distance - lower.rangeM) / (upper.rangeM - lower.rangeM);

    return BallisticRowData(
      rangeM: distance,
      elevationMil: lower.elevationMil + t * (upper.elevationMil - lower.elevationMil),
      tofS: lower.tofS + t * (upper.tofS - lower.tofS),
      driftMil: lower.driftMil + t * (upper.driftMil - lower.driftMil),
    );
  }

  /// Export table to JSON
  String exportTable(String mortar) {
    final table = _tables[mortar];
    if (table == null) throw Exception('Table not found: $mortar');
    return jsonEncode(table.toJson());
  }

  /// Import table from JSON
  Future<void> importTable(String jsonString) async {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final table = BallisticTableData.fromJson(json);
    
    _tables[table.mortar] = table;

    // Save to device storage
    final appDir = await getApplicationDocumentsDirectory();
    final tablesDir = Directory('${appDir.path}/tables');
    await tablesDir.create(recursive: true);

    final file = File('${tablesDir.path}/${table.mortar.toLowerCase()}.json');
    await file.writeAsString(jsonString);
  }

  /// Copy default tables to device storage
  Future<void> copyDefaultsToDevice() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tablesDir = Directory('${appDir.path}/tables');
    
    if (!await tablesDir.exists()) {
      await tablesDir.create(recursive: true);
    }

    final defaultTables = ['m252', '2b14', 'm224'];
    
    for (final tableName in defaultTables) {
      final targetFile = File('${tablesDir.path}/$tableName.json');
      if (await targetFile.exists()) continue;

      try {
        final jsonString = await rootBundle.loadString(
          'assets/data_pack/tables/$tableName.json'
        );
        await targetFile.writeAsString(jsonString);
      } catch (e) {
        debugPrint('Failed to copy table $tableName: $e');
      }
    }
  }
}

/// Ballistic table data model
class BallisticTableData {
  final String format;
  final String mortar;
  final String description;
  final int caliberMm;
  final String origin;
  final String firingMode;
  final List<ChargeData> charges;
  final Map<String, dynamic> specifications;

  BallisticTableData({
    required this.format,
    required this.mortar,
    required this.description,
    required this.caliberMm,
    required this.origin,
    required this.firingMode,
    required this.charges,
    required this.specifications,
  });

  factory BallisticTableData.fromJson(Map<String, dynamic> json) {
    return BallisticTableData(
      format: json['format'] as String,
      mortar: json['mortar'] as String,
      description: json['description'] as String,
      caliberMm: json['caliber_mm'] as int,
      origin: json['origin'] as String,
      firingMode: json['firing_mode'] as String,
      charges: (json['charges'] as List<dynamic>)
          .map((e) => ChargeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      specifications: json['specifications'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'mortar': mortar,
      'description': description,
      'caliber_mm': caliberMm,
      'origin': origin,
      'firing_mode': firingMode,
      'charges': charges.map((c) => c.toJson()).toList(),
      'specifications': specifications,
    };
  }

  double get maxRangeM => specifications['max_range_m'] as double;
  double get minRangeM => specifications['min_range_m'] as double;
}

/// Charge data model
class ChargeData {
  final int charge;
  final String description;
  final String propellant;
  final int increments;
  final double minRangeM;
  final double maxRangeM;
  final List<BallisticRowData> table;

  ChargeData({
    required this.charge,
    required this.description,
    required this.propellant,
    required this.increments,
    required this.minRangeM,
    required this.maxRangeM,
    required this.table,
  });

  factory ChargeData.fromJson(Map<String, dynamic> json) {
    return ChargeData(
      charge: json['charge'] as int,
      description: json['description'] as String,
      propellant: json['propellant'] as String,
      increments: json['increments'] as int,
      minRangeM: (json['min_range_m'] as num).toDouble(),
      maxRangeM: (json['max_range_m'] as num).toDouble(),
      table: (json['table'] as List<dynamic>)
          .map((e) => BallisticRowData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charge': charge,
      'description': description,
      'propellant': propellant,
      'increments': increments,
      'min_range_m': minRangeM,
      'max_range_m': maxRangeM,
      'table': table.map((r) => r.toJson()).toList(),
    };
  }
}

/// Ballistic row data model
class BallisticRowData {
  final double rangeM;
  final double elevationMil;
  final double tofS;
  final double driftMil;

  BallisticRowData({
    required this.rangeM,
    required this.elevationMil,
    required this.tofS,
    required this.driftMil,
  });

  factory BallisticRowData.fromJson(Map<String, dynamic> json) {
    return BallisticRowData(
      rangeM: (json['range_m'] as num).toDouble(),
      elevationMil: (json['elevation_mil'] as num).toDouble(),
      tofS: (json['tof_s'] as num).toDouble(),
      driftMil: (json['drift_mil'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'range_m': rangeM,
      'elevation_mil': elevationMil,
      'tof_s': tofS,
      'drift_mil': driftMil,
    };
  }
}
