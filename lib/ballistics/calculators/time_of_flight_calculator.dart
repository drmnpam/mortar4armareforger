import '../../models/models.dart';
import '../tables.dart';

/// Time of flight calculator
class TimeOfFlightCalculator {
  /// Get TOF from ballistic table
  static double getTimeOfFlight(
    String mortarType,
    int charge,
    double distance,
  ) {
    final table = BallisticTables.getTable(mortarType, charge);
    if (table == null) return 0;
    
    final lower = table.findLowerBound(distance);
    final upper = table.findUpperBound(distance);
    
    if (lower == null && upper == null) return 0;
    if (lower == null) return upper!.timeOfFlight;
    if (upper == null) return lower.timeOfFlight;
    if (lower == upper) return lower.timeOfFlight;
    
    // Interpolate
    final t = (distance - lower.range) / (upper.range - lower.range);
    return lower.timeOfFlight + t * (upper.timeOfFlight - lower.timeOfFlight);
  }
  
  /// Get TOF for complete solution
  static double calculate(
    String mortarType,
    int charge,
    double distance,
    double heightDifference,
  ) {
    final baseTOF = getTimeOfFlight(mortarType, charge, distance);
    
    // Height adjustment
    final heightFactor = 1 + (heightDifference / distance) * 0.05;
    
    return baseTOF * heightFactor;
  }
  
  /// Estimate TOF for all charges at given distance
  static Map<int, double> estimateForAllCharges(
    String mortarType,
    double distance,
  ) {
    final tables = BallisticTables.getTables(mortarType);
    final results = <int, double>{};
    
    for (final table in tables) {
      if (distance >= table.minRange && distance <= table.maxRange) {
        results[table.charge] = getTimeOfFlight(mortarType, table.charge, distance);
      }
    }
    
    return results;
  }
  
  /// Format TOF for display
  static String format(double tof) {
    return '${tof.toStringAsFixed(1)}s';
  }
  
  /// Get splash time (TOF + fuze delay if applicable)
  static double getSplashTime(
    double tof, {
    double fuzeDelay = 0,
  }) {
    return tof + fuzeDelay;
  }
}
