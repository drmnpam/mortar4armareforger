import '../../models/models.dart';

/// Dedicated height correction module
class HeightCorrector {
  /// Standard site calculation (height correction factor)
  /// Returns mils correction per meter of height difference
  static double calculateSite(
    double heightDifference,
    double groundDistance,
  ) {
    if (groundDistance == 0) return 0.0;
    return heightDifference / groundDistance;
  }
  
  /// Apply height correction to elevation
  /// Formula: correctedElevation = elevation + (site * correctionFactor)
  static double applyCorrection(
    double elevation,
    double heightDifference,
    double groundDistance, {
    double correctionFactor = 1000.0,
  }) {
    if (groundDistance == 0) return elevation;
    
    final site = calculateSite(heightDifference, groundDistance);
    return elevation + (site * correctionFactor);
  }
  
  /// Calculate comprehensive height correction with adjusted TOF
  static HeightCorrectionResult calculate(
    double elevation,
    double timeOfFlight,
    double heightDifference,
    double groundDistance, {
    double correctionFactor = 1000.0,
  }) {
    final correctedElevation = applyCorrection(
      elevation,
      heightDifference,
      groundDistance,
      correctionFactor: correctionFactor,
    );
    
    // Adjust TOF slightly based on height
    // Higher targets take longer to reach, lower targets faster
    final heightFactor = 1 + (heightDifference / groundDistance) * 0.1;
    final correctedTOF = timeOfFlight * heightFactor;
    
    return HeightCorrectionResult(
      originalElevation: elevation,
      correctedElevation: correctedElevation,
      elevationChange: correctedElevation - elevation,
      originalTimeOfFlight: timeOfFlight,
      correctedTimeOfFlight: correctedTOF,
      site: calculateSite(heightDifference, groundDistance),
      isUpward: heightDifference > 0,
      isSignificant: heightDifference.abs() > 10, // More than 10m difference
    );
  }
  
  /// Get correction description
  static String getCorrectionDescription(
    double heightDifference,
    double groundDistance,
  ) {
    final site = calculateSite(heightDifference, groundDistance);
    final correction = site * 1000;
    
    if (heightDifference.abs() < 1) {
      return 'No height correction needed';
    }
    
    final direction = heightDifference > 0 ? 'UP' : 'DOWN';
    final magnitude = correction.abs();
    
    if (magnitude < 10) {
      return 'Minor $direction correction (${magnitude.toStringAsFixed(1)} mils)';
    } else if (magnitude < 50) {
      return 'Moderate $direction correction (${magnitude.toStringAsFixed(1)} mils)';
    } else {
      return 'Significant $direction correction (${magnitude.toStringAsFixed(1)} mils) - Verify target altitude';
    }
  }
  
  /// Check if height correction is needed
  static bool needsCorrection(double heightDifference, {double threshold = 5.0}) {
    return heightDifference.abs() >= threshold;
  }
  
  /// Estimate height from terrain profile
  /// This would integrate with heightmap data
  static double estimateTerrainHeight(
    Position position,
    Map<String, dynamic>? heightmap,
  ) {
    // Placeholder for heightmap integration
    // Would sample heightmap at position
    return position.altitude;
  }
  
  /// Calculate sight picture adjustment for spotters
  /// Returns mil adjustment for observer
  static double calculateObserverCorrection(
    Position observer,
    Position target,
    double targetHeight,
  ) {
    final groundDistance = calculateDistance2D(observer, target);
    final heightDiff = targetHeight - observer.altitude;
    
    return (heightDiff / groundDistance) * 1000;
  }
  
  static double calculateDistance2D(Position a, Position b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return (dx * dx + dy * dy);
  }
}

/// Result of height correction calculation
class HeightCorrectionResult {
  final double originalElevation;
  final double correctedElevation;
  final double elevationChange;
  final double originalTimeOfFlight;
  final double correctedTimeOfFlight;
  final double site;
  final bool isUpward;
  final bool isSignificant;
  
  const HeightCorrectionResult({
    required this.originalElevation,
    required this.correctedElevation,
    required this.elevationChange,
    required this.originalTimeOfFlight,
    required this.correctedTimeOfFlight,
    required this.site,
    required this.isUpward,
    required this.isSignificant,
  });
  
  String get direction => isUpward ? 'UP' : 'DOWN';
  
  String get formattedChange {
    final sign = elevationChange >= 0 ? '+' : '';
    return '$sign${elevationChange.toStringAsFixed(1)} mils';
  }
}
