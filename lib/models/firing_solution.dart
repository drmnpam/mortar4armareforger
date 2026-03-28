import 'package:equatable/equatable.dart';

/// Complete firing solution for mortar
class FiringSolution extends Equatable {
  /// Distance to target in meters
  final double distance;
  
  /// Azimuth in mils (0-6400)
  final double azimuth;
  
  /// Elevation in mils
  final double elevation;
  
  /// Charge number (0-3 typically)
  final int charge;
  
  /// Time of flight in seconds
  final double timeOfFlight;
  
  /// Height difference between mortar and target (positive = target higher)
  final double heightDifference;
  
  /// Suggested correction if needed
  final String? correction;
  
  /// Mortar type used for calculation
  final String mortarType;
  
  /// Whether elevation was adjusted for height
  final bool heightAdjusted;

  const FiringSolution({
    required this.distance,
    required this.azimuth,
    required this.elevation,
    required this.charge,
    required this.timeOfFlight,
    required this.heightDifference,
    this.correction,
    required this.mortarType,
    this.heightAdjusted = false,
  });

  /// Azimuth formatted as string with direction
  String get azimuthDisplay {
    final mils = azimuth.round();
    return mils.toString().padLeft(4, '0');
  }

  /// Elevation formatted as string
  String get elevationDisplay {
    return elevation.toStringAsFixed(1);
  }

  /// Distance formatted as string
  String get distanceDisplay {
    return '${distance.toStringAsFixed(0)}m';
  }

  /// Time of flight formatted
  String get timeOfFlightDisplay {
    return '${timeOfFlight.toStringAsFixed(1)}s';
  }

  /// Format for copying to clipboard
  String get clipboardFormat {
    return 'AZ: $azimuthDisplay | EL: $elevationDisplay | CH: $charge | DST: $distanceDisplay';
  }

  /// Create a copy with modified values
  FiringSolution copyWith({
    double? distance,
    double? azimuth,
    double? elevation,
    int? charge,
    double? timeOfFlight,
    double? heightDifference,
    String? correction,
    String? mortarType,
    bool? heightAdjusted,
  }) {
    return FiringSolution(
      distance: distance ?? this.distance,
      azimuth: azimuth ?? this.azimuth,
      elevation: elevation ?? this.elevation,
      charge: charge ?? this.charge,
      timeOfFlight: timeOfFlight ?? this.timeOfFlight,
      heightDifference: heightDifference ?? this.heightDifference,
      correction: correction ?? this.correction,
      mortarType: mortarType ?? this.mortarType,
      heightAdjusted: heightAdjusted ?? this.heightAdjusted,
    );
  }

  Map<String, dynamic> toJson() => {
    'distance': distance,
    'azimuth': azimuth,
    'elevation': elevation,
    'charge': charge,
    'timeOfFlight': timeOfFlight,
    'heightDifference': heightDifference,
    'correction': correction,
    'mortarType': mortarType,
    'heightAdjusted': heightAdjusted,
  };

  factory FiringSolution.fromJson(Map<String, dynamic> json) {
    return FiringSolution(
      distance: (json['distance'] as num).toDouble(),
      azimuth: (json['azimuth'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      charge: json['charge'] as int,
      timeOfFlight: (json['timeOfFlight'] as num).toDouble(),
      heightDifference: (json['heightDifference'] as num).toDouble(),
      correction: json['correction'] as String?,
      mortarType: json['mortarType'] as String,
      heightAdjusted: json['heightAdjusted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    distance, azimuth, elevation, charge, 
    timeOfFlight, heightDifference, mortarType, heightAdjusted
  ];

  @override
  String toString() => 
    'FiringSolution(AZ: $azimuthDisplay, EL: $elevationDisplay, CH: $charge)';
}
