import 'package:equatable/equatable.dart';

/// Generic weapon ballistic table row
/// Supports multiple weapon types (mortar, artillery, angle tables)
class WeaponBallisticRow extends Equatable {
  /// Range in meters
  final double range;
  
  /// Elevation in mils (for mortars and artillery)
  final double? elevation;
  
  /// Angle in degrees (for angle tables like D30)
  final double? angle;
  
  /// Time of flight in seconds
  final double? timeOfFlight;
  
  /// Fuze setting (for some artillery)
  final double? fuzeSetting;
  
  const WeaponBallisticRow({
    required this.range,
    this.elevation,
    this.angle,
    this.timeOfFlight,
    this.fuzeSetting,
  });
  
  factory WeaponBallisticRow.fromJson(Map<String, dynamic> json) {
    // Handle both formats: (range, elevation, tof) and (range_m, elevation_mil, tof_s)
    final range = (json['range_m'] as num?)?.toDouble() ?? 
                  (json['range'] as num).toDouble();
    
    final elevation = (json['elevation_mil'] as num?)?.toDouble() ?? 
                      (json['elevation'] as num?)?.toDouble();
    
    final angle = (json['angle'] as num?)?.toDouble();
    
    final timeOfFlight = (json['tof_s'] as num?)?.toDouble() ?? 
                        (json['tof'] as num?)?.toDouble() ?? 
                        (json['timeOfFlight'] as num?)?.toDouble();
    
    final fuzeSetting = (json['fuze'] as num?)?.toDouble();
    
    return WeaponBallisticRow(
      range: range,
      elevation: elevation,
      angle: angle,
      timeOfFlight: timeOfFlight,
      fuzeSetting: fuzeSetting,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'range': range,
    if (elevation != null) 'elevation': elevation,
    if (angle != null) 'angle': angle,
    if (timeOfFlight != null) 'tof': timeOfFlight,
    if (fuzeSetting != null) 'fuze': fuzeSetting,
  };
  
  @override
  List<Object?> get props => [range, elevation, angle, timeOfFlight, fuzeSetting];
}
