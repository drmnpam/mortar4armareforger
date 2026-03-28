import '../models/models.dart';
import 'formulas.dart';
import 'tables.dart';

/// Interpolator for ballistic table data
class BallisticInterpolator {
  /// Interpolate elevation and time of flight from table
  /// Returns interpolated BallisticRow or null if out of range
  static BallisticRow? interpolate(
    BallisticTable table,
    double targetRange, {
    bool extrapolate = false,
  }) {
    // Check if exact match exists
    final exactIndex = _findExactRange(table, targetRange);
    if (exactIndex >= 0) {
      return table.table[exactIndex];
    }

    // Find surrounding rows
    final bounds = _findBounds(table, targetRange);
    if (bounds == null) {
      if (!extrapolate) return null;
      return _extrapolate(table, targetRange);
    }

    // Interpolate
    return BallisticFormulas.interpolateBallisticRow(
      bounds.lower,
      bounds.upper,
      targetRange,
    );
  }

  /// Find index of exact range match
  static int _findExactRange(BallisticTable table, double targetRange) {
    for (int i = 0; i < table.table.length; i++) {
      if ((table.table[i].range - targetRange).abs() < 0.01) {
        return i;
      }
    }
    return -1;
  }

  /// Find lower and upper bounds for interpolation
  static _BoundsResult? _findBounds(BallisticTable table, double targetRange) {
    final rows = table.table;
    
    if (targetRange < rows.first.range || targetRange > rows.last.range) {
      return null;
    }

    for (int i = 0; i < rows.length - 1; i++) {
      if (rows[i].range <= targetRange && rows[i + 1].range >= targetRange) {
        return _BoundsResult(rows[i], rows[i + 1]);
      }
    }
    
    return null;
  }

  /// Extrapolate beyond table bounds
  static BallisticRow? _extrapolate(BallisticTable table, double targetRange) {
    final rows = table.table;
    
    if (rows.length < 2) return null;

    BallisticRow r1, r2;
    
    if (targetRange < rows.first.range) {
      // Extrapolate below
      r1 = rows[0];
      r2 = rows[1];
    } else {
      // Extrapolate above
      r1 = rows[rows.length - 2];
      r2 = rows[rows.length - 1];
    }

    return BallisticFormulas.interpolateBallisticRow(r1, r2, targetRange);
  }

  /// Get safe elevation range for a charge
  static ({double min, double max})? getElevationRange(BallisticTable table) {
    if (table.table.isEmpty) return null;
    
    final elevations = table.table.map((r) => r.elevation).toList();
    return (
      min: elevations.reduce((a, b) => a < b ? a : b),
      max: elevations.reduce((a, b) => a > b ? a : b),
    );
  }

  /// Estimate elevation for visualization
  /// Returns approximate elevation without interpolation for quick preview
  static double quickEstimate(BallisticTable table, double targetRange) {
    final closestIndex = table.findClosestIndex(targetRange);
    final closest = table.table[closestIndex];
    
    // If not at bounds, do simple interpolation
    if (closestIndex > 0 && closestIndex < table.table.length - 1) {
      final prev = table.table[closestIndex - 1];
      final next = table.table[closestIndex + 1];
      
      if (targetRange < closest.range) {
        return BallisticFormulas.linearInterpolate(
          prev.range, prev.elevation,
          closest.range, closest.elevation,
          targetRange,
        );
      } else {
        return BallisticFormulas.linearInterpolate(
          closest.range, closest.elevation,
          next.range, next.elevation,
          targetRange,
        );
      }
    }
    
    return closest.elevation;
  }
}

class _BoundsResult {
  final BallisticRow lower;
  final BallisticRow upper;
  
  _BoundsResult(this.lower, this.upper);
}
