import 'dart:math';
import '../../models/models.dart';

/// Heightmap support for automatic altitude lookup
/// 
/// Heightmap data format:
/// - Stored as 2D array of elevation values
/// - Can be loaded from image (grayscale = height) or raw data
/// - Supports multiple resolution levels for performance
class Heightmap {
  final String name;
  final int width;
  final int height;
  final List<double> data;
  final double worldSize;
  final double minElevation;
  final double maxElevation;
  
  Heightmap({
    required this.name,
    required this.width,
    required this.height,
    required this.data,
    required this.worldSize,
    this.minElevation = 0,
    this.maxElevation = 1000,
  });
  
  /// Get elevation at world coordinates
  double getElevationAt(Position position) {
    return getElevationAtXY(position.x, position.y);
  }
  
  /// Get elevation at specific world x,y
  double getElevationAtXY(double x, double y) {
    // Convert world coordinates to heightmap indices
    final px = ((x / worldSize) * width).clamp(0, width - 1).toInt();
    final py = ((1 - y / worldSize) * height).clamp(0, height - 1).toInt();
    
    return _getInterpolatedElevation(px, py, x, y);
  }
  
  /// Bilinear interpolation for smooth elevation
  double _getInterpolatedElevation(int px, int py, double worldX, double worldY) {
    final scaleX = worldSize / width;
    final scaleY = worldSize / height;
    
    // Fractional position within cell
    final fx = (worldX / scaleX) - px;
    final fy = (worldY / scaleY) - py;
    
    // Get surrounding values
    final x0 = px.clamp(0, width - 1);
    final x1 = (px + 1).clamp(0, width - 1);
    final y0 = py.clamp(0, height - 1);
    final y1 = (py + 1).clamp(0, height - 1);
    
    final q00 = _getRawElevation(x0, y0);
    final q01 = _getRawElevation(x0, y1);
    final q10 = _getRawElevation(x1, y0);
    final q11 = _getRawElevation(x1, y1);
    
    // Bilinear interpolation
    final r0 = q00 * (1 - fx) + q10 * fx;
    final r1 = q01 * (1 - fx) + q11 * fx;
    
    return r0 * (1 - fy) + r1 * fy;
  }
  
  /// Get raw elevation from array
  double _getRawElevation(int x, int y) {
    final index = y * width + x;
    if (index < 0 || index >= data.length) return minElevation;
    return data[index];
  }
  
  /// Get elevation gradient (slope) at position
  /// Returns (dx, dy) elevation change per meter
  ({double dx, double dy}) getGradientAt(Position position) {
    final delta = worldSize / width; // meters per pixel
    
    final e = getElevationAtXY(position.x + delta, position.y);
    final w = getElevationAtXY(position.x - delta, position.y);
    final n = getElevationAtXY(position.x, position.y + delta);
    final s = getElevationAtXY(position.x, position.y - delta);
    
    return (
      dx: (e - w) / (2 * delta),
      dy: (n - s) / (2 * delta),
    );
  }
  
  /// Get slope angle at position (in degrees)
  double getSlopeAngle(Position position) {
    final grad = getGradientAt(position);
    final slope = (grad.dx * grad.dx + grad.dy * grad.dy);
    return atan(slope) * (180 / pi);
  }
  
  /// Check if line of sight exists between two points
  /// Simple ray-casting check
  bool hasLineOfSight(Position from, Position to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final distance = (dx * dx + dy * dy);
    
    if (distance < 1) return true;
    
    final steps = (distance / (worldSize / width)).ceil().clamp(10, 100);
    final stepX = dx / steps;
    final stepY = dy / steps;
    final stepElev = (to.altitude - from.altitude) / steps;
    
    for (int i = 1; i < steps; i++) {
      final x = from.x + stepX * i;
      final y = from.y + stepY * i;
      final terrainHeight = getElevationAtXY(x, y);
      const lineHeight = 0; // Simplified
      
      if (terrainHeight > from.altitude + stepElev * i + lineHeight) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Create heightmap from grayscale image bytes
  static Heightmap fromGrayscaleImage(
    List<int> imageBytes,
    int width,
    int height, {
    required double worldSize,
    double minElevation = 0,
    double maxElevation = 1000,
    String name = 'Imported',
  }) {
    final data = <double>[];
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = imageBytes[y * width + x];
        // Normalize to 0-1 and scale to elevation range
        final normalized = pixel / 255.0;
        final elevation = minElevation + (normalized * (maxElevation - minElevation));
        data.add(elevation);
      }
    }
    
    return Heightmap(
      name: name,
      width: width,
      height: height,
      data: data,
      worldSize: worldSize,
      minElevation: minElevation,
      maxElevation: maxElevation,
    );
  }
  
  /// Create heightmap from raw float data
  static Heightmap fromRawData(
    List<double> data,
    int width,
    int height, {
    required double worldSize,
    String name = 'Raw',
  }) {
    return Heightmap(
      name: name,
      width: width,
      height: height,
      data: List.from(data),
      worldSize: worldSize,
      minElevation: data.reduce((a, b) => a < b ? a : b),
      maxElevation: data.reduce((a, b) => a > b ? a : b),
    );
  }
  
  /// Downsample for lower LOD
  Heightmap downsample(int factor) {
    final newWidth = width ~/ factor;
    final newHeight = height ~/ factor;
    final newData = <double>[];
    
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        // Average surrounding pixels
        var sum = 0.0;
        var count = 0;
        
        for (int dy = 0; dy < factor; dy++) {
          for (int dx = 0; dx < factor; dx++) {
            final px = (x * factor + dx).clamp(0, width - 1);
            final py = (y * factor + dy).clamp(0, height - 1);
            sum += _getRawElevation(px, py);
            count++;
          }
        }
        
        newData.add(sum / count);
      }
    }
    
    return Heightmap(
      name: '$name (LOD)',
      width: newWidth,
      height: newHeight,
      data: newData,
      worldSize: worldSize,
      minElevation: minElevation,
      maxElevation: maxElevation,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'width': width,
    'height': height,
    'worldSize': worldSize,
    'minElevation': minElevation,
    'maxElevation': maxElevation,
    'data': data, // Note: this could be large
  };
}

/// Heightmap manager
class HeightmapManager {
  final Map<String, Heightmap> _heightmaps = {};
  String? _activeHeightmap;
  
  Heightmap? get activeHeightmap =>
    _activeHeightmap != null ? _heightmaps[_activeHeightmap] : null;
  
  List<String> get availableHeightmaps => _heightmaps.keys.toList();
  
  /// Add heightmap
  void addHeightmap(String name, Heightmap heightmap) {
    _heightmaps[name] = heightmap;
    _activeHeightmap ??= name;
  }
  
  /// Set active heightmap
  void setActive(String name) {
    if (_heightmaps.containsKey(name)) {
      _activeHeightmap = name;
    }
  }
  
  /// Remove heightmap
  void removeHeightmap(String name) {
    _heightmaps.remove(name);
    if (_activeHeightmap == name) {
      _activeHeightmap = _heightmaps.keys.firstOrNull;
    }
  }
  
  /// Get elevation at position using active heightmap
  double? getElevation(Position position) {
    return activeHeightmap?.getElevationAt(position);
  }
  
  /// Auto-set altitude on position
  Position autoAltitude(Position position) {
    final elevation = getElevation(position);
    if (elevation != null) {
      return position.copyWith(altitude: elevation);
    }
    return position;
  }
  
  /// Clear all heightmaps
  void clear() {
    _heightmaps.clear();
    _activeHeightmap = null;
  }
}

// ignore: unused_import
const double pi = 3.14159265359;
