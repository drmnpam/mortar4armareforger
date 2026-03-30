/// Weapon types supported by the application
enum WeaponType {
  mortar,
  artillery,
  angleTable,
}

/// Extension for WeaponType JSON serialization
extension WeaponTypeExtension on WeaponType {
  String get jsonValue {
    switch (this) {
      case WeaponType.mortar:
        return 'mortar';
      case WeaponType.artillery:
        return 'artillery';
      case WeaponType.angleTable:
        return 'angle_table';
    }
  }

  static WeaponType fromJson(String value) {
    switch (value.toLowerCase()) {
      case 'mortar':
        return WeaponType.mortar;
      case 'artillery':
      case 'artillery_table':
        return WeaponType.artillery;
      case 'angle_table':
      case 'angletable':
        return WeaponType.angleTable;
      default:
        return WeaponType.mortar;
    }
  }
}

/// Represents a weapon in the registry
class Weapon {
  final String id;
  final String name;
  final WeaponType type;
  final double minRange;
  final double maxRange;
  final bool hasCharges;
  final List<int> charges;
  final String tableId;

  const Weapon({
    required this.id,
    required this.name,
    required this.type,
    required this.minRange,
    required this.maxRange,
    required this.hasCharges,
    required this.charges,
    required this.tableId,
  });

  /// Check if a distance is within weapon's operational range
  bool canReach(double distance) {
    return distance >= minRange && distance <= maxRange;
  }

  /// Get display name with range info
  String get displayName => '$name (${minRange.toStringAsFixed(0)}-${maxRange.toStringAsFixed(0)}m)';

  @override
  String toString() => 'Weapon(id: $id, name: $name, type: $type)';
}

/// All available weapons in the application
const List<Weapon> allWeapons = [
  // Mortars
  Weapon(
    id: '2b14',
    name: '2B14',
    type: WeaponType.mortar,
    minRange: 100,
    maxRange: 3600,
    hasCharges: true,
    charges: [0, 1, 2, 3],
    tableId: '2b14',
  ),
  Weapon(
    id: 'm224',
    name: 'M224',
    type: WeaponType.mortar,
    minRange: 100,
    maxRange: 3500,
    hasCharges: true,
    charges: [0, 1, 2, 3],
    tableId: 'm224',
  ),
  Weapon(
    id: 'm252',
    name: 'M252',
    type: WeaponType.mortar,
    minRange: 200,
    maxRange: 5800,
    hasCharges: true,
    charges: [0, 1, 2, 3],
    tableId: 'm252',
  ),
  // Artillery
  Weapon(
    id: 'm107',
    name: 'M107 HE',
    type: WeaponType.artillery,
    minRange: 950,
    maxRange: 1500,
    hasCharges: false,
    charges: [],
    tableId: 'm107',
  ),
  Weapon(
    id: '2s1',
    name: '2S1 Gvozdika',
    type: WeaponType.artillery,
    minRange: 1000,
    maxRange: 12000,
    hasCharges: false,
    charges: [],
    tableId: '2s1',
  ),
  // Angle Table
  Weapon(
    id: 'd30',
    name: '122mm D30',
    type: WeaponType.angleTable,
    minRange: 500,
    maxRange: 12000,
    hasCharges: false,
    charges: [],
    tableId: 'd30',
  ),
];

/// Get weapon by ID
Weapon? getWeaponById(String id) {
  try {
    return allWeapons.firstWhere(
      (w) => w.id.toLowerCase() == id.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}

/// Get all mortars
List<Weapon> getMortars() {
  return allWeapons.where((w) => w.type == WeaponType.mortar).toList();
}

/// Get all artillery weapons
List<Weapon> getArtillery() {
  return allWeapons.where((w) => w.type == WeaponType.artillery).toList();
}

/// Get all angle table weapons
List<Weapon> getAngleWeapons() {
  return allWeapons.where((w) => w.type == WeaponType.angleTable).toList();
}

/// Get weapons by type
List<Weapon> getWeaponsByType(WeaponType type) {
  return allWeapons.where((w) => w.type == type).toList();
}

/// Get all weapon IDs
List<String> get allWeaponIds => allWeapons.map((w) => w.id).toList();

/// Get all weapon names
List<String> get allWeaponNames => allWeapons.map((w) => w.name).toList();

/// Default weapon ID (M252)
const String defaultWeaponId = 'm252';

/// Get default weapon
Weapon getDefaultWeapon() {
  return getWeaponById(defaultWeaponId) ?? allWeapons.first;
}
