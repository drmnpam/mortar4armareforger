import 'dart:math';
import 'dart:ui';
import '../../models/models.dart';
import 'grid_system.dart';

/// Comprehensive coordinate conversion module
/// Handles all coordinate transformations in the system
class CoordinateConverter {
  final GridCoordinateSystem _gridSystem;
  
  CoordinateConverter({
    required double worldSize,
    double gridSize = 100.0,
  }) : _gridSystem = GridCoordinateSystem(
         worldSize: worldSize,
         gridSize: gridSize,
       );
  
  // ==================== GRID CONVERSIONS ====================
  
  /// Grid to meters (world coordinates)
  Position gridToMeters(String gridReference) {
    return _gridSystem.gridToWorld(gridReference);
  }
  
  /// Meters to grid reference
  String metersToGrid(Position position) {
    return _gridSystem.worldToGrid(position);
  }
  
  /// Quick entry (6-digit) to meters
  Position quickEntryToMeters(String input) {
    return _gridSystem.parseQuickEntry(input);
  }
  
  /// Meters to quick entry format
  String metersToQuickEntry(Position position) {
    return _gridSystem.formatQuickEntry(position.x, position.y);
  }
  
  // ==================== MAP PIXEL CONVERSIONS ====================
  
  /// Meters to map pixels
  /// 
  /// Parameters:
  /// - position: World position in meters
  /// - imageSize: Size of the map image
  /// - worldSize: Size of the world in meters
  /// - flipY: Whether to flip Y axis (typically true for image coordinates)
  Offset metersToPixels(
    Position position,
    Size imageSize,
    double worldSize, {
    bool flipY = true,
  }) {
    final scaleX = imageSize.width / worldSize;
    final scaleY = imageSize.height / worldSize;
    
    final pixelX = position.x * scaleX;
    final pixelY = flipY
        ? imageSize.height - (position.y * scaleY)
        : position.y * scaleY;
    
    return Offset(pixelX, pixelY);
  }
  
  /// Pixels to meters
  Position pixelsToMeters(
    Offset pixel,
    Size imageSize,
    double worldSize, {
    bool flipY = true,
  }) {
    final scaleX = worldSize / imageSize.width;
    final scaleY = worldSize / imageSize.height;
    
    final worldX = pixel.dx * scaleX;
    final worldY = flipY
        ? (imageSize.height - pixel.dy) * scaleY
        : pixel.dy * scaleY;
    
    return Position(x: worldX, y: worldY);
  }
  
  /// Pixels to grid reference
  String pixelsToGrid(
    Offset pixel,
    Size imageSize,
    double worldSize, {
    bool flipY = true,
  }) {
    final meters = pixelsToMeters(pixel, imageSize, worldSize, flipY: flipY);
    return metersToGrid(meters);
  }
  
  /// Grid to pixels
  Offset gridToPixels(
    String grid,
    Size imageSize,
    double worldSize, {
    bool flipY = true,
  }) {
    final meters = gridToMeters(grid);
    return metersToPixels(meters, imageSize, worldSize, flipY: flipY);
  }
  
  // ==================== SCALE CONVERSIONS ====================
  
  /// Get scale factor (meters per pixel)
  double getScale(Size imageSize, double worldSize) {
    return worldSize / imageSize.width;
  }
  
  /// Convert distance in meters to pixels
  double metersToPixelsDistance(
    double meters,
    Size imageSize,
    double worldSize,
  ) {
    return meters * (imageSize.width / worldSize);
  }
  
  /// Convert distance in pixels to meters
  double pixelsToMetersDistance(
    double pixels,
    Size imageSize,
    double worldSize,
  ) {
    return pixels * (worldSize / imageSize.width);
  }
  
  // ==================== COORDINATE FORMATTING ====================
  
  /// Format meters to various coordinate formats
  String formatCoordinates(
    Position position, {
    CoordinateFormat format = CoordinateFormat.grid,
  }) {
    switch (format) {
      case CoordinateFormat.grid:
        return metersToGrid(position);
      case CoordinateFormat.quick:
        return metersToQuickEntry(position);
      case CoordinateFormat.full:
        return 'X: ${position.x.toStringAsFixed(1)} Y: ${position.y.toStringAsFixed(1)}';
      case CoordinateFormat.raw:
        return '${position.x.toStringAsFixed(2)}, ${position.y.toStringAsFixed(2)}';
    }
  }
  
  /// Parse coordinate from various formats
  Position? parseCoordinates(
    String input, {
    CoordinateFormat? hint,
  }) {
    // Try grid format first
    if (hint == null || hint == CoordinateFormat.grid) {
      try {
        return _gridSystem.gridToWorld(input);
      } catch (_) {}
    }
    
    // Try quick format
    if (hint == null || hint == CoordinateFormat.quick) {
      try {
        final clean = input.replaceAll(RegExp(r'[^\d]'), '');
        if (clean.length == 6) {
          return _gridSystem.parseQuickEntry(input);
        }
      } catch (_) {}
    }
    
    // Try raw format (x, y)
    if (hint == null || hint == CoordinateFormat.raw) {
      try {
        final parts = input.split(',');
        if (parts.length == 2) {
          return Position(
            x: double.parse(parts[0].trim()),
            y: double.parse(parts[1].trim()),
          );
        }
      } catch (_) {}
    }
    
    return null;
  }
  
  // ==================== TRANSFORMATION HELPERS ====================
  
  /// Transform a point with zoom and pan
  Offset applyZoomAndPan(
    Offset point,
    double zoom,
    Offset pan,
  ) {
    return Offset(
      point.dx * zoom + pan.dx,
      point.dy * zoom + pan.dy,
    );
  }
  
  /// Reverse zoom and pan transformation
  Offset removeZoomAndPan(
    Offset transformed,
    double zoom,
    Offset pan,
  ) {
    return Offset(
      (transformed.dx - pan.dx) / zoom,
      (transformed.dy - pan.dy) / zoom,
    );
  }
  
  /// Convert zoom level to scale factor
  double zoomToScale(double zoom) {
    return zoom;
  }
  
  /// Get visible area in meters from viewport
  Rect getVisibleArea(
    Size viewportSize,
    Offset pan,
    double zoom,
    Size imageSize,
    double worldSize,
  ) {
    // Get corner pixels in screen space
    final topLeft = removeZoomAndPan(Offset.zero, zoom, pan);
    final bottomRight = removeZoomAndPan(
      Offset(viewportSize.width, viewportSize.height),
      zoom,
      pan,
    );
    
    // Convert to meters
    final tl = pixelsToMeters(topLeft, imageSize, worldSize);
    final br = pixelsToMeters(bottomRight, imageSize, worldSize);
    
    return Rect.fromLTRB(
      tl.x,
      tl.y,
      br.x,
      br.y,
    );
  }
}

/// Coordinate format types
enum CoordinateFormat {
  grid,     // "012 345"
  quick,    // "012345"
  full,     // "X: 1234.5 Y: 5678.9"
  raw,      // "1234.5, 5678.9"
}

/// Helper class for Rect
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  
  const Rect.fromLTRB(this.left, this.top, this.right, this.bottom);
  
  double get width => right - left;
  double get height => bottom - top;
  
  bool contains(Position point) {
    return point.x >= left && point.x <= right &&
           point.y >= top && point.y <= bottom;
  }
}
