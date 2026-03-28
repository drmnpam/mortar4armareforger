import 'package:equatable/equatable.dart';

/// Single row in a ballistic table
class BallisticRow extends Equatable {
  /// Range in meters
  final double range;
  
  /// Elevation in mils
  final double elevation;
  
  /// Time of flight in seconds
  final double timeOfFlight;
  
  /// Height of burst at this range (optional)
  final double? heightOfBurst;
  
  /// Drift in mils (optional)
  final double? drift;

  const BallisticRow({
    required this.range,
    required this.elevation,
    required this.timeOfFlight,
    this.heightOfBurst,
    this.drift,
  });

  factory BallisticRow.fromJson(Map<String, dynamic> json) {
    return BallisticRow(
      range: (json['range'] as num).toDouble(),
      elevation: (json['elevation'] as num).toDouble(),
      timeOfFlight: (json['tof'] as num).toDouble(),
      heightOfBurst: (json['heightOfBurst'] as num?)?.toDouble(),
      drift: (json['drift'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'range': range,
    'elevation': elevation,
    'tof': timeOfFlight,
    if (heightOfBurst != null) 'heightOfBurst': heightOfBurst,
    if (drift != null) 'drift': drift,
  };

  @override
  List<Object?> get props => [range, elevation, timeOfFlight, heightOfBurst, drift];

  @override
  String toString() => 'BallisticRow(range: $range, elevation: $elevation)';
}
