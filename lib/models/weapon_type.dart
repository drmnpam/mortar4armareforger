/// Weapon types for ballistic calculations
enum WeaponType {
  /// Standard mortar with elevation-based tables
  mortar,
  
  /// Artillery with charge-based ballistic tables
  artilleryTable,
  
  /// Angle-based firing tables (e.g., 122mm D30)
  angleTable,
  
  /// Direct fire weapons (e.g., tank cannons, rockets)
  directFire,
}

extension WeaponTypeExtension on WeaponType {
  String get displayName {
    switch (this) {
      case WeaponType.mortar:
        return 'Mortar';
      case WeaponType.artilleryTable:
        return 'Artillery';
      case WeaponType.angleTable:
        return 'Angle Table';
      case WeaponType.directFire:
        return 'Direct Fire';
    }
  }
  
  String get jsonValue {
    switch (this) {
      case WeaponType.mortar:
        return 'mortar';
      case WeaponType.artilleryTable:
        return 'artillery_table';
      case WeaponType.angleTable:
        return 'angle_table';
      case WeaponType.directFire:
        return 'direct_fire';
    }
  }
  
  static WeaponType fromJson(String value) {
    switch (value) {
      case 'mortar':
        return WeaponType.mortar;
      case 'artillery_table':
        return WeaponType.artilleryTable;
      case 'angle_table':
        return WeaponType.angleTable;
      case 'direct_fire':
        return WeaponType.directFire;
      default:
        return WeaponType.mortar;
    }
  }
}
