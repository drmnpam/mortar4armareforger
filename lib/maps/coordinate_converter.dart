import 'dart:math';
import '../models/models.dart';

/// Coordinate conversion utilities
class CoordinateConverter {
  /// Convert grid coordinates to world coordinates
  /// Grid format: "012 345" or "0123 4567"
  static Position? gridToPosition(String gridReference, {int precision = 3}) {
    try {
      // Remove spaces and validate
      final clean = gridReference.replaceAll(' ', '').replaceAll('-', '');
      if (clean.length != precision * 4) {
        return null;
      }
      
      // Split into x and y components
      final mid = precision * 2;
      final xStr = clean.substring(0, mid);
      final yStr = clean.substring(mid);
      
      final x = double.parse(xStr.padRight(6, '0'));
      final y = double.parse(yStr.padRight(6, '0'));
      
      return Position(x: x, y: y);
    } catch (e) {
      return null;
    }
  }
  
  /// Convert position to grid reference
  static String positionToGrid(
    Position position, {
    int precision = 3,
    bool includeSpaces = true,
  }) {
    return position.toGridReference(precision: precision);
  }
  
  /// Convert world coordinates to map pixel coordinates
  static ({double x, double y}) worldToPixel(
    Position position,
    MapMetadata metadata,
    int imageWidth,
    int imageHeight,
  ) {
    return metadata.worldToPixel(position.x, position.y, imageWidth, imageHeight);
  }
  
  /// Convert map pixel coordinates to world coordinates
  static Position pixelToWorld(
    double pixelX,
    double pixelY,
    MapMetadata metadata,
    int imageWidth,
    int imageHeight,
  ) {
    final result = metadata.pixelToWorld(pixelX, pixelY, imageWidth, imageHeight);
    return Position(x: result.x, y: result.y);
  }
  
  /// Calculate grid cell coordinates from world position
  static ({int x, int y}) worldToGridCell(
    Position position,
    double gridSize,
  ) {
    return (
      x: (position.x / gridSize).floor(),
      y: (position.y / gridSize).floor(),
    );
  }
  
  /// Get grid cell bounds in world coordinates
  static ({double minX, double minY, double maxX, double maxY}) getGridCellBounds(
    int cellX,
    int cellY,
    double gridSize,
  ) {
    return (
      minX: cellX * gridSize,
      minY: cellY * gridSize,
      maxX: (cellX + 1) * gridSize,
      maxY: (cellY + 1) * gridSize,
    );
  }
  
  /// Get grid label for a cell (e.g., "AA 01")
  static String getGridLabel(int cellX, int cellY) {
    final letterX = String.fromCharCode(65 + (cellX % 26));
    final letterY = String.fromCharCode(65 + (cellY % 26));
    return '$letterX$letterY ${(cellX ~/ 26).toString().padLeft(2, '0')}${(cellY ~/ 26).toString().padLeft(2, '0')}';
  }
  
  /// Parse Arma-style coordinates (6-digit precision)
  static Position? parseArmaCoordinates(String input) {
    // Remove all non-numeric characters
    final numeric = input.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numeric.length != 12) {
      return null;
    }
    
    final x = double.parse(numeric.substring(0, 6));
    final y = double.parse(numeric.substring(6, 12));
    
    return Position(x: x, y: y);
  }
  
  /// Format coordinates in Arma style
  static String formatArmaCoordinates(Position position) {
    final x = position.x.toInt().toString().padLeft(6, '0');
    final y = position.y.toInt().toString().padLeft(6, '0');
    return '$x $y';
  }
  
  /// Convert distance to display string
  static String formatDistance(double meters, {bool useKilometers = false}) {
    if (useKilometers && meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
  
  /// Convert azimuth to mils and format
  static String formatAzimuthMils(double radians) {
    const radiansToMils = 1018.5916;
    var mils = (radians * radiansToMils).round();
    
    // Normalize to 0-6400
    while (mils < 0) mils += 6400;
    while (mils >= 6400) mils -= 6400;
    
    return mils.toString().padLeft(4, '0');
  }
  
  /// Convert azimuth mils to degrees
  static double milsToDegrees(double mils) {
    return mils * 360 / 6400;
  }
  
  /// Convert degrees to mils
  static double degreesToMils(double degrees) {
    return degrees * 6400 / 360;
  }
  
  /// Calculate bearing between two points in degrees
  static double calculateBearingDegrees(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    
    final bearing = atan2(dx, dy) * (180 / pi);
    return (bearing + 360) % 360;
  }
  
  /// Calculate midpoint between two positions
  static Position calculateMidpoint(Position a, Position b) {
    return Position(
      x: (a.x + b.x) / 2,
      y: (a.y + b.y) / 2,
      altitude: (a.altitude + b.altitude) / 2,
    );
  }
  
  /// Extend line by distance
  static Position extendLine(
    Position start,
    Position end,
    double additionalDistance,
  ) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final currentDistance = sqrt(dx * dx + dy * dy);
    
    if (currentDistance == 0) return end;
    
    final ratio = (currentDistance + additionalDistance) / currentDistance;
    
    return Position(
      x: start.x + dx * ratio,
      y: start.y + dy * ratio,
      altitude: end.altitude,
    );
  }
}
