import 'dart:math';
import '../../models/models.dart';
import '../calculators/azimuth_calculator.dart';
import '../calculators/distance_calculator.dart';

/// Shot correction system
/// Handles ADD/DROP (range) and LEFT/RIGHT (deflection) corrections
class ShotCorrector {
  /// Correction factors - how much elevation change affects range
  /// These are approximate values based on ballistic curves
  static const double elevationToRangeFactor = 0.5; // meters per mil
  static const double milsPerMeterRange = 2.0; // mils needed per meter of range correction
  
  /// Apply shot correction to existing solution
  static ShotCorrectionResult applyCorrection({
    required FiringSolution originalSolution,
    required Position mortarPosition,
    required Position targetPosition,
    double? addMeters,      // Positive = add (increase range)
    double? dropMeters,     // Positive = drop (decrease range)
    double? leftMils,       // Positive = left (decrease azimuth)
    double? rightMils,      // Positive = right (increase azimuth)
    String? observerNotes,  // Text notes from forward observer
  }) {
    double elevationChange = 0;
    double azimuthChange = 0;
    
    // Calculate range correction (ADD/DROP)
    final rangeCorrection = (addMeters ?? 0) - (dropMeters ?? 0);
    if (rangeCorrection != 0) {
      elevationChange = rangeCorrection * milsPerMeterRange;
    }
    
    // Calculate deflection correction (LEFT/RIGHT)
    final deflection = (rightMils ?? 0) - (leftMils ?? 0);
    azimuthChange = deflection;
    
    // Calculate new values
    final newElevation = originalSolution.elevation + elevationChange;
    final newAzimuth = AzimuthCalculator.addOffset(
      originalSolution.azimuth,
      azimuthChange,
    );
    
    // Calculate approximate new impact point
    // This is a simplified calculation for display purposes
    final distance = DistanceCalculator.calculateDistance(
      mortarPosition,
      targetPosition,
    );
    final newDistance = distance + rangeCorrection;
    
    // Calculate new impact position
    final newImpact = _calculateNewImpact(
      mortarPosition,
      targetPosition,
      newAzimuth,
      newDistance,
    );
    
    return ShotCorrectionResult(
      originalSolution: originalSolution,
      newElevation: newElevation,
      newAzimuth: newAzimuth,
      elevationChange: elevationChange,
      azimuthChange: azimuthChange,
      rangeCorrection: rangeCorrection,
      newImpactPosition: newImpact,
      correctionDescription: _buildDescription(
        addMeters: addMeters,
        dropMeters: dropMeters,
        leftMils: leftMils,
        rightMils: rightMils,
      ),
      observerNotes: observerNotes,
    );
  }
  
  /// Build correction from observer call
  /// Standard format: "DROP 50, ADD 20, RIGHT 30, LEFT 10"
  static ShotCorrectionResult? parseObserverCall({
    required FiringSolution solution,
    required Position mortar,
    required Position target,
    required String call,
  }) {
    double? addMeters;
    double? dropMeters;
    double? leftMils;
    double? rightMils;
    
    // Normalize and split
    final normalized = call.toUpperCase().replaceAll(',', ' ');
    final parts = normalized.split(RegExp(r'\s+'));
    
    for (int i = 0; i < parts.length - 1; i++) {
      final command = parts[i];
      final value = double.tryParse(parts[i + 1]);
      
      if (value == null) continue;
      
      switch (command) {
        case 'ADD':
        case 'UP':
          addMeters = value;
          break;
        case 'DROP':
        case 'DOWN':
          dropMeters = value;
          break;
        case 'LEFT':
          leftMils = value;
          break;
        case 'RIGHT':
          rightMils = value;
          break;
      }
    }
    
    if (addMeters == null && dropMeters == null &&
        leftMils == null && rightMils == null) {
      return null;
    }
    
    return applyCorrection(
      originalSolution: solution,
      mortarPosition: mortar,
      targetPosition: target,
      addMeters: addMeters,
      dropMeters: dropMeters,
      leftMils: leftMils,
      rightMils: rightMils,
    );
  }
  
  /// Calculate new impact position based on corrected azimuth and range
  static Position _calculateNewImpact(
    Position mortar,
    Position originalTarget,
    double newAzimuth,
    double newDistance,
  ) {
    // Convert azimuth from mils to radians
    // Arma: 0 mils = North, increases clockwise
    final azimuthRad = newAzimuth / AzimuthCalculator.radiansToMils;
    
    // Calculate displacement from mortar
    // In Arma: X is East, Y is North
    // sin(azimuth) gives East component
    // cos(azimuth) gives North component
    final dx = sin(azimuthRad) * newDistance;
    final dy = cos(azimuthRad) * newDistance;
    
    return Position(
      x: mortar.x + dx,
      y: mortar.y + dy,
      altitude: originalTarget.altitude,
    );
  }
  
  /// Build human-readable correction description
  static String _buildDescription({
    double? addMeters,
    double? dropMeters,
    double? leftMils,
    double? rightMils,
  }) {
    final parts = <String>[];
    
    if (addMeters != null && addMeters > 0) {
      parts.add('ADD ${addMeters.toStringAsFixed(0)}m');
    }
    if (dropMeters != null && dropMeters > 0) {
      parts.add('DROP ${dropMeters.toStringAsFixed(0)}m');
    }
    if (leftMils != null && leftMils > 0) {
      parts.add('LEFT ${leftMils.toStringAsFixed(0)} mils');
    }
    if (rightMils != null && rightMils > 0) {
      parts.add('RIGHT ${rightMils.toStringAsFixed(0)} mils');
    }
    
    return parts.join(', ');
  }
  
  /// Estimate correction needed based on impact vs target
  static ShotCorrectionResult estimateCorrection({
    required FiringSolution originalSolution,
    required Position mortar,
    required Position intendedTarget,
    required Position actualImpact,
  }) {
    final distance = DistanceCalculator.calculateDistance(mortar, actualImpact);
    final targetDistance = DistanceCalculator.calculateDistance(
      mortar,
      intendedTarget,
    );
    final rangeDiff = distance - targetDistance;
    
    final azimuth = AzimuthCalculator.calculateAzimuth(mortar, actualImpact);
    final targetAzimuth = AzimuthCalculator.calculateAzimuth(
      mortar,
      intendedTarget,
    );
    final deflection = AzimuthCalculator.calculateDeflection(
      targetAzimuth,
      azimuth,
    );
    
    return applyCorrection(
      originalSolution: originalSolution,
      mortarPosition: mortar,
      targetPosition: intendedTarget,
      addMeters: rangeDiff < 0 ? -rangeDiff : null,
      dropMeters: rangeDiff > 0 ? rangeDiff : null,
      leftMils: deflection < 0 ? -deflection : null,
      rightMils: deflection > 0 ? deflection : null,
    );
  }
  
  /// Convert correction to clipboard format
  static String formatForClipboard(ShotCorrectionResult correction) {
    return '''SHOT CORRECTION
AZ: ${AzimuthCalculator.format(correction.newAzimuth)}
EL: ${correction.newElevation.toStringAsFixed(1)}
${correction.correctionDescription}''';
  }
}

/// Result of shot correction calculation
class ShotCorrectionResult {
  final FiringSolution originalSolution;
  final double newElevation;
  final double newAzimuth;
  final double elevationChange;
  final double azimuthChange;
  final double rangeCorrection;
  final Position newImpactPosition;
  final String correctionDescription;
  final String? observerNotes;
  
  const ShotCorrectionResult({
    required this.originalSolution,
    required this.newElevation,
    required this.newAzimuth,
    required this.elevationChange,
    required this.azimuthChange,
    required this.rangeCorrection,
    required this.newImpactPosition,
    required this.correctionDescription,
    this.observerNotes,
  });
  
  bool get isValid => newElevation > 0 && newElevation < 1600;
  
  String get formattedElevationChange {
    final sign = elevationChange >= 0 ? '+' : '';
    return '$sign${elevationChange.toStringAsFixed(1)} mils';
  }
  
  String get formattedAzimuthChange {
    final sign = azimuthChange >= 0 ? 'R ' : 'L ';
    return '$sign${azimuthChange.abs().toStringAsFixed(0)} mils';
  }
  
  /// Check if correction is within reasonable bounds
  bool get isReasonable {
    return elevationChange.abs() < 500 && // Max 500 mils elevation change
           azimuthChange.abs() < 800;    // Max half circle
  }
}
