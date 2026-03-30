import 'package:equatable/equatable.dart';

/// Represents map metadata
class MapMetadata extends Equatable {
  final String name;
  final String description;
  final double worldSize;
  final double gridSize;
  final double pixelsPerMeter;
  final List<double> origin;
  final String? heightmapPath;
  final String? mapImage;

  /// Actual image dimensions stored from JSON (or derived from worldSize * pixelsPerMeter).
  final int _imageWidth;
  final int _imageHeight;

  const MapMetadata({
    required this.name,
    required this.description,
    required this.worldSize,
    required this.gridSize,
    required this.pixelsPerMeter,
    required this.origin,
    this.heightmapPath,
    this.mapImage,
    int? imageWidth,
    int? imageHeight,
  })  : _imageWidth = imageWidth ?? 0,
        _imageHeight = imageHeight ?? 0;

  /// Create from JSON
  factory MapMetadata.fromJson(Map<String, dynamic> json) {
    final worldSize = (json['worldSize'] as num).toDouble();
    final pixelsPerMeter = (json['pixelsPerMeter'] as num).toDouble();
    final derived = (worldSize * pixelsPerMeter).round();

    final imageWidth =
        (json['imageWidth'] as num?)?.round() ?? derived;
    final imageHeight =
        (json['imageHeight'] as num?)?.round() ?? derived;

    return MapMetadata(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      worldSize: worldSize,
      gridSize: (json['gridSize'] as num).toDouble(),
      pixelsPerMeter: pixelsPerMeter,
      origin: (json['origin'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0],
      heightmapPath: json['heightmap'] as String?,
      mapImage: json['image'] as String? ?? 'map.png',
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'worldSize': worldSize,
        'gridSize': gridSize,
        'pixelsPerMeter': pixelsPerMeter,
        'origin': origin,
        'heightmap': heightmapPath,
        'image': mapImage,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
      };

  /// Image width in pixels (from JSON or derived from worldSize * pixelsPerMeter).
  int get imageWidth =>
      _imageWidth > 0 ? _imageWidth : (worldSize * pixelsPerMeter).round();

  /// Image height in pixels (from JSON or derived from worldSize * pixelsPerMeter).
  int get imageHeight =>
      _imageHeight > 0 ? _imageHeight : (worldSize * pixelsPerMeter).round();

  /// World height derived from aspect ratio so non-square maps work correctly.
  double get worldHeight =>
      imageHeight > 0 && imageWidth > 0
          ? worldSize * (imageHeight / imageWidth)
          : worldSize;

  /// Meters per pixel (inverse of pixelsPerMeter)
  double get metersPerPixel => 1.0 / pixelsPerMeter;

  /// Convert world coordinates to pixel coordinates
  ({double x, double y}) worldToPixel(
      double worldX, double worldY, int imageWidth, int imageHeight) {
    final pixelX = (worldX / worldSize) * imageWidth;
    final pixelY = imageHeight - (worldY / worldHeight) * imageHeight;
    return (x: pixelX, y: pixelY);
  }

  /// Convert pixel coordinates to world coordinates
  ({double x, double y}) pixelToWorld(
      double pixelX, double pixelY, int imageWidth, int imageHeight) {
    final worldX = (pixelX / imageWidth) * worldSize;
    final worldY = ((imageHeight - pixelY) / imageHeight) * worldHeight;
    return (x: worldX, y: worldY);
  }

  @override
  List<Object?> get props =>
      [name, worldSize, gridSize, pixelsPerMeter, origin, mapImage,
       _imageWidth, _imageHeight];

  @override
  String toString() =>
      'MapMetadata(name: $name, size: $worldSize, '
      'image: ${imageWidth}x${imageHeight})';
}
