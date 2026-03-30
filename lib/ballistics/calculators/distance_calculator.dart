import 'dart:math';
import '../../models/models.dart';

/// Dedicated distance calculator
class DistanceCalculator {
  /// Calculate 2D distance between two positions
  static double calculateDistance(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Alias for calculateDistance
  static double calculate2D(Position from, Position to) => calculateDistance(from, to);
  
  /// Calculate 3D distance including altitude
  static double calculateDistance3D(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dz = to.altitude - from.altitude;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
  
  /// Calculate slant range (true ballistic distance)
  /// This accounts for the actual trajectory path
  static double calculateSlantRange(
    Position from,
    Position to, {
    double? elevation,
  }) {
    final groundDistance = calculateDistance(from, to);
    final heightDiff = to.altitude - from.altitude;
    
    // If elevation provided, calculate more accurate slant
    if (elevation != null) {
      // Convert elevation from mils to approximate path multiplier
      // Lower elevation = flatter trajectory, closer to ground distance
      final elevationRad = elevation * 0.000981748; // mils to radians
      final pathMultiplier = 1 / cos(elevationRad);
      return groundDistance * pathMultiplier;
    }
    
    // Simple hypotenuse for 3D distance
    return sqrt(groundDistance * groundDistance + heightDiff * heightDiff);
  }
  
  /// Check if target is within mortar range
  static bool isWithinRange(
    Position mortar,
    Position target,
    double minRange,
    double maxRange,
  ) {
    final distance = calculateDistance(mortar, target);
    return distance >= minRange && distance <= maxRange;
  }
  
  /// Calculate distance from line (for error analysis)
  static double distanceFromLine(
    Position point,
    Position lineStart,
    Position lineEnd,
  ) {
    final dx = lineEnd.x - lineStart.x;
    final dy = lineEnd.y - lineStart.y;
    
    if (dx == 0 && dy == 0) {
      return calculateDistance(point, lineStart);
    }
    
    final t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) /
              (dx * dx + dy * dy);
    
    if (t < 0) return calculateDistance(point, lineStart);
    if (t > 1) return calculateDistance(point, lineEnd);
    
    final projX = lineStart.x + t * dx;
    final projY = lineStart.y + t * dy;
    
    return sqrt((point.x - projX) * (point.x - projX) +
                (point.y - projY) * (point.y - projY));
  }
}
