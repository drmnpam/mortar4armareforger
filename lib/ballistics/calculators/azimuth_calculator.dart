import 'dart:math';
import '../../models/models.dart';

/// Dedicated azimuth calculator for NATO/Arma mils system
class AzimuthCalculator {
  /// NATO standard: 6400 mils per circle
  static const double totalMils = 6400.0;
  
  /// Conversion factor: radians to NATO mils
  static const double radiansToMils = 1018.5916; // 6400 / (2 * PI)
  
  /// Calculate azimuth in NATO mils (0-6400)
  /// In Arma/Arma Reforger, Y is North, X is East
  static double calculateAzimuth(Position from, Position to) {
    final dx = to.x - from.x; // East-West difference
    final dy = to.y - from.y; // North-South difference
    
    // atan2 returns angle from positive X axis (East)
    // But in military navigation, we want angle from North
    // So we swap dx and dy to get azimuth from North
    double azimuthRad = atan2(dx, dy);
    
    // Convert to mils
    double azimuthMils = azimuthRad * radiansToMils;
    
    // Normalize to 0-6400
    return normalize(azimuthMils);
  }
  
  /// Normalize azimuth to 0-6400 range
  static double normalize(double azimuthMils) {
    while (azimuthMils < 0) {
      azimuthMils += totalMils;
    }
    while (azimuthMils >= totalMils) {
      azimuthMils -= totalMils;
    }
    return azimuthMils;
  }
  
  /// Calculate azimuth difference (shortest path)
  static double calculateDifference(double azimuth1, double azimuth2) {
    double diff = azimuth2 - azimuth1;
    
    // Normalize to -3200 to +3200 (shortest rotation)
    while (diff > totalMils / 2) diff -= totalMils;
    while (diff < -totalMils / 2) diff += totalMils;
    
    return diff;
  }
  
  /// Add offset to azimuth
  static double addOffset(double azimuth, double offset) {
    return normalize(azimuth + offset);
  }
  
  /// Convert mils to degrees
  static double milsToDegrees(double mils) {
    return mils * 360 / totalMils;
  }
  
  /// Convert degrees to mils
  static double degreesToMils(double degrees) {
    return degrees * totalMils / 360;
  }
  
  /// Convert mils to radians
  static double milsToRadians(double mils) {
    return mils / radiansToMils;
  }
  
  /// Convert radians to mils
  static double radiansToMils(double radians) {
    return radians * radiansToMils;
  }
  
  /// Get cardinal direction from azimuth
  static String getCardinalDirection(double azimuthMils) {
    final directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];
    
    // Each direction covers 400 mils (6400 / 16)
    final index = ((azimuthMils + 200) / 400).floor() % 16;
    return directions[index];
  }
  
  /// Get precise direction description
  static String getDirectionDescription(double azimuthMils) {
    final cardinal = getCardinalDirection(azimuthMils);
    final mils = azimuthMils.round();
    return '$cardinal ($mils mils)';
  }
  
  /// Format azimuth for display (4 digits with leading zeros)
  static String format(double azimuthMils) {
    final mils = azimuthMils.round();
    return mils.toString().padLeft(4, '0');
  }
  
  /// Calculate deflection from baseline azimuth
  /// Positive = right, Negative = left (standard artillery convention)
  static double calculateDeflection(
    double baselineAzimuth,
    double targetAzimuth,
  ) {
    return calculateDifference(baselineAzimuth, targetAzimuth);
  }
  
  /// Check if target is left or right of baseline
  static String getDeflectionDirection(double deflection) {
    if (deflection.abs() < 10) return 'ON LINE';
    return deflection > 0 ? 'RIGHT' : 'LEFT';
  }
}
