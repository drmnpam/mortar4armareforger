import 'package:equatable/equatable.dart';

/// Represents a 2D position with altitude
class Position extends Equatable {
  final double x;
  final double y;
  final double altitude;

  const Position({
    required this.x,
    required this.y,
    this.altitude = 0.0,
  });

  /// Create from map coordinates (e.g., grid reference)
  factory Position.fromMap(double x, double y, {double altitude = 0.0}) {
    return Position(x: x, y: y, altitude: altitude);
  }

  /// Create a copy with modified values
  Position copyWith({
    double? x,
    double? y,
    double? altitude,
  }) {
    return Position(
      x: x ?? this.x,
      y: y ?? this.y,
      altitude: altitude ?? this.altitude,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'altitude': altitude,
  };

  /// Create from JSON
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Format as grid reference string (e.g., "0123 0456")
  String toGridReference({int precision = 3}) {
    final xStr = x.toInt().toString().padLeft(precision * 2, '0');
    final yStr = y.toInt().toString().padLeft(precision * 2, '0');
    final split = precision;
    return '${xStr.substring(0, split)} ${xStr.substring(split)} ${yStr.substring(0, split)} ${yStr.substring(split)}';
  }

  @override
  List<Object?> get props => [x, y, altitude];

  @override
  String toString() => 'Position(x: $x, y: $y, alt: $altitude)';
}
