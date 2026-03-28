import '../models/models.dart';
import 'formulas.dart';
import 'tables.dart';
import 'interpolation.dart';

/// Main ballistic solver
class BallisticSolver {
  /// Calculate complete firing solution
  /// 
  /// Parameters:
  /// - mortarPosition: Position of the mortar
  /// - targetPosition: Position of the target  
  /// - mortarType: Type of mortar (e.g., "M252")
  /// - preferredCharge: Specific charge to use, or null for auto-selection
  static FiringSolution calculate({
    required Position mortarPosition,
    required Position targetPosition,
    required String mortarType,
    int? preferredCharge,
  }) {
    // Ensure tables are loaded
    BallisticTables.initialize();

    // Step 1: Calculate distance
    final distance = BallisticFormulas.calculateDistance(mortarPosition, targetPosition);
    
    // Step 2: Calculate azimuth
    final azimuth = BallisticFormulas.calculateAzimuth(mortarPosition, targetPosition);
    
    // Step 3: Calculate height difference
    final heightDifference = BallisticFormulas.calculateHeightDifference(mortarPosition, targetPosition);
    
    // Step 4: Select charge
    final charge = preferredCharge ?? BallisticTables.selectCharge(mortarType, distance);
    
    // Step 5: Get ballistic table
    final table = BallisticTables.getTable(mortarType, charge);
    if (table == null) {
      throw BallisticException(
        'No ballistic table found for $mortarType charge $charge'
      );
    }
    
    // Step 6: Interpolate elevation and TOF
    final row = BallisticInterpolator.interpolate(table, distance, extrapolate: true);
    if (row == null) {
      throw BallisticException(
        'Target distance $distance is out of range for $mortarType charge $charge'
      );
    }
    
    // Step 7: Apply height correction
    final elevation = BallisticFormulas.applyHeightCorrection(
      row.elevation,
      heightDifference,
      distance,
    );
    
    // Step 8: Generate correction hint if needed
    final correction = _generateCorrection(distance, heightDifference, elevation);
    
    return FiringSolution(
      distance: distance,
      azimuth: azimuth,
      elevation: elevation,
      charge: charge,
      timeOfFlight: row.timeOfFlight,
      heightDifference: heightDifference,
      correction: correction,
      mortarType: mortarType,
      heightAdjusted: heightDifference.abs() > 1.0,
    );
  }

  /// Validate if a firing solution is achievable
  static bool isValidSolution(
    Position mortarPosition,
    Position targetPosition,
    String mortarType, {
    int? charge,
    double? maxElevation,
    double? minElevation,
  }) {
    try {
      final solution = calculate(
        mortarPosition: mortarPosition,
        targetPosition: targetPosition,
        mortarType: mortarType,
        preferredCharge: charge,
      );
      
      if (maxElevation != null && solution.elevation > maxElevation) {
        return false;
      }
      if (minElevation != null && solution.elevation < minElevation) {
        return false;
      }
      
      return true;
    } on BallisticException {
      return false;
    }
  }

  /// Find optimal charge for best trajectory (flattest/lowest elevation)
  static int findOptimalCharge(
    Position mortarPosition,
    Position targetPosition,
    String mortarType,
  ) {
    final distance = BallisticFormulas.calculateDistance(mortarPosition, targetPosition);
    final tables = BallisticTables.getTables(mortarType);
    
    int? bestCharge;
    double? lowestElevation;
    
    for (final table in tables) {
      if (!BallisticTables.canUseCharge(mortarType, table.charge, distance)) {
        continue;
      }
      
      final row = BallisticInterpolator.interpolate(table, distance);
      if (row != null) {
        if (lowestElevation == null || row.elevation < lowestElevation) {
          lowestElevation = row.elevation;
          bestCharge = table.charge;
        }
      }
    }
    
    return bestCharge ?? tables.firstOrNull?.charge ?? 0;
  }

  /// Calculate multiple solutions for different charges
  static List<FiringSolution> calculateAllCharges({
    required Position mortarPosition,
    required Position targetPosition,
    required String mortarType,
  }) {
    final solutions = <FiringSolution>[];
    final tables = BallisticTables.getTables(mortarType);
    final distance = BallisticFormulas.calculateDistance(mortarPosition, targetPosition);
    final heightDifference = BallisticFormulas.calculateHeightDifference(mortarPosition, targetPosition);
    final azimuth = BallisticFormulas.calculateAzimuth(mortarPosition, targetPosition);
    
    for (final table in tables) {
      final row = BallisticInterpolator.interpolate(table, distance, extrapolate: true);
      if (row != null) {
        final elevation = BallisticFormulas.applyHeightCorrection(
          row.elevation,
          heightDifference,
          distance,
        );
        
        solutions.add(FiringSolution(
          distance: distance,
          azimuth: azimuth,
          elevation: elevation,
          charge: table.charge,
          timeOfFlight: row.timeOfFlight,
          heightDifference: heightDifference,
          correction: null,
          mortarType: mortarType,
          heightAdjusted: heightDifference.abs() > 1.0,
        ));
      }
    }
    
    return solutions;
  }

  /// Generate correction suggestion based on conditions
  static String? _generateCorrection(
    double distance,
    double heightDifference,
    double elevation,
  ) {
    final List<String> hints = [];
    
    // Height correction hint
    if (heightDifference > 50) {
      hints.add('TARGET ELEVATED - ADJUST UP');
    } else if (heightDifference < -50) {
      hints.add('TARGET BELOW - ADJUST DOWN');
    }
    
    // Elevation warning
    if (elevation > 1500) {
      hints.add('HIGH ANGLE - CHECK CLEARANCE');
    } else if (elevation < 200) {
      hints.add('LOW ANGLE - DANGER CLOSE');
    }
    
    // Distance warning
    if (distance < 200) {
      hints.add('DANGER CLOSE - MINIMUM RANGE');
    }
    
    return hints.isEmpty ? null : hints.join(' | ');
  }

  /// Validate table data integrity
  static bool validateTable(BallisticTable table) {
    if (table.table.isEmpty) return false;
    
    // Check ranges are sorted
    for (int i = 1; i < table.table.length; i++) {
      if (table.table[i].range <= table.table[i - 1].range) {
        return false;
      }
    }
    
    // Check elevation decreases as range increases (typical for mortars)
    // This is a sanity check - real data may vary
    int decreasingCount = 0;
    for (int i = 1; i < table.table.length; i++) {
      if (table.table[i].elevation < table.table[i - 1].elevation) {
        decreasingCount++;
      }
    }
    
    // Most rows should show decreasing elevation
    return decreasingCount >= table.table.length ~/ 2;
  }
}

/// Exception for ballistic calculation errors
class BallisticException implements Exception {
  final String message;
  
  BallisticException(this.message);
  
  @override
  String toString() => 'BallisticException: $message';
}
