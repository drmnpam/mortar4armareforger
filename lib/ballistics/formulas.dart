import 'dart:math';

import '../models/models.dart';

/// Ballistic formulas and calculations
class BallisticFormulas {
  /// Constant for converting radians to mils (NATO standard)
  /// 1 radian = 1018.5916 mils (NATO 6400 mils per circle)
  static const double radiansToMils = 1018.5916;
  
  /// Total mils in circle
  static const double totalMils = 6400.0;

  /// Calculate distance between two positions (2D)
  static double calculateDistance(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate azimuth in mils (NATO standard)
  /// Returns value between 0 and 6400
  static double calculateAzimuth(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    
    // atan2 returns angle from positive X axis
    // In Arma, Y is north, so we swap dx and dy
    double azimuthRad = atan2(dx, dy);
    
    // Convert to mils
    double azimuthMils = azimuthRad * radiansToMils;
    
    // Normalize to 0-6400
    while (azimuthMils < 0) {
      azimuthMils += totalMils;
    }
    while (azimuthMils >= totalMils) {
      azimuthMils -= totalMils;
    }
    
    return azimuthMils;
  }

  /// Calculate height difference between positions
  static double calculateHeightDifference(Position from, Position to) {
    return to.altitude - from.altitude;
  }

  /// Calculate site (height correction factor)
  /// Returns mils correction per meter of height difference
  static double calculateSite(double heightDifference, double distance) {
    if (distance == 0) return 0.0;
    return heightDifference / distance;
  }

  /// Apply height correction to elevation
  /// Formula: correctedElevation = elevation + (site * 1000)
  /// The factor 1000 is an approximation based on standard ballistic curves
  static double applyHeightCorrection(
    double elevation,
    double heightDifference,
    double distance,
  ) {
    if (distance == 0) return elevation;
    final site = heightDifference / distance;
    return elevation + (site * 1000);
  }

  /// Linear interpolation between two values
  /// y = y1 + (x - x1) * (y2 - y1) / (x2 - x1)
  static double linearInterpolate(
    double x1, double y1,
    double x2, double y2,
    double x,
  ) {
    if (x2 == x1) return y1;
    return y1 + (x - x1) * (y2 - y1) / (x2 - x1);
  }

  /// Interpolate ballistic data between two rows
  static BallisticRow interpolateBallisticRow(
    BallisticRow lower,
    BallisticRow upper,
    double targetRange,
  ) {
    final elevation = linearInterpolate(
      lower.range, lower.elevation,
      upper.range, upper.elevation,
      targetRange,
    );
    
    final timeOfFlight = linearInterpolate(
      lower.range, lower.timeOfFlight,
      upper.range, upper.timeOfFlight,
      targetRange,
    );
    
    double? heightOfBurst;
    if (lower.heightOfBurst != null && upper.heightOfBurst != null) {
      heightOfBurst = linearInterpolate(
        lower.range, lower.heightOfBurst!,
        upper.range, upper.heightOfBurst!,
        targetRange,
      );
    }
    
    double? drift;
    if (lower.drift != null && upper.drift != null) {
      drift = linearInterpolate(
        lower.range, lower.drift!,
        upper.range, upper.drift!,
        targetRange,
      );
    }
    
    return BallisticRow(
      range: targetRange,
      elevation: elevation,
      timeOfFlight: timeOfFlight,
      heightOfBurst: heightOfBurst,
      drift: drift,
    );
  }

  /// Convert azimuth to cardinal direction string
  static String azimuthToDirection(double azimuthMils) {
    final directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    final index = ((azimuthMils + 200) / 400).floor() % 16;
    return directions[index];
  }

  /// Format azimuth as display string (e.g., "3240")
  static String formatAzimuth(double azimuthMils) {
    final rounded = azimuthMils.round();
    return rounded.toString().padLeft(4, '0');
  }

  /// Check if a range is valid for a given charge
  static bool isRangeValid(
    double range,
    BallisticTable table, {
    double tolerance = 10.0,
  }) {
    return range >= table.minRange - tolerance && 
           range <= table.maxRange + tolerance;
  }

  /// Calculate quadrant elevation for high angle fire
  /// This is used when terrain or other factors require high angle
  static double? calculateHighAngleElevation(
    double distance,
    List<BallisticTable> tables,
  ) {
    // Find first charge that can reach this distance at high angle
    for (final table in tables.reversed) {
      // High angle is typically at the end of the table
      if (distance <= table.maxRange * 0.95) {
        final closest = table.findClosestIndex(distance);
        final row = table.table[closest];
        // Check if this is in high angle range (> 1000 mils typically)
        if (row.elevation > 1000) {
          return row.elevation;
        }
      }
    }
    return null;
  }

  /// Estimate impact dispersion based on range
  /// Returns approximate CEP (Circular Error Probable) in meters
  static double estimateDispersion(double range, int charge) {
    // Simplified dispersion model
    // Base dispersion increases with range
    final baseDispersion = 5.0; // meters at 0 range
    final rangeFactor = range * 0.005; // 0.5% of range
    final chargeFactor = 1.0 + (charge * 0.1); // Higher charges = more dispersion
    return (baseDispersion + rangeFactor) * chargeFactor;
  }
}
