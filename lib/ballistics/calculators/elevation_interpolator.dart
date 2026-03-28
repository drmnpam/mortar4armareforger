import '../../models/models.dart';
import '../tables.dart';

/// Dedicated elevation interpolator
class ElevationInterpolator {
  /// Interpolate elevation from ballistic table
  static BallisticRow interpolate(
    BallisticTable table,
    double distance, {
    InterpolationMethod method = InterpolationMethod.linear,
  }) {
    final lower = table.findLowerBound(distance);
    final upper = table.findUpperBound(distance);
    
    // If exact match
    if (lower != null && lower.range == distance) {
      return lower;
    }
    
    // Out of bounds - extrapolate
    if (lower == null) return _extrapolate(table, distance, forward: true);
    if (upper == null) return _extrapolate(table, distance, forward: false);
    
    // Interpolate
    switch (method) {
      case InterpolationMethod.linear:
        return _linearInterpolate(lower, upper, distance);
      case InterpolationMethod.cosine:
        return _cosineInterpolate(lower, upper, distance);
      default:
        return _linearInterpolate(lower, upper, distance);
    }
  }
  
  /// Linear interpolation
  static BallisticRow _linearInterpolate(
    BallisticRow lower,
    BallisticRow upper,
    double targetRange,
  ) {
    final t = (targetRange - lower.range) / (upper.range - lower.range);
    
    return BallisticRow(
      range: targetRange,
      elevation: lower.elevation + t * (upper.elevation - lower.elevation),
      timeOfFlight: lower.timeOfFlight + t * (upper.timeOfFlight - lower.timeOfFlight),
      heightOfBurst: _interpolateOptional(lower.heightOfBurst, upper.heightOfBurst, t),
      drift: _interpolateOptional(lower.drift, upper.drift, t),
    );
  }
  
  /// Cosine interpolation (smoother)
  static BallisticRow _cosineInterpolate(
    BallisticRow lower,
    BallisticRow upper,
    double targetRange,
  ) {
    final t = (targetRange - lower.range) / (upper.range - lower.range);
    final cosT = (1 - (t * 3.14159265359).cos()) / 2;
    
    return BallisticRow(
      range: targetRange,
      elevation: lower.elevation + cosT * (upper.elevation - lower.elevation),
      timeOfFlight: lower.timeOfFlight + cosT * (upper.timeOfFlight - lower.timeOfFlight),
      heightOfBurst: _interpolateOptional(lower.heightOfBurst, upper.heightOfBurst, cosT),
      drift: _interpolateOptional(lower.drift, upper.drift, cosT),
    );
  }
  
  /// Extrapolate beyond table bounds
  static BallisticRow _extrapolate(
    BallisticTable table,
    double targetRange, {
    required bool forward,
  }) {
    final rows = table.table;
    if (rows.length < 2) return rows.first;
    
    BallisticRow r1, r2;
    if (forward) {
      r1 = rows[0];
      r2 = rows[1];
    } else {
      r1 = rows[rows.length - 2];
      r2 = rows[rows.length - 1];
    }
    
    return _linearInterpolate(r1, r2, targetRange);
  }
  
  /// Interpolate optional values
  static double? _interpolateOptional(double? a, double? b, double t) {
    if (a == null || b == null) return null;
    return a + t * (b - a);
  }
  
  /// Get elevation at exact table ranges only
  static double? getExactElevation(BallisticTable table, double distance) {
    for (final row in table.table) {
      if ((row.range - distance).abs() < 0.01) {
        return row.elevation;
      }
    }
    return null;
  }
  
  /// Get elevation range for a distance across all charges
  static ({double min, double max}) getElevationRange(
    String mortarType,
    double distance,
  ) {
    final tables = BallisticTables.getTables(mortarType);
    
    double? minElevation;
    double? maxElevation;
    
    for (final table in tables) {
      if (distance >= table.minRange && distance <= table.maxRange) {
        final row = interpolate(table, distance);
        
        if (minElevation == null || row.elevation < minElevation) {
          minElevation = row.elevation;
        }
        if (maxElevation == null || row.elevation > maxElevation) {
          maxElevation = row.elevation;
        }
      }
    }
    
    return (
      min: minElevation ?? 0,
      max: maxElevation ?? 0,
    );
  }
  
  /// Estimate elevation falloff per meter (for quick adjustments)
  static double getElevationRate(BallisticTable table, double distance) {
    final row = table.findClosestIndex(distance);
    if (row <= 0 || row >= table.table.length - 1) return 0;
    
    final prev = table.table[row - 1];
    final next = table.table[row + 1];
    
    return (next.elevation - prev.elevation) / (next.range - prev.range);
  }
}

enum InterpolationMethod {
  linear,
  cosine,
}
