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

  /// Source image width in pixels.
  final double imageWidth;

  /// Source image height in pixels.
  final double imageHeight;
  
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
    required this.imageWidth,
    required this.imageHeight,
    this.description,
    this.minX,
    this.minY,
    this.maxX,
    this.maxY,
  });

  /// Convert world coordinates to pixel coordinates
  MapOffset worldToPixel(double x, double y, double mapPixelWidth, double mapPixelHeight) {
    final pixelX = (x / worldSize) * mapPixelWidth;
    final pixelY = (1 - (y / worldHeight)) * mapPixelHeight;
    return MapOffset(pixelX, pixelY);
  }

  /// Convert pixel coordinates to world coordinates
  Position pixelToWorld(
      double pixelX, double pixelY, double mapPixelWidth, double mapPixelHeight) {
    final worldX = (pixelX / mapPixelWidth) * worldSize;
    final worldY = (1 - (pixelY / mapPixelHeight)) * worldHeight;
    return Position(x: worldX, y: worldY);
  }

  /// Pixel-to-meter ratio based on map width.
  double get metersPerPixel => worldSize / imageWidth;

  /// World height in meters derived from image aspect ratio.
  double get worldHeight => imageHeight * metersPerPixel;

  factory MapMetadata.fromJson(Map<String, dynamic> json) {
    final worldSize = (json['worldSize'] as num).toDouble();
    final legacyPixelsPerMeter =
        (json['pixelsPerMeter'] as num?)?.toDouble() ?? 1.0;
    final imageWidth =
        (json['imageWidth'] as num?)?.toDouble() ?? (worldSize * legacyPixelsPerMeter);
    final imageHeight =
        (json['imageHeight'] as num?)?.toDouble() ?? imageWidth;

    return MapMetadata(
      name: json['name'] as String,
      image: json['image'] as String,
      worldSize: worldSize,
      gridSize: (json['gridSize'] as num).toDouble(),
      pixelsPerMeter: legacyPixelsPerMeter,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
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
    'imageWidth': imageWidth,
    'imageHeight': imageHeight,
    if (description != null) 'description': description,
    if (minX != null) 'minX': minX,
    if (minY != null) 'minY': minY,
    if (maxX != null) 'maxX': maxX,
    if (maxY != null) 'maxY': maxY,
  };

  @override
  List<Object?> get props => [
    name,
    image,
    worldSize,
    gridSize,
    pixelsPerMeter,
    imageWidth,
    imageHeight,
  ];

  @override
  String toString() =>
      'MapMetadata($name, ${worldSize}m x ${worldHeight.toStringAsFixed(1)}m)';
}

class MapOffset {
  final double dx;
  final double dy;
  
  const MapOffset(this.dx, this.dy);
  
  double get distance => (dx * dx + dy * dy);
}
