import 'package:equatable/equatable.dart';
import 'weapon_ballistic_row.dart';
import 'weapon_type.dart';

/// Complete ballistic table for a weapon
/// Supports multiple charges and trajectories
class WeaponBallisticTable extends Equatable {
  /// Weapon identifier (e.g., "M107", "2S1", "122mm D30")
  final String weapon;
  
  /// Weapon type determines calculation method
  final WeaponType type;
  
  /// Available trajectories (e.g., ["low", "high"] for angle tables)
  final List<String>? trajectories;
  
  /// Default trajectory to use
  final String? defaultTrajectory;
  
  /// Ballistic data organized by charge
  /// Key: charge number (as string), Value: list of rows
  final Map<String, List<WeaponBallisticRow>> charges;
  
  /// For angle tables without charges - single data list
  final List<WeaponBallisticRow>? data;
  
  /// Description of the weapon/ammunition
  final String? description;
  
  const WeaponBallisticTable({
    required this.weapon,
    required this.type,
    this.trajectories,
    this.defaultTrajectory,
    this.charges = const {},
    this.data,
    this.description,
  });
  
  /// Get all available charges
  List<String> get availableCharges => charges.keys.toList()..sort();
  
  /// Get data for specific charge
  List<WeaponBallisticRow>? getChargeData(String charge) => charges[charge];
  
  /// Get minimum range across all charges
  double get minRange {
    double min = double.infinity;
    for (final rows in charges.values) {
      if (rows.isNotEmpty && rows.first.range < min) {
        min = rows.first.range;
      }
    }
    return min == double.infinity ? 0 : min;
  }
  
  /// Get maximum range across all charges
  double get maxRange {
    double max = 0;
    for (final rows in charges.values) {
      if (rows.isNotEmpty && rows.last.range > max) {
        max = rows.last.range;
      }
    }
    return max;
  }
  
  /// Interpolate values for given range and charge
  /// Returns interpolated elevation, time of flight, etc.
  WeaponBallisticRow? interpolate(double range, String charge) {
    final rows = charges[charge];
    if (rows == null || rows.isEmpty) return null;
    
    // Find bounding rows
    WeaponBallisticRow? lower;
    WeaponBallisticRow? upper;
    
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].range <= range) lower = rows[i];
      if (rows[i].range >= range && upper == null) upper = rows[i];
    }
    
    // If exact match or at bounds
    if (lower == null) return rows.first;
    if (upper == null || lower.range == range) return lower;
    if (upper.range == range) return upper;
    
    // Interpolate
    final t = (range - lower.range) / (upper.range - lower.range);
    
    return WeaponBallisticRow(
      range: range,
      elevation: _interpolateValue(lower.elevation, upper.elevation, t),
      angle: _interpolateValue(lower.angle, upper.angle, t),
      timeOfFlight: _interpolateValue(lower.timeOfFlight, upper.timeOfFlight, t),
      fuzeSetting: _interpolateValue(lower.fuzeSetting, upper.fuzeSetting, t),
    );
  }
  
  double? _interpolateValue(double? v1, double? v2, double t) {
    if (v1 == null || v2 == null) return v1 ?? v2;
    return v1 + t * (v2 - v1);
  }
  
  factory WeaponBallisticTable.fromJson(Map<String, dynamic> json) {
    final type = WeaponTypeExtension.fromJson(json['type'] as String? ?? 'mortar');
    
    // Parse charges - handle both Map format and Array format
    Map<String, List<WeaponBallisticRow>> charges = {};
    final chargesJson = json['charges'];
    if (chargesJson is Map<String, dynamic>) {
      // Standard format: charges as Map<String, List>
      charges = chargesJson.map((key, value) => 
        MapEntry(key, (value as List)
          .map((e) => WeaponBallisticRow.fromJson(e as Map<String, dynamic>))
          .toList()));
    } else if (chargesJson is List) {
      // Mortar format: charges as array of charge objects
      for (final chargeObj in chargesJson) {
        final chargeNum = chargeObj['charge']?.toString();
        final table = chargeObj['table'] as List?;
        if (chargeNum != null && table != null) {
          charges[chargeNum] = table
            .map((e) => WeaponBallisticRow.fromJson(e as Map<String, dynamic>))
            .toList();
        }
      }
    }
    
    // Parse data (for angle tables)
    List<WeaponBallisticRow>? data;
    final dataJson = json['data'] as List?;
    if (dataJson != null) {
      data = dataJson
        .map((e) => WeaponBallisticRow.fromJson(e as Map<String, dynamic>))
        .toList();
    }
    
    // Handle both "weapon" and "mortar" field names
    final weaponName = json['weapon'] as String? ?? json['mortar'] as String? ?? 'Unknown';
    
    return WeaponBallisticTable(
      weapon: weaponName,
      type: type,
      trajectories: (json['trajectory'] as List?)?.cast<String>(),
      defaultTrajectory: json['defaultTrajectory'] as String?,
      charges: charges,
      data: data,
      description: json['description'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'weapon': weapon,
    'type': type.jsonValue,
    if (trajectories != null) 'trajectory': trajectories,
    if (defaultTrajectory != null) 'defaultTrajectory': defaultTrajectory,
    if (charges.isNotEmpty) 
      'charges': charges.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    if (data != null) 
      'data': data!.map((e) => e.toJson()).toList(),
    if (description != null) 'description': description,
  };
  
  @override
  List<Object?> get props => [weapon, type, charges, data, trajectories];
}
