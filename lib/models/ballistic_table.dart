import 'package:equatable/equatable.dart';
import 'ballistic_row.dart';

/// Ballistic table for a specific mortar and charge
class BallisticTable extends Equatable {
  /// Mortar type identifier (e.g., "M252", "2B14")
  final String mortar;
  
  /// Charge number
  final int charge;
  
  /// List of ballistic data rows sorted by range
  final List<BallisticRow> table;
  
  /// Minimum effective range for this charge
  double get minRange => table.first.range;
  
  /// Maximum effective range for this charge
  double get maxRange => table.last.range;

  const BallisticTable({
    required this.mortar,
    required this.charge,
    required this.table,
  });

  /// Find the row with closest range less than or equal to target
  BallisticRow? findLowerBound(double range) {
    for (int i = table.length - 1; i >= 0; i--) {
      if (table[i].range <= range) return table[i];
    }
    return null;
  }

  /// Find the row with closest range greater than target
  BallisticRow? findUpperBound(double range) {
    for (final row in table) {
      if (row.range >= range) return row;
    }
    return null;
  }

  /// Find index of closest range
  int findClosestIndex(double range) {
    int closest = 0;
    double minDiff = double.infinity;
    
    for (int i = 0; i < table.length; i++) {
      final diff = (table[i].range - range).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    
    return closest;
  }

  factory BallisticTable.fromJson(Map<String, dynamic> json) {
    return BallisticTable(
      mortar: json['mortar'] as String,
      charge: json['charge'] as int,
      table: (json['table'] as List)
          .map((e) => BallisticRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'mortar': mortar,
    'charge': charge,
    'table': table.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [mortar, charge, table];

  @override
  String toString() => 'BallisticTable($mortar, charge $charge, ${table.length} rows)';
}
