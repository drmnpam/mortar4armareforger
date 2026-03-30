import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/models.dart';

/// Types of map markers
enum MarkerType {
  mortar,
  target,
  splash,
  saved,
  fireMission,
}

/// Map marker with position and metadata
class MapMarker {
  final String id;
  final MarkerType type;
  Position position;
  String? label;
  String? description;
  Color color;
  bool isDraggable;
  DateTime createdAt;
  FiringSolution? solution;
  
  MapMarker({
    required this.id,
    required this.type,
    required this.position,
    this.label,
    this.description,
    this.color = Colors.green,
    this.isDraggable = true,
    DateTime? createdAt,
    this.solution,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Create a mortar marker
  factory MapMarker.mortar(Position position, {String? label}) {
    return MapMarker(
      id: 'mortar_${DateTime.now().millisecondsSinceEpoch}',
      type: MarkerType.mortar,
      position: position,
      label: label ?? 'MORTAR',
      color: const Color(0xFF4CAF50), // Green
      isDraggable: true,
    );
  }
  
  /// Create a target marker
  factory MapMarker.target(Position position, {String? label}) {
    return MapMarker(
      id: 'target_${DateTime.now().millisecondsSinceEpoch}',
      type: MarkerType.target,
      position: position,
      label: label ?? 'TARGET',
      color: const Color(0xFFEF5350), // Red
      isDraggable: true,
    );
  }
  
  /// Create a splash/impact marker
  factory MapMarker.splash(Position position, {String? label}) {
    return MapMarker(
      id: 'splash_${DateTime.now().millisecondsSinceEpoch}',
      type: MarkerType.splash,
      position: position,
      label: label ?? 'SPLASH',
      color: const Color(0xFFFFA726), // Orange
      isDraggable: false,
    );
  }
  
  /// Update marker position
  void updatePosition(Position newPosition) {
    position = newPosition;
  }
  
  /// Update firing solution
  void updateSolution(FiringSolution? newSolution) {
    solution = newSolution;
  }
  
  /// Get icon for marker type
  IconData get icon {
    switch (type) {
      case MarkerType.mortar:
        return Icons.my_location;
      case MarkerType.target:
        return Icons.location_on;
      case MarkerType.splash:
        return Icons.local_fire_department;
      case MarkerType.saved:
        return Icons.bookmark;
      case MarkerType.fireMission:
        return Icons.campaign;
    }
  }
  
  /// Get marker size
  double get size {
    switch (type) {
      case MarkerType.mortar:
        return 40;
      case MarkerType.target:
        return 40;
      case MarkerType.splash:
        return 30;
      case MarkerType.saved:
        return 35;
      case MarkerType.fireMission:
        return 35;
    }
  }
  
  /// Get display label with coordinates
  String get displayLabel {
    final coords = position.toGridReference(precision: 3);
    if (label != null && label!.isNotEmpty) {
      return '$label\n$coords';
    }
    return coords;
  }
  
  MapMarker copyWith({
    String? id,
    MarkerType? type,
    Position? position,
    String? label,
    String? description,
    Color? color,
    bool? isDraggable,
    DateTime? createdAt,
    FiringSolution? solution,
  }) {
    return MapMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      label: label ?? this.label,
      description: description ?? this.description,
      color: color ?? this.color,
      isDraggable: isDraggable ?? this.isDraggable,
      createdAt: createdAt ?? this.createdAt,
      solution: solution ?? this.solution,
    );
  }
  
  @override
  String toString() => 'MapMarker($type, $position, $label)';
}

/// Manager for map markers
class MarkerManager {
  final List<MapMarker> _markers = [];
  
  List<MapMarker> get markers => List.unmodifiable(_markers);
  
  /// Get marker by ID
  MapMarker? getMarker(String id) {
    try {
      return _markers.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Get markers by type
  List<MapMarker> getMarkersByType(MarkerType type) {
    return _markers.where((m) => m.type == type).toList();
  }
  
  /// Get first mortar marker
  MapMarker? get mortarMarker {
    try {
      return _markers.firstWhere((m) => m.type == MarkerType.mortar);
    } catch (_) {
      return null;
    }
  }
  
  /// Get first target marker
  MapMarker? get targetMarker {
    try {
      return _markers.firstWhere((m) => m.type == MarkerType.target);
    } catch (_) {
      return null;
    }
  }
  
  /// Add a marker
  void addMarker(MapMarker marker) {
    // Remove existing marker of same type for primary markers
    if (marker.type == MarkerType.mortar || marker.type == MarkerType.target) {
      _markers.removeWhere((m) => m.type == marker.type);
    }
    _markers.add(marker);
  }
  
  /// Remove a marker
  void removeMarker(String id) {
    _markers.removeWhere((m) => m.id == id);
  }
  
  /// Remove all markers of a type
  void removeMarkersByType(MarkerType type) {
    _markers.removeWhere((m) => m.type == type);
  }
  
  /// Update marker position by ID
  void updateMarkerPosition(String id, Position newPosition) {
    final marker = getMarker(id);
    if (marker != null) {
      marker.updatePosition(newPosition);
    }
  }

  /// Move marker by type (for mortar/target)
  void moveMarker(MarkerType type, Position newPosition) {
    final marker = _markers.firstWhere(
      (m) => m.type == type,
      orElse: () => throw Exception('No marker of type $type found'),
    );
    marker.updatePosition(newPosition);
  }
  
  /// Clear all markers
  void clear() {
    _markers.clear();
  }
  
  /// Check if both mortar and target are placed
  bool get hasValidSolution {
    return mortarMarker != null && targetMarker != null;
  }
  
  /// Get distance between mortar and target
  double? get distance {
    final mortar = mortarMarker;
    final target = targetMarker;
    if (mortar == null || target == null) return null;
    
    final dx = target.position.x - mortar.position.x;
    final dy = target.position.y - mortar.position.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Convert markers to list
  List<Map<String, dynamic>> toJson() {
    return _markers.map((m) => {
      'id': m.id,
      'type': m.type.index,
      'position': m.position.toJson(),
      'label': m.label,
      'description': m.description,
      'color': m.color.value,
      'createdAt': m.createdAt.toIso8601String(),
    }).toList();
  }
  
  /// Load markers from JSON
  void fromJson(List<dynamic> json) {
    _markers.clear();
    for (final item in json) {
      _markers.add(MapMarker(
        id: item['id'] as String,
        type: MarkerType.values[item['type'] as int],
        position: Position.fromJson(item['position'] as Map<String, dynamic>),
        label: item['label'] as String?,
        description: item['description'] as String?,
        color: Color(item['color'] as int),
        createdAt: DateTime.parse(item['createdAt'] as String),
      ));
    }
  }
}
