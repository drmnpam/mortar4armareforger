import 'package:equatable/equatable.dart';
import 'position.dart';

/// Map metadata for loading and displaying maps
class MapMetadata extends Equatable {
  /// Map display name
  final String name;
  
  /// Image filename
  final String image;
  
  /// World size in meters (e.g., 10240 for 10km x 10km)
  final double worldSize;
  
  /// Grid cell size in meters
  final double gridSize;
  
  /// Pixels per meter ratio
  final double pixelsPerMeter;
  
  /// Optional description
  final String? description;
  
  /// Optional minimum/maximum coordinates
  final double? minX;
  final double? minY;
  final double? maxX;
  final double? maxY;

  const MapMetadata({
    required this.name,
    required this.image,
    required this.worldSize,
    required this.gridSize,
    required this.pixelsPerMeter,
    this.description,
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
  });

  /// Convert world coordinates to pixel coordinates
  MapOffset worldToPixel(double x, double y, double imageWidth, double imageHeight) {
    final pixelX = x * pixelsPerMeter;
    final pixelY = imageHeight - (y * pixelsPerMeter); // Flip Y axis
    return MapOffset(pixelX, pixelY);
  }

  /// Convert pixel coordinates to world coordinates
  Position pixelToWorld(double pixelX, double pixelY, double imageHeight) {
    final worldX = pixelX / pixelsPerMeter;
    final worldY = (imageHeight - pixelY) / pixelsPerMeter;
    return Position(x: worldX, y: worldY);
  }

  factory MapMetadata.fromJson(Map<String, dynamic> json) {
    return MapMetadata(
      name: json['name'] as String,
      image: json['image'] as String,
      worldSize: (json['worldSize'] as num).toDouble(),
      gridSize: (json['gridSize'] as num).toDouble(),
      pixelsPerMeter: (json['pixelsPerMeter'] as num).toDouble(),
      description: json['description'] as String?,
      minX: (json['minX'] as num?)?.toDouble(),
      minY: (json['minY'] as num?)?.toDouble(),
      maxX: (json['maxX'] as num?)?.toDouble(),
      maxY: (json['maxY'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'image': image,
    'worldSize': worldSize,
    'gridSize': gridSize,
    'pixelsPerMeter': pixelsPerMeter,
    if (description != null) 'description': description,
    if (minX != null) 'minX': minX,
    if (minY != null) 'minY': minY,
    if (maxX != null) 'maxX': maxX,
    if (maxY != null) 'maxY': maxY,
  };

  @override
  List<Object?> get props => [name, image, worldSize, gridSize, pixelsPerMeter];

  @override
  String toString() => 'MapMetadata($name, ${worldSize}m x ${worldSize}m)';
}

class MapOffset {
  final double dx;
  final double dy;
  
  const MapOffset(this.dx, this.dy);
  
  double get distance => (dx * dx + dy * dy);
}
