import '../../models/models.dart';
import '../tables.dart';

/// Dedicated charge selector
class ChargeSelector {
  /// Select optimal charge for given distance
  /// Returns lowest charge that can reach the target
  static int selectOptimalCharge(
    String mortarType,
    double distance, {
    bool preferLowTrajectory = true,
  }) {
    final tables = BallisticTables.getTables(mortarType);
    
    if (tables.isEmpty) return 0;
    
    // Find the lowest charge that can reach this distance
    for (final table in tables) {
      if (distance <= table.maxRange * 1.02) { // 2% tolerance
        return table.charge;
      }
    }
    
    // If beyond max range, return highest available charge
    return tables.last.charge;
  }
  
  /// Select charge for flattest trajectory (lowest elevation)
  static int selectFlattestCharge(String mortarType, double distance) {
    final tables = BallisticTables.getTables(mortarType);
    
    int? bestCharge;
    double? lowestElevation;
    
    for (final table in tables) {
      if (distance < table.minRange || distance > table.maxRange * 1.02) {
        continue;
      }
      
      // Get elevation at this distance
      final row = _getInterpolatedRow(table, distance);
      if (row != null) {
        if (lowestElevation == null || row.elevation < lowestElevation) {
          lowestElevation = row.elevation;
          bestCharge = table.charge;
        }
      }
    }
    
    return bestCharge ?? tables.firstOrNull?.charge ?? 0;
  }
  
  /// Select charge for highest angle (terrain clearance)
  static int selectHighAngleCharge(String mortarType, double distance) {
    final tables = BallisticTables.getTables(mortarType);
    
    int? bestCharge;
    double? highestElevation;
    
    for (final table in tables.reversed) {
      if (distance < table.minRange || distance > table.maxRange * 1.02) {
        continue;
      }
      
      final row = _getInterpolatedRow(table, distance);
      if (row != null) {
        if (highestElevation == null || row.elevation > highestElevation) {
          highestElevation = row.elevation;
          bestCharge = table.charge;
        }
      }
    }
    
    return bestCharge ?? tables.lastOrNull?.charge ?? 0;
  }
  
  /// Check if a specific charge can reach the target
  static bool canReach(
    String mortarType,
    int charge,
    double distance, {
    double tolerance = 10.0,
  }) {
    final table = BallisticTables.getTable(mortarType, charge);
    if (table == null) return false;
    
    return distance >= table.minRange - tolerance &&
           distance <= table.maxRange + tolerance;
  }
  
  /// Get all viable charges for a distance
  static List<int> getViableCharges(
    String mortarType,
    double distance, {
    double tolerance = 10.0,
  }) {
    final tables = BallisticTables.getTables(mortarType);
    final viable = <int>[];
    
    for (final table in tables) {
      if (distance >= table.minRange - tolerance &&
          distance <= table.maxRange + tolerance) {
        viable.add(table.charge);
      }
    }
    
    return viable;
  }
  
  /// Get charge range information
  static ChargeRangeInfo getChargeRangeInfo(String mortarType, int charge) {
    final table = BallisticTables.getTable(mortarType, charge);
    if (table == null) {
      return ChargeRangeInfo(
        charge: charge,
        minRange: 0,
        maxRange: 0,
        minElevation: 0,
        maxElevation: 0,
      );
    }
    
    final elevations = table.table.map((r) => r.elevation).toList();
    
    return ChargeRangeInfo(
      charge: charge,
      minRange: table.minRange,
      maxRange: table.maxRange,
      minElevation: elevations.reduce((a, b) => a < b ? a : b),
      maxElevation: elevations.reduce((a, b) => a > b ? a : b),
    );
  }
  
  /// Helper: Get interpolated row
  static BallisticRow? _getInterpolatedRow(BallisticTable table, double distance) {
    final lower = table.findLowerBound(distance);
    final upper = table.findUpperBound(distance);
    
    if (lower == null && upper == null) return null;
    if (lower == null) return upper;
    if (upper == null) return lower;
    if (lower == upper) return lower;
    
    // Linear interpolation
    final t = (distance - lower.range) / (upper.range - lower.range);
    return BallisticRow(
      range: distance,
      elevation: lower.elevation + t * (upper.elevation - lower.elevation),
      timeOfFlight: lower.timeOfFlight + t * (upper.timeOfFlight - lower.timeOfFlight),
    );
  }
}

/// Information about a charge's range capabilities
class ChargeRangeInfo {
  final int charge;
  final double minRange;
  final double maxRange;
  final double minElevation;
  final double maxElevation;
  
  const ChargeRangeInfo({
    required this.charge,
    required this.minRange,
    required this.maxRange,
    required this.minElevation,
    required this.maxElevation,
  });
  
  bool get isValid => maxRange > minRange;
  
  double get midRange => (minRange + maxRange) / 2;
}
