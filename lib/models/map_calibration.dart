import 'package:equatable/equatable.dart';

/// Grid calibration mode
enum CalibrationMode {
  /// Automatic calibration using 100m reference line
  automatic,
  
  /// Legacy manual calibration with scale/offset
  manual,
}

extension CalibrationModeExtension on CalibrationMode {
  String get displayName {
    switch (this) {
      case CalibrationMode.automatic:
        return 'Automatic (100m reference)';
      case CalibrationMode.manual:
        return 'Manual (Legacy)';
    }
  }
  
  String get jsonValue {
    switch (this) {
      case CalibrationMode.automatic:
        return 'automatic';
      case CalibrationMode.manual:
        return 'manual';
    }
  }
  
  static CalibrationMode fromJson(String value) {
    switch (value) {
      case 'automatic':
        return CalibrationMode.automatic;
      case 'manual':
        return CalibrationMode.manual;
      default:
        return CalibrationMode.automatic;
    }
  }
}

/// Map calibration data using automatic 100m reference line method
class MapCalibration extends Equatable {
  /// Calibration mode
  final CalibrationMode mode;
  
  /// Meters per pixel - calculated from 100m reference line
  final double metersPerPixel;
  
  /// Grid size in meters (default 100)
  final double gridSizeMeters;
  
  /// Offset X in pixels
  final double offsetX;
  
  /// Offset Y in pixels
  final double offsetY;
  
  /// Reference point A (start of 100m line) - stored as normalized coords
  final double? refPointAX;
  final double? refPointAY;
  
  /// Reference point B (end of 100m line) - stored as normalized coords
  final double? refPointBX;
  final double? refPointBY;
  
  /// Legacy scale values (for manual mode compatibility)
  final double scaleX;
  final double scaleY;

  const MapCalibration({
    this.mode = CalibrationMode.automatic,
    this.metersPerPixel = 1.0,
    this.gridSizeMeters = 100.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.refPointAX,
    this.refPointAY,
    this.refPointBX,
    this.refPointBY,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  /// Calculate meters per pixel from reference line
  /// pixelDistance - distance between reference points in pixels
  /// referenceMeters - actual distance (default 100)
  factory MapCalibration.fromReferenceLine({
    required double pixelDistance,
    double referenceMeters = 100.0,
    required double refPointAX,
    required double refPointAY,
    required double refPointBX,
    required double refPointBY,
    double gridSizeMeters = 100.0,
  }) {
    final metersPerPixel = referenceMeters / pixelDistance;
    
    return MapCalibration(
      mode: CalibrationMode.automatic,
      metersPerPixel: metersPerPixel,
      gridSizeMeters: gridSizeMeters,
      offsetX: 0.0,
      offsetY: 0.0,
      refPointAX: refPointAX,
      refPointAY: refPointAY,
      refPointBX: refPointBX,
      refPointBY: refPointBY,
    );
  }

  /// Convert world coordinates to screen pixels
  /// Uses automatic calibration formula
  double worldToPixel(double worldPos, double imageSize) {
    if (mode == CalibrationMode.automatic) {
      // Automatic: world position * scale + offset
      final scale = 1.0 / metersPerPixel;
      return worldPos * scale + offsetX;
    } else {
      // Legacy manual mode
      return worldPos * scaleX + offsetX;
    }
  }

  /// Convert screen pixels to world coordinates
  double pixelToWorld(double pixelPos, double imageSize) {
    if (mode == CalibrationMode.automatic) {
      final scale = 1.0 / metersPerPixel;
      return (pixelPos - offsetX) / scale;
    } else {
      return (pixelPos - offsetX) / scaleX;
    }
  }

  /// Get grid size in pixels
  double get gridSizePixels => gridSizeMeters / metersPerPixel;

  /// Check if calibration is valid
  bool get isValid {
    if (mode == CalibrationMode.automatic) {
      return metersPerPixel > 0 && 
             refPointAX != null && 
             refPointAY != null && 
             refPointBX != null && 
             refPointBY != null;
    }
    return scaleX > 0 && scaleY > 0;
  }

  /// Get calibration info for display
  Map<String, dynamic> get info => {
    'mode': mode.displayName,
    'metersPerPixel': metersPerPixel.toStringAsFixed(4),
    'gridSizeMeters': gridSizeMeters.toStringAsFixed(0),
    'gridSizePixels': gridSizePixels.toStringAsFixed(1),
    'isValid': isValid,
  };

  factory MapCalibration.fromJson(Map<String, dynamic> json) {
    return MapCalibration(
      mode: CalibrationModeExtension.fromJson(json['mode'] as String? ?? 'automatic'),
      metersPerPixel: (json['metersPerPixel'] as num?)?.toDouble() ?? 1.0,
      gridSizeMeters: (json['gridSizeMeters'] as num?)?.toDouble() ?? 100.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      refPointAX: (json['refPointAX'] as num?)?.toDouble(),
      refPointAY: (json['refPointAY'] as num?)?.toDouble(),
      refPointBX: (json['refPointBX'] as num?)?.toDouble(),
      refPointBY: (json['refPointBY'] as num?)?.toDouble(),
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.jsonValue,
    'metersPerPixel': metersPerPixel,
    'gridSizeMeters': gridSizeMeters,
    'offsetX': offsetX,
    'offsetY': offsetY,
    if (refPointAX != null) 'refPointAX': refPointAX,
    if (refPointAY != null) 'refPointAY': refPointAY,
    if (refPointBX != null) 'refPointBX': refPointBX,
    if (refPointBY != null) 'refPointBY': refPointBY,
    'scaleX': scaleX,
    'scaleY': scaleY,
  };

  MapCalibration copyWith({
    CalibrationMode? mode,
    double? metersPerPixel,
    double? gridSizeMeters,
    double? offsetX,
    double? offsetY,
    double? refPointAX,
    double? refPointAY,
    double? refPointBX,
    double? refPointBY,
    double? scaleX,
    double? scaleY,
  }) {
    return MapCalibration(
      mode: mode ?? this.mode,
      metersPerPixel: metersPerPixel ?? this.metersPerPixel,
      gridSizeMeters: gridSizeMeters ?? this.gridSizeMeters,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      refPointAX: refPointAX ?? this.refPointAX,
      refPointAY: refPointAY ?? this.refPointAY,
      refPointBX: refPointBX ?? this.refPointBX,
      refPointBY: refPointBY ?? this.refPointBY,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
    );
  }

  @override
  List<Object?> get props => [
    mode, 
    metersPerPixel, 
    gridSizeMeters, 
    offsetX, 
    offsetY,
    refPointAX,
    refPointAY,
    refPointBX,
    refPointBY,
    scaleX,
    scaleY,
  ];
}
