import '../../models/models.dart';
import 'distance_calculator.dart';
import 'azimuth_calculator.dart';
import 'charge_selector.dart';
import 'elevation_interpolator.dart';
import 'height_corrector.dart';
import 'time_of_flight_calculator.dart';
import '../tables.dart';

/// Refactored ballistic solver using dedicated calculators
class RefactoredBallisticSolver {
  /// Calculate complete firing solution
  static FiringSolution calculate({
    required Position mortarPosition,
    required Position targetPosition,
    required String mortarType,
    int? preferredCharge,
    bool autoSelectCharge = true,
  }) {
    // Step 1: Calculate distance
    final distance = DistanceCalculator.calculateDistance(
      mortarPosition,
      targetPosition,
    );
    
    // Step 2: Calculate azimuth
    final azimuth = AzimuthCalculator.calculateAzimuth(
      mortarPosition,
      targetPosition,
    );
    
    // Step 3: Calculate height difference
    final heightDifference = targetPosition.altitude - mortarPosition.altitude;
    
    // Step 4: Select charge
    final charge = autoSelectCharge && preferredCharge == null
        ? ChargeSelector.selectOptimalCharge(mortarType, distance)
        : preferredCharge ?? 0;
    
    // Validate charge
    if (!ChargeSelector.canReach(mortarType, charge, distance)) {
      throw BallisticSolverException(
        'Charge $charge cannot reach target at ${distance.toStringAsFixed(0)}m'
      );
    }
    
    // Step 5: Get ballistic table
    final table = BallisticTables.getTable(mortarType, charge);
    if (table == null) {
      throw BallisticSolverException('No ballistic table for $mortarType charge $charge');
    }
    
    // Step 6: Interpolate elevation
    final row = ElevationInterpolator.interpolate(table, distance);
    
    // Step 7: Apply height correction
    final heightResult = HeightCorrector.calculate(
      row.elevation,
      row.timeOfFlight,
      heightDifference,
      distance,
    );
    
    // Step 8: Calculate TOF
    final tof = TimeOfFlightCalculator.calculate(
      mortarType,
      charge,
      distance,
      heightDifference,
    );
    
    // Step 9: Generate corrections
    final correction = _generateCorrection(distance, heightDifference, heightResult);
    
    return FiringSolution(
      distance: distance,
      azimuth: azimuth,
      elevation: heightResult.correctedElevation,
      charge: charge,
      timeOfFlight: tof,
      heightDifference: heightDifference,
      correction: correction,
      mortarType: mortarType,
      heightAdjusted: heightResult.isSignificant,
    );
  }
  
  /// Calculate all possible solutions for comparison
  static List<FiringSolution> calculateAllOptions({
    required Position mortarPosition,
    required Position targetPosition,
    required String mortarType,
  }) {
    final solutions = <FiringSolution>[];
    final tables = BallisticTables.getTables(mortarType);
    
    final distance = DistanceCalculator.calculateDistance(
      mortarPosition,
      targetPosition,
    );
    final azimuth = AzimuthCalculator.calculateAzimuth(
      mortarPosition,
      targetPosition,
    );
    final heightDifference = targetPosition.altitude - mortarPosition.altitude;
    
    for (final table in tables) {
      if (distance < table.minRange || distance > table.maxRange * 1.05) {
        continue;
      }
      
      final row = ElevationInterpolator.interpolate(table, distance);
      final heightResult = HeightCorrector.calculate(
        row.elevation,
        row.timeOfFlight,
        heightDifference,
        distance,
      );
      
      final tof = TimeOfFlightCalculator.calculate(
        mortarType,
        table.charge,
        distance,
        heightDifference,
      );
      
      solutions.add(FiringSolution(
        distance: distance,
        azimuth: azimuth,
        elevation: heightResult.correctedElevation,
        charge: table.charge,
        timeOfFlight: tof,
        heightDifference: heightDifference,
        correction: null,
        mortarType: mortarType,
        heightAdjusted: heightResult.isSignificant,
      ));
    }
    
    return solutions;
  }
  
  /// Quick calculation for map mode
  static FiringSolution? calculateQuick({
    required Position mortar,
    required Position target,
    required String mortarType,
  }) {
    try {
      return calculate(
        mortarPosition: mortar,
        targetPosition: target,
        mortarType: mortarType,
        autoSelectCharge: true,
      );
    } on BallisticSolverException {
      return null;
    }
  }
  
  /// Generate correction advice
  static String? _generateCorrection(
    double distance,
    double heightDifference,
    HeightCorrectionResult heightResult,
  ) {
    final List<String> hints = [];
    
    if (heightResult.isSignificant) {
      hints.add('HEIGHT ${heightResult.direction}: ${heightResult.formattedChange}');
    }
    
    if (distance < 200) {
      hints.add('DANGER CLOSE');
    } else if (distance > 3500) {
      hints.add('MAX RANGE');
    }
    
    return hints.isEmpty ? null : hints.join(' | ');
  }
}

class BallisticSolverException implements Exception {
  final String message;
  BallisticSolverException(this.message);
  @override
  String toString() => 'BallisticSolverException: $message';
}
