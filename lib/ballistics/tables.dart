import 'dart:convert';

import '../models/models.dart';

/// Ballistic table loader and manager
class BallisticTables {
  static final Map<String, List<BallisticTable>> _tables = {};
  static final Set<String> _customMortars = {};
  static bool _initialized = false;

  /// Initialize with default tables
  static void initialize() {
    if (_initialized) return;

    // Load M252 tables
    _tables['M252'] = _loadM252Tables();

    // Load 2B14 Podnos tables (Russian 82mm)
    _tables['2B14'] = _load2B14Tables();

    // Load M224 tables (60mm)
    _tables['M224'] = _loadM224Tables();

    _initialized = true;
  }

  /// Get all tables for a mortar type
  static List<BallisticTable> getTables(String mortarType) {
    if (!_initialized) initialize();
    return _tables[mortarType] ?? [];
  }

  /// Get table for specific mortar and charge
  static BallisticTable? getTable(String mortarType, int charge) {
    final tables = getTables(mortarType);
    try {
      return tables.firstWhere((t) => t.charge == charge);
    } catch (_) {
      return null;
    }
  }

  /// Get all available mortar types
  static List<String> get availableMortars => _tables.keys.toList()..sort();

  /// Get imported custom mortar types.
  static List<String> get customMortars => _customMortars.toList()..sort();

  /// Select best charge for given distance
  /// Returns the charge with lowest elevation (flattest trajectory)
  static int selectCharge(String mortarType, double distance) {
    final tables = getTables(mortarType);

    // Find lowest charge that can reach this distance
    for (int i = 0; i < tables.length; i++) {
      if (distance <= tables[i].maxRange * 1.05) {
        return tables[i].charge;
      }
    }

    // If beyond max range, use highest charge
    return tables.isNotEmpty ? tables.last.charge : 0;
  }

  /// Check if a charge can be used for a given distance
  static bool canUseCharge(
    String mortarType,
    int charge,
    double distance, {
    double tolerance = 10.0,
  }) {
    final table = getTable(mortarType, charge);
    if (table == null) return false;
    return distance >= table.minRange - tolerance &&
        distance <= table.maxRange + tolerance;
  }

  // Default tables for M252 81mm mortar
  static List<BallisticTable> _loadM252Tables() {
    return [
      // Charge 0
      BallisticTable(
        mortar: 'M252',
        charge: 0,
        table: [
          const BallisticRow(range: 100, elevation: 1520, timeOfFlight: 11.5),
          const BallisticRow(range: 200, elevation: 1490, timeOfFlight: 12.8),
          const BallisticRow(range: 300, elevation: 1450, timeOfFlight: 14.2),
          const BallisticRow(range: 400, elevation: 1400, timeOfFlight: 15.8),
          const BallisticRow(range: 500, elevation: 1340, timeOfFlight: 17.6),
          const BallisticRow(range: 600, elevation: 1270, timeOfFlight: 19.7),
          const BallisticRow(range: 700, elevation: 1180, timeOfFlight: 22.2),
          const BallisticRow(range: 800, elevation: 1070, timeOfFlight: 25.4),
          const BallisticRow(range: 900, elevation: 920, timeOfFlight: 30.1),
          const BallisticRow(range: 1000, elevation: 700, timeOfFlight: 39.5),
        ],
      ),
      // Charge 1
      BallisticTable(
        mortar: 'M252',
        charge: 1,
        table: [
          const BallisticRow(range: 300, elevation: 1520, timeOfFlight: 14.2),
          const BallisticRow(range: 400, elevation: 1490, timeOfFlight: 15.8),
          const BallisticRow(range: 500, elevation: 1460, timeOfFlight: 17.6),
          const BallisticRow(range: 600, elevation: 1420, timeOfFlight: 19.7),
          const BallisticRow(range: 700, elevation: 1380, timeOfFlight: 22.2),
          const BallisticRow(range: 800, elevation: 1340, timeOfFlight: 25.4),
          const BallisticRow(range: 900, elevation: 1290, timeOfFlight: 30.1),
          const BallisticRow(range: 1000, elevation: 1230, timeOfFlight: 39.5),
          const BallisticRow(range: 1100, elevation: 1160, timeOfFlight: 44.2),
          const BallisticRow(range: 1200, elevation: 1070, timeOfFlight: 48.5),
          const BallisticRow(range: 1300, elevation: 950, timeOfFlight: 52.8),
          const BallisticRow(range: 1400, elevation: 750, timeOfFlight: 57.1),
          const BallisticRow(range: 1500, elevation: 400, timeOfFlight: 61.5),
        ],
      ),
      // Charge 2
      BallisticTable(
        mortar: 'M252',
        charge: 2,
        table: [
          const BallisticRow(range: 600, elevation: 1520, timeOfFlight: 19.7),
          const BallisticRow(range: 700, elevation: 1490, timeOfFlight: 22.2),
          const BallisticRow(range: 800, elevation: 1460, timeOfFlight: 25.4),
          const BallisticRow(range: 900, elevation: 1430, timeOfFlight: 30.1),
          const BallisticRow(range: 1000, elevation: 1400, timeOfFlight: 32.5),
          const BallisticRow(range: 1200, elevation: 1330, timeOfFlight: 38.5),
          const BallisticRow(range: 1400, elevation: 1250, timeOfFlight: 43.8),
          const BallisticRow(range: 1600, elevation: 1160, timeOfFlight: 49.2),
          const BallisticRow(range: 1800, elevation: 1050, timeOfFlight: 54.6),
          const BallisticRow(range: 2000, elevation: 900, timeOfFlight: 60.1),
          const BallisticRow(range: 2200, elevation: 680, timeOfFlight: 65.8),
          const BallisticRow(range: 2400, elevation: 280, timeOfFlight: 72.1),
        ],
      ),
      // Charge 3
      BallisticTable(
        mortar: 'M252',
        charge: 3,
        table: [
          const BallisticRow(range: 1100, elevation: 1520, timeOfFlight: 44.2),
          const BallisticRow(range: 1200, elevation: 1490, timeOfFlight: 48.5),
          const BallisticRow(range: 1400, elevation: 1440, timeOfFlight: 52.8),
          const BallisticRow(range: 1600, elevation: 1390, timeOfFlight: 57.1),
          const BallisticRow(range: 1800, elevation: 1340, timeOfFlight: 61.5),
          const BallisticRow(range: 2000, elevation: 1280, timeOfFlight: 65.8),
          const BallisticRow(range: 2200, elevation: 1220, timeOfFlight: 70.2),
          const BallisticRow(range: 2400, elevation: 1160, timeOfFlight: 74.5),
          const BallisticRow(range: 2600, elevation: 1090, timeOfFlight: 78.9),
          const BallisticRow(range: 2800, elevation: 1010, timeOfFlight: 83.2),
          const BallisticRow(range: 3000, elevation: 920, timeOfFlight: 87.6),
          const BallisticRow(range: 3200, elevation: 800, timeOfFlight: 92.0),
          const BallisticRow(range: 3400, elevation: 620, timeOfFlight: 96.5),
          const BallisticRow(range: 3600, elevation: 280, timeOfFlight: 101.1),
        ],
      ),
    ];
  }

  // Default tables for 2B14 Podnos 82mm mortar
  static List<BallisticTable> _load2B14Tables() {
    return [
      // Charge 0 (close range)
      BallisticTable(
        mortar: '2B14',
        charge: 0,
        table: [
          const BallisticRow(range: 100, elevation: 1510, timeOfFlight: 11.2),
          const BallisticRow(range: 200, elevation: 1480, timeOfFlight: 12.5),
          const BallisticRow(range: 300, elevation: 1440, timeOfFlight: 13.9),
          const BallisticRow(range: 400, elevation: 1390, timeOfFlight: 15.4),
          const BallisticRow(range: 500, elevation: 1330, timeOfFlight: 17.1),
          const BallisticRow(range: 600, elevation: 1260, timeOfFlight: 19.0),
          const BallisticRow(range: 700, elevation: 1170, timeOfFlight: 21.3),
          const BallisticRow(range: 800, elevation: 1060, timeOfFlight: 24.1),
          const BallisticRow(range: 900, elevation: 900, timeOfFlight: 28.0),
          const BallisticRow(range: 1000, elevation: 650, timeOfFlight: 34.2),
        ],
      ),
      // Charge 1
      BallisticTable(
        mortar: '2B14',
        charge: 1,
        table: [
          const BallisticRow(range: 300, elevation: 1510, timeOfFlight: 13.9),
          const BallisticRow(range: 400, elevation: 1480, timeOfFlight: 15.4),
          const BallisticRow(range: 500, elevation: 1450, timeOfFlight: 17.1),
          const BallisticRow(range: 600, elevation: 1410, timeOfFlight: 19.0),
          const BallisticRow(range: 700, elevation: 1370, timeOfFlight: 21.3),
          const BallisticRow(range: 800, elevation: 1330, timeOfFlight: 24.1),
          const BallisticRow(range: 900, elevation: 1280, timeOfFlight: 28.0),
          const BallisticRow(range: 1000, elevation: 1220, timeOfFlight: 32.2),
          const BallisticRow(range: 1100, elevation: 1150, timeOfFlight: 36.5),
          const BallisticRow(range: 1200, elevation: 1060, timeOfFlight: 40.8),
          const BallisticRow(range: 1300, elevation: 940, timeOfFlight: 45.2),
          const BallisticRow(range: 1400, elevation: 740, timeOfFlight: 49.5),
          const BallisticRow(range: 1500, elevation: 350, timeOfFlight: 54.0),
        ],
      ),
      // Charge 2
      BallisticTable(
        mortar: '2B14',
        charge: 2,
        table: [
          const BallisticRow(range: 600, elevation: 1510, timeOfFlight: 19.0),
          const BallisticRow(range: 700, elevation: 1480, timeOfFlight: 21.3),
          const BallisticRow(range: 800, elevation: 1450, timeOfFlight: 24.1),
          const BallisticRow(range: 900, elevation: 1420, timeOfFlight: 28.0),
          const BallisticRow(range: 1000, elevation: 1390, timeOfFlight: 30.8),
          const BallisticRow(range: 1200, elevation: 1320, timeOfFlight: 36.8),
          const BallisticRow(range: 1400, elevation: 1240, timeOfFlight: 42.5),
          const BallisticRow(range: 1600, elevation: 1150, timeOfFlight: 48.2),
          const BallisticRow(range: 1800, elevation: 1040, timeOfFlight: 54.0),
          const BallisticRow(range: 2000, elevation: 880, timeOfFlight: 60.0),
          const BallisticRow(range: 2200, elevation: 650, timeOfFlight: 66.5),
          const BallisticRow(range: 2400, elevation: 250, timeOfFlight: 73.5),
        ],
      ),
      // Charge 3
      BallisticTable(
        mortar: '2B14',
        charge: 3,
        table: [
          const BallisticRow(range: 1100, elevation: 1510, timeOfFlight: 42.5),
          const BallisticRow(range: 1200, elevation: 1480, timeOfFlight: 46.8),
          const BallisticRow(range: 1400, elevation: 1430, timeOfFlight: 51.2),
          const BallisticRow(range: 1600, elevation: 1380, timeOfFlight: 55.5),
          const BallisticRow(range: 1800, elevation: 1330, timeOfFlight: 59.8),
          const BallisticRow(range: 2000, elevation: 1270, timeOfFlight: 64.2),
          const BallisticRow(range: 2200, elevation: 1210, timeOfFlight: 68.5),
          const BallisticRow(range: 2400, elevation: 1150, timeOfFlight: 72.8),
          const BallisticRow(range: 2600, elevation: 1080, timeOfFlight: 77.2),
          const BallisticRow(range: 2800, elevation: 1000, timeOfFlight: 81.5),
          const BallisticRow(range: 3000, elevation: 910, timeOfFlight: 85.8),
          const BallisticRow(range: 3200, elevation: 790, timeOfFlight: 90.2),
          const BallisticRow(range: 3400, elevation: 610, timeOfFlight: 94.5),
          const BallisticRow(range: 3600, elevation: 260, timeOfFlight: 99.2),
        ],
      ),
    ];
  }

  // Default tables for M224 60mm mortar
  static List<BallisticTable> _loadM224Tables() {
    return [
      // Charge 0
      BallisticTable(
        mortar: 'M224',
        charge: 0,
        table: [
          const BallisticRow(range: 100, elevation: 1480, timeOfFlight: 9.5),
          const BallisticRow(range: 200, elevation: 1450, timeOfFlight: 10.5),
          const BallisticRow(range: 300, elevation: 1410, timeOfFlight: 11.6),
          const BallisticRow(range: 400, elevation: 1360, timeOfFlight: 12.8),
          const BallisticRow(range: 500, elevation: 1300, timeOfFlight: 14.2),
          const BallisticRow(range: 600, elevation: 1230, timeOfFlight: 15.8),
          const BallisticRow(range: 700, elevation: 1140, timeOfFlight: 17.7),
          const BallisticRow(range: 800, elevation: 1020, timeOfFlight: 20.1),
          const BallisticRow(range: 900, elevation: 850, timeOfFlight: 23.2),
          const BallisticRow(range: 1000, elevation: 580, timeOfFlight: 28.0),
        ],
      ),
      // Charge 1
      BallisticTable(
        mortar: 'M224',
        charge: 1,
        table: [
          const BallisticRow(range: 300, elevation: 1480, timeOfFlight: 11.6),
          const BallisticRow(range: 400, elevation: 1450, timeOfFlight: 12.8),
          const BallisticRow(range: 500, elevation: 1420, timeOfFlight: 14.2),
          const BallisticRow(range: 600, elevation: 1380, timeOfFlight: 15.8),
          const BallisticRow(range: 700, elevation: 1340, timeOfFlight: 17.7),
          const BallisticRow(range: 800, elevation: 1300, timeOfFlight: 20.1),
          const BallisticRow(range: 900, elevation: 1250, timeOfFlight: 23.2),
          const BallisticRow(range: 1000, elevation: 1190, timeOfFlight: 26.5),
          const BallisticRow(range: 1100, elevation: 1120, timeOfFlight: 29.8),
          const BallisticRow(range: 1200, elevation: 1030, timeOfFlight: 33.2),
          const BallisticRow(range: 1300, elevation: 910, timeOfFlight: 36.5),
          const BallisticRow(range: 1400, elevation: 710, timeOfFlight: 40.0),
          const BallisticRow(range: 1500, elevation: 320, timeOfFlight: 44.0),
        ],
      ),
      // Charge 2
      BallisticTable(
        mortar: 'M224',
        charge: 2,
        table: [
          const BallisticRow(range: 500, elevation: 1480, timeOfFlight: 14.2),
          const BallisticRow(range: 600, elevation: 1450, timeOfFlight: 15.8),
          const BallisticRow(range: 700, elevation: 1420, timeOfFlight: 17.7),
          const BallisticRow(range: 800, elevation: 1390, timeOfFlight: 20.1),
          const BallisticRow(range: 900, elevation: 1360, timeOfFlight: 22.5),
          const BallisticRow(range: 1000, elevation: 1320, timeOfFlight: 25.0),
          const BallisticRow(range: 1100, elevation: 1280, timeOfFlight: 28.0),
          const BallisticRow(range: 1200, elevation: 1230, timeOfFlight: 31.0),
          const BallisticRow(range: 1400, elevation: 1120, timeOfFlight: 37.0),
          const BallisticRow(range: 1600, elevation: 990, timeOfFlight: 43.0),
          const BallisticRow(range: 1800, elevation: 820, timeOfFlight: 49.0),
          const BallisticRow(range: 2000, elevation: 560, timeOfFlight: 55.5),
          const BallisticRow(range: 2200, elevation: 100, timeOfFlight: 63.0),
        ],
      ),
      // Charge 3
      BallisticTable(
        mortar: 'M224',
        charge: 3,
        table: [
          const BallisticRow(range: 900, elevation: 1480, timeOfFlight: 23.2),
          const BallisticRow(range: 1000, elevation: 1450, timeOfFlight: 26.5),
          const BallisticRow(range: 1200, elevation: 1400, timeOfFlight: 31.0),
          const BallisticRow(range: 1400, elevation: 1340, timeOfFlight: 36.5),
          const BallisticRow(range: 1600, elevation: 1280, timeOfFlight: 42.0),
          const BallisticRow(range: 1800, elevation: 1210, timeOfFlight: 47.5),
          const BallisticRow(range: 2000, elevation: 1140, timeOfFlight: 53.0),
          const BallisticRow(range: 2200, elevation: 1060, timeOfFlight: 58.5),
          const BallisticRow(range: 2400, elevation: 970, timeOfFlight: 64.0),
          const BallisticRow(range: 2600, elevation: 860, timeOfFlight: 69.5),
          const BallisticRow(range: 2800, elevation: 720, timeOfFlight: 75.0),
          const BallisticRow(range: 3000, elevation: 520, timeOfFlight: 81.0),
          const BallisticRow(range: 3200, elevation: 180, timeOfFlight: 87.5),
        ],
      ),
    ];
  }

  /// Load raw table rows for a mortar.
  static void loadFromJson(
    String mortarType,
    List<Map<String, dynamic>> json, {
    bool markCustom = false,
  }) {
    if (!_initialized) initialize();
    _tables[mortarType] = json
        .map((e) => BallisticTable.fromJson(e))
        .toList(growable: false)
      ..sort((a, b) => a.charge.compareTo(b.charge));
    if (markCustom) {
      _customMortars.add(mortarType);
    }
  }

  /// Parse one or many custom table JSON objects.
  static List<Map<String, dynamic>> parseImportPayload(String rawJson) {
    final decoded = jsonDecode(rawJson);
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
    throw const FormatException('Unsupported JSON payload');
  }

  /// Import custom tables from payloads.
  static void importCustomTables(List<Map<String, dynamic>> payloads) {
    if (!_initialized) initialize();
    for (final payload in payloads) {
      importCustomTable(payload);
    }
  }

  /// Import one custom table.
  static void importCustomTable(Map<String, dynamic> payload) {
    if (!_initialized) initialize();
    final mortarName =
        (payload['mortar'] ?? payload['name'])?.toString().trim();
    if (mortarName == null || mortarName.isEmpty) {
      throw const FormatException('Custom table must include mortar name');
    }

    final rawCharges = payload['charges'];
    if (rawCharges is! List || rawCharges.isEmpty) {
      throw const FormatException('Custom table must include charges');
    }

    final builtTables = <BallisticTable>[];
    for (final chargeEntry in rawCharges) {
      if (chargeEntry is! Map) {
        throw const FormatException('Charge entry must be an object');
      }
      final chargeData = Map<String, dynamic>.from(chargeEntry);
      final charge = _toInt(chargeData['charge']);
      if (charge == null) {
        throw const FormatException('Charge must be a number');
      }
      final rawRows = chargeData['table'] ?? chargeData['rows'];
      if (rawRows is! List || rawRows.isEmpty) {
        throw const FormatException('Charge must include table rows');
      }

      final rows = <BallisticRow>[];
      for (final rowEntry in rawRows) {
        if (rowEntry is! Map) {
          throw const FormatException('Table row must be an object');
        }
        final row = Map<String, dynamic>.from(rowEntry);
        final range = _toDouble(row['range'] ?? row['range_m']);
        final elevation = _toDouble(row['elevation'] ?? row['elevation_mil']);
        final tof =
            _toDouble(row['timeOfFlight'] ?? row['tof'] ?? row['tof_s']);
        if (range == null || elevation == null || tof == null) {
          throw const FormatException(
              'Each row requires range, elevation, timeOfFlight');
        }
        rows.add(
          BallisticRow(
            range: range,
            elevation: elevation,
            timeOfFlight: tof,
          ),
        );
      }

      rows.sort((a, b) => a.range.compareTo(b.range));
      builtTables.add(
        BallisticTable(
          mortar: mortarName,
          charge: charge,
          table: rows,
        ),
      );
    }

    builtTables.sort((a, b) => a.charge.compareTo(b.charge));
    _tables[mortarName] = builtTables;
    _customMortars.add(mortarName);
  }

  /// Export one mortar table in custom JSON format.
  static Map<String, dynamic> exportMortarAsJson(String mortarType) {
    if (!_initialized) initialize();
    final tables = getTables(mortarType);
    if (tables.isEmpty) {
      throw FormatException('Mortar "$mortarType" is not available');
    }

    return {
      'mortar': mortarType,
      'charges': tables
          .map((table) => {
                'charge': table.charge,
                'table': table.table
                    .map((row) => {
                          'range': row.range,
                          'elevation': row.elevation,
                          'timeOfFlight': row.timeOfFlight,
                        })
                    .toList(growable: false),
              })
          .toList(growable: false),
    };
  }

  /// Export all custom mortars.
  static List<Map<String, dynamic>> exportCustomTables() {
    if (!_initialized) initialize();
    final exported = <Map<String, dynamic>>[];
    for (final mortar in customMortars) {
      exported.add(exportMortarAsJson(mortar));
    }
    return exported;
  }

  /// Export all custom mortars as JSON string.
  static String exportCustomTablesJson({bool pretty = false}) {
    final payload = {
      'mortars': exportCustomTables(),
    };
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(payload)
        : jsonEncode(payload);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Clear all tables
  static void clear() {
    _tables.clear();
    _customMortars.clear();
    _initialized = false;
  }
}
