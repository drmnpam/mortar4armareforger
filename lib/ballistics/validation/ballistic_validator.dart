import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../calculators/distance_calculator.dart';
import '../calculators/azimuth_calculator.dart';
import '../calculators/elevation_interpolator.dart';
import '../calculators/height_corrector.dart';
import '../tables.dart';

/// Ballistic validation and testing utilities
class BallisticValidator {
  /// Run all validation tests
  static ValidationReport runAllTests() {
    final tests = <ValidationTest>[];
    
    tests.add(_testDistanceFormula());
    tests.add(_testAzimuthFormula());
    tests.add(_testElevationInterpolation());
    tests.add(_testHeightCorrection());
    tests.add(_testBallisticTables());
    tests.add(_testSlantRange());
    
    final passed = tests.where((t) => t.passed).length;
    final failed = tests.where((t) => !t.passed).length;
    
    return ValidationReport(
      tests: tests,
      totalTests: tests.length,
      passed: passed,
      failed: failed,
    );
  }
  
  /// Test distance formula with known values
  static ValidationTest _testDistanceFormula() {
    // Known: 3-4-5 triangle
    final p1 = const Position(x: 0, y: 0);
    final p2 = const Position(x: 300, y: 400);
    final dist = DistanceCalculator.calculateDistance(p1, p2);
    final expected = 500.0; // 300-400-500 triangle
    
    final diff = (dist - expected).abs();
    final passed = diff < 0.001;
    
    return ValidationTest(
      name: 'Distance Formula (3-4-5 triangle)',
      passed: passed,
      expected: expected.toStringAsFixed(1),
      actual: dist.toStringAsFixed(1),
      error: passed ? null : 'Difference: ${diff.toStringAsFixed(3)}m',
    );
  }
  
  /// Test azimuth formula with known values
  static ValidationTest _testAzimuthFormula() {
    // Test North (0 mils) - Y increases, X same
    final north = AzimuthCalculator.calculateAzimuth(
      const Position(x: 0, y: 0),
      const Position(x: 0, y: 100),
    );
    
    // Test East (1600 mils) - X increases, Y same  
    final east = AzimuthCalculator.calculateAzimuth(
      const Position(x: 0, y: 0),
      const Position(x: 100, y: 0),
    );
    
    // Test South (3200 mils)
    final south = AzimuthCalculator.calculateAzimuth(
      const Position(x: 0, y: 100),
      const Position(x: 0, y: 0),
    );
    
    // Test West (4800 mils)
    final west = AzimuthCalculator.calculateAzimuth(
      const Position(x: 100, y: 0),
      const Position(x: 0, y: 0),
    );
    
    final northError = (north - 0).abs();
    final eastError = (east - 1600).abs();
    final southError = (south - 3200).abs();
    final westError = (west - 4800).abs();
    
    final passed = northError < 1 && eastError < 1 && 
                   southError < 1 && westError < 1;
    
    return ValidationTest(
      name: 'Azimuth Cardinal Directions',
      passed: passed,
      expected: 'N:0, E:1600, S:3200, W:4800',
      actual: 'N:${north.toStringAsFixed(0)}, '
              'E:${east.toStringAsFixed(0)}, '
              'S:${south.toStringAsFixed(0)}, '
              'W:${west.toStringAsFixed(0)}',
      error: passed ? null : 'North: ${northError.toStringAsFixed(1)} mils error',
    );
  }
  
  /// Test elevation interpolation
  static ValidationTest _testElevationInterpolation() {
    BallisticTables.initialize();
    final tables = BallisticTables.getTables('M252');
    
    if (tables.isEmpty) {
      return ValidationTest(
        name: 'Elevation Interpolation',
        passed: false,
        expected: 'Tables available',
        actual: 'No tables found',
        error: 'M252 tables not loaded',
      );
    }
    
    final table = tables.first;
    final midRange = (table.minRange + table.maxRange) / 2;
    
    final row = ElevationInterpolator.interpolate(table, midRange);
    
    // Check that elevation is within table bounds
    final elevations = table.table.map((r) => r.elevation).toList();
    final minEl = elevations.reduce((a, b) => a < b ? a : b);
    final maxEl = elevations.reduce((a, b) => a > b ? a : b);
    
    final passed = row.elevation >= minEl - 100 && row.elevation <= maxEl + 100;
    
    return ValidationTest(
      name: 'Elevation Interpolation',
      passed: passed,
      expected: 'Between $minEl and $maxEl mils',
      actual: '${row.elevation.toStringAsFixed(1)} mils',
      error: passed ? null : 'Outside expected range',
    );
  }
  
  /// Test height correction
  static ValidationTest _testHeightCorrection() {
    // Target 100m higher, 1000m away
    const heightDiff = 100.0;
    const distance = 1000.0;
    const baseElevation = 800.0;
    
    final result = HeightCorrector.calculate(
      baseElevation,
      30.0, // TOF
      heightDiff,
      distance,
    );
    
    // Site = 100/1000 = 0.1, correction = 0.1 * 1000 = 100 mils
    const expectedCorrection = 100.0;
    final diff = (result.elevationChange - expectedCorrection).abs();
    final passed = diff < 5; // Within 5 mils
    
    return ValidationTest(
      name: 'Height Correction',
      passed: passed,
      expected: '+$expectedCorrection mils',
      actual: result.formattedChange,
      error: passed ? null : 'Correction error: ${diff.toStringAsFixed(1)} mils',
    );
  }
  
  /// Validate ballistic table consistency
  static ValidationTest _testBallisticTables() {
    BallisticTables.initialize();
    final issues = <String>[];
    
    for (final mortar in BallisticTables.availableMortars) {
      final tables = BallisticTables.getTables(mortar);
      
      for (int i = 0; i < tables.length; i++) {
        final table = tables[i];
        
        // Check ranges are sorted
        for (int j = 1; j < table.table.length; j++) {
          if (table.table[j].range <= table.table[j - 1].range) {
            issues.add('$mortar CH${table.charge}: Range not sorted at row $j');
          }
        }
        
        // Check elevation decreases with range (typical for mortars)
        int decreasing = 0;
        for (int j = 1; j < table.table.length; j++) {
          if (table.table[j].elevation < table.table[j - 1].elevation) {
            decreasing++;
          }
        }
        
        if (decreasing < table.table.length ~/ 2) {
          issues.add('$mortar CH${table.charge}: Elevation trend unusual');
        }
        
        // Check TOF increases with range
        for (int j = 1; j < table.table.length; j++) {
          if (table.table[j].timeOfFlight < table.table[j - 1].timeOfFlight) {
            issues.add('$mortar CH${table.charge}: TOF decreases at row $j');
          }
        }
      }
    }
    
    return ValidationTest(
      name: 'Ballistic Table Consistency',
      passed: issues.isEmpty,
      expected: 'No issues',
      actual: issues.isEmpty ? 'Valid' : '${issues.length} issues',
      error: issues.isEmpty ? null : issues.take(3).join('; '),
    );
  }
  
  /// Test slant range calculation
  static ValidationTest _testSlantRange() {
    // Horizontal distance 1000m, height diff 0
    final flat = DistanceCalculator.calculateSlantRange(
      const Position(x: 0, y: 0, altitude: 0),
      const Position(x: 1000, y: 0, altitude: 0),
    );
    
    // Height diff 100m, horizontal 1000m
    final elevated = DistanceCalculator.calculateSlantRange(
      const Position(x: 0, y: 0, altitude: 0),
      const Position(x: 1000, y: 0, altitude: 100),
    );
    
    // Slant should be longer
    final passed = elevated > flat && 
                   (elevated - flat).abs() < 10; // Close to 5m more
    
    return ValidationTest(
      name: 'Slant Range Calculation',
      passed: passed,
      expected: 'Elevated > Flat',
      actual: 'Flat: ${flat.toStringAsFixed(1)}m, Elev: ${elevated.toStringAsFixed(1)}m',
      error: passed ? null : 'Slant range calculation error',
    );
  }
  
  /// Validate against known Arma 3/Reforger data points
  static List<ValidationTest> validateAgainstGameData() {
    // Known data points from Arma (example values)
    final knownPoints = [
      // (distance, charge, expected elevation range)
      _KnownPoint(mortar: 'M252', distance: 500, charge: 0, 
                  minElevation: 1300, maxElevation: 1400),
      _KnownPoint(mortar: 'M252', distance: 1000, charge: 1,
                  minElevation: 1150, maxElevation: 1250),
      _KnownPoint(mortar: 'M252', distance: 2000, charge: 2,
                  minElevation: 850, maxElevation: 950),
    ];
    
    final tests = <ValidationTest>[];
    
    for (final point in knownPoints) {
      final table = BallisticTables.getTable(point.mortar, point.charge);
      if (table == null) continue;
      
      final row = ElevationInterpolator.interpolate(table, point.distance);
      final passed = row.elevation >= point.minElevation && 
                     row.elevation <= point.maxElevation;
      
      tests.add(ValidationTest(
        name: '${point.mortar} CH${point.charge} @ ${point.distance}m',
        passed: passed,
        expected: '${point.minElevation}-${point.maxElevation} mils',
        actual: '${row.elevation.toStringAsFixed(1)} mils',
        error: passed ? null : 'Outside expected range',
      ));
    }
    
    return tests;
  }
}

/// Single validation test result
class ValidationTest {
  final String name;
  final bool passed;
  final String expected;
  final String actual;
  final String? error;
  
  const ValidationTest({
    required this.name,
    required this.passed,
    required this.expected,
    required this.actual,
    this.error,
  });
}

/// Complete validation report
class ValidationReport {
  final List<ValidationTest> tests;
  final int totalTests;
  final int passed;
  final int failed;
  
  const ValidationReport({
    required this.tests,
    required this.totalTests,
    required this.passed,
    required this.failed,
  });
  
  bool get allPassed => failed == 0;
  double get passRate => totalTests > 0 ? passed / totalTests : 0;
  
  String get summary {
    return 'Passed: $passed/$totalTests (${(passRate * 100).toStringAsFixed(0)}%)';
  }
}

class _KnownPoint {
  final String mortar;
  final double distance;
  final int charge;
  final double minElevation;
  final double maxElevation;
  
  const _KnownPoint({
    required this.mortar,
    required this.distance,
    required this.charge,
    required this.minElevation,
    required this.maxElevation,
  });
}
