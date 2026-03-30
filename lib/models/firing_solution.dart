import 'package:equatable/equatable.dart';

/// Represents a calculated firing solution
class FiringSolution extends Equatable {
  final double distance;
  final double azimuth;
  final double elevation;
  final int charge;
  final double timeOfFlight;
  final double heightDifference;
  final String mortarType;
  final String? correction;
  final bool heightAdjusted;

  const FiringSolution({
    required this.distance,
    required this.azimuth,
    required this.elevation,
    required this.charge,
    required this.timeOfFlight,
    required this.heightDifference,
    required this.mortarType,
    this.correction,
    this.heightAdjusted = false,
  });

  /// Create a copy with modified values
  FiringSolution copyWith({
    double? distance,
    double? azimuth,
    double? elevation,
    int? charge,
    double? timeOfFlight,
    double? heightDifference,
    String? mortarType,
    String? correction,
    bool? heightAdjusted,
  }) {
    return FiringSolution(
      distance: distance ?? this.distance,
      azimuth: azimuth ?? this.azimuth,
      elevation: elevation ?? this.elevation,
      charge: charge ?? this.charge,
      timeOfFlight: timeOfFlight ?? this.timeOfFlight,
      heightDifference: heightDifference ?? this.heightDifference,
      mortarType: mortarType ?? this.mortarType,
      correction: correction ?? this.correction,
      heightAdjusted: heightAdjusted ?? this.heightAdjusted,
    );
  }

  /// Display getters
  String get azimuthDisplay => azimuth.round().toString().padLeft(4, '0');
  String get azimuthDegreesDisplay {
    final degrees = azimuth * 0.05625;
    return degrees.toStringAsFixed(1);
  }
  String get elevationDisplay => elevation.toStringAsFixed(1);
  String get distanceDisplay => '${distance.round()}m';
  String get timeOfFlightDisplay => '${timeOfFlight.toStringAsFixed(1)}s';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'distance': distance,
    'azimuth': azimuth,
    'elevation': elevation,
    'charge': charge,
    'timeOfFlight': timeOfFlight,
    'heightDifference': heightDifference,
    'mortarType': mortarType,
    'correction': correction,
    'heightAdjusted': heightAdjusted,
  };

  /// Create from JSON
  factory FiringSolution.fromJson(Map<String, dynamic> json) {
    return FiringSolution(
      distance: (json['distance'] as num).toDouble(),
      azimuth: (json['azimuth'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      charge: json['charge'] as int,
      timeOfFlight: (json['timeOfFlight'] as num).toDouble(),
      heightDifference: (json['heightDifference'] as num).toDouble(),
      mortarType: json['mortarType'] as String,
      correction: json['correction'] as String?,
      heightAdjusted: json['heightAdjusted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [distance, azimuth, elevation, charge, timeOfFlight, heightDifference, mortarType, correction, heightAdjusted];

  @override
  String toString() => 'FiringSolution(az: $azimuth, el: $elevation, ch: $charge)';
}
