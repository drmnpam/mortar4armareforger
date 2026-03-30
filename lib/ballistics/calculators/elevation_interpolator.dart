import 'dart:math';
import '../../models/models.dart';
import '../tables.dart';

/// Elevation interpolation utilities
class ElevationInterpolator {
  /// Interpolate elevation from ballistic table for given distance
  static BallisticRow interpolate(BallisticTable table, double distance) {
    final rows = table.table;
    if (rows.isEmpty) {
      throw Exception('Empty ballistic table');
    }

    // Find surrounding rows
    BallisticRow? lower;
    BallisticRow? upper;

    for (final row in rows) {
      if (row.range <= distance) {
        lower = row;
      }
      if (row.range >= distance && upper == null) {
        upper = row;
      }
    }

    // Handle edge cases
    if (lower == null) return rows.first;
    if (upper == null) return rows.last;
    if (lower == upper) return lower;

    // Linear interpolation
    final t = (distance - lower.range) / (upper.range - lower.range);

    return BallisticRow(
      range: distance,
      elevation: lower.elevation + t * (upper.elevation - lower.elevation),
      timeOfFlight: lower.timeOfFlight + t * (upper.timeOfFlight - lower.timeOfFlight),
    );
  }

  /// Cosine interpolation for smoother results
  static BallisticRow interpolateCosine(BallisticTable table, double distance) {
    final rows = table.table;
    if (rows.isEmpty) {
      throw Exception('Empty ballistic table');
    }

    // Find surrounding rows
    BallisticRow? lower;
    BallisticRow? upper;

    for (final row in rows) {
      if (row.range <= distance) {
        lower = row;
      }
      if (row.range >= distance && upper == null) {
        upper = row;
      }
    }

    // Handle edge cases
    if (lower == null) return rows.first;
    if (upper == null) return rows.last;
    if (lower == upper) return lower;

    // Cosine interpolation
    final t = (distance - lower.range) / (upper.range - lower.range);
    final cosineT = (1 - cos(t * pi)) / 2;

    return BallisticRow(
      range: distance,
      elevation: lower.elevation + cosineT * (upper.elevation - lower.elevation),
      timeOfFlight: lower.timeOfFlight + cosineT * (upper.timeOfFlight - lower.timeOfFlight),
    );
  }
}
