import 'dart:math';
import '../../models/models.dart';
import 'calculators/ballistic_solver.dart';

/// Fire Mission management system
/// Supports multiple targets in a fire mission queue
class FireMission {
  final String id;
  final String name;
  final Position mortarPosition;
  final List<FireMissionTarget> targets;
  final String mortarType;
  final DateTime createdAt;
  FireMissionStatus status;
  int currentTargetIndex;
  
  FireMission({
    String? id,
    required this.name,
    required this.mortarPosition,
    required this.targets,
    required this.mortarType,
    DateTime? createdAt,
    this.status = FireMissionStatus.planned,
    this.currentTargetIndex = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();
  
  /// Calculate all firing solutions for this mission
  void calculateAll() {
    for (int i = 0; i < targets.length; i++) {
      final target = targets[i];
      try {
        final solution = RefactoredBallisticSolver.calculate(
          mortarPosition: mortarPosition,
          targetPosition: target.position,
          mortarType: mortarType,
        );
        targets[i] = target.copyWith(solution: solution);
      } catch (e) {
        targets[i] = target.copyWith(error: e.toString());
      }
    }
  }
  
  /// Get current target
  FireMissionTarget? get currentTarget {
    if (currentTargetIndex >= 0 && currentTargetIndex < targets.length) {
      return targets[currentTargetIndex];
    }
    return null;
  }
  
  /// Move to next target
  bool nextTarget() {
    if (currentTargetIndex < targets.length - 1) {
      // Mark current as fired
      if (currentTarget != null) {
        targets[currentTargetIndex] = currentTarget!.copyWith(
          status: TargetStatus.fired,
          firedAt: DateTime.now(),
        );
      }
      currentTargetIndex++;
      return true;
    }
    status = FireMissionStatus.completed;
    return false;
  }
  
  /// Get total mission time (sum of all TOF)
  Duration get totalTime {
    var seconds = 0.0;
    for (final target in targets) {
      if (target.solution != null) {
        seconds += target.solution!.timeOfFlight;
      }
    }
    return Duration(seconds: seconds.round());
  }
  
  /// Get average range
  double get averageRange {
    if (targets.isEmpty) return 0;
    var total = 0.0;
    var count = 0;
    for (final target in targets) {
      if (target.solution != null) {
        total += target.solution!.distance;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }
  
  /// Get number of targets ready to fire
  int get readyCount => targets.where((t) => t.status == TargetStatus.ready).length;
  
  /// Get number of targets already fired
  int get firedCount => targets.where((t) => t.status == TargetStatus.fired).length;
  
  /// Get coverage area (bounding box of all targets)
  ({Position min, Position max})? get coverageArea {
    if (targets.isEmpty) return null;
    
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    
    for (final target in targets) {
      if (target.position.x < minX) minX = target.position.x;
      if (target.position.y < minY) minY = target.position.y;
      if (target.position.x > maxX) maxX = target.position.x;
      if (target.position.y > maxY) maxY = target.position.y;
    }
    
    return (
      min: Position(x: minX, y: minY),
      max: Position(x: maxX, y: maxY),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mortarPosition': mortarPosition.toJson(),
    'targets': targets.map((t) => t.toJson()).toList(),
    'mortarType': mortarType,
    'createdAt': createdAt.toIso8601String(),
    'status': status.index,
    'currentTargetIndex': currentTargetIndex,
  };
  
  factory FireMission.fromJson(Map<String, dynamic> json) {
    return FireMission(
      id: json['id'] as String,
      name: json['name'] as String,
      mortarPosition: Position.fromJson(json['mortarPosition'] as Map<String, dynamic>),
      targets: (json['targets'] as List)
          .map((t) => FireMissionTarget.fromJson(t as Map<String, dynamic>))
          .toList(),
      mortarType: json['mortarType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: FireMissionStatus.values[json['status'] as int],
      currentTargetIndex: json['currentTargetIndex'] as int,
    );
  }
}

/// Individual target in a fire mission
class FireMissionTarget {
  final String id;
  final String name;
  final Position position;
  final FiringSolution? solution;
  final TargetStatus status;
  final DateTime? firedAt;
  final String? error;
  final int priority; // 1 = highest
  final String? notes;
  
  const FireMissionTarget({
    String? id,
    required this.name,
    required this.position,
    this.solution,
    this.status = TargetStatus.ready,
    this.firedAt,
    this.error,
    this.priority = 5,
    this.notes,
  }) : id = id ?? '';
  
  bool get isCalculated => solution != null;
  bool get hasError => error != null;
  
  FireMissionTarget copyWith({
    String? name,
    Position? position,
    FiringSolution? solution,
    TargetStatus? status,
    DateTime? firedAt,
    String? error,
    int? priority,
    String? notes,
  }) {
    return FireMissionTarget(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      solution: solution ?? this.solution,
      status: status ?? this.status,
      firedAt: firedAt ?? this.firedAt,
      error: error ?? this.error,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position.toJson(),
    'solution': solution?.toJson(),
    'status': status.index,
    'firedAt': firedAt?.toIso8601String(),
    'error': error,
    'priority': priority,
    'notes': notes,
  };
  
  factory FireMissionTarget.fromJson(Map<String, dynamic> json) {
    return FireMissionTarget(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      solution: json['solution'] != null
          ? FiringSolution.fromJson(json['solution'] as Map<String, dynamic>)
          : null,
      status: TargetStatus.values[json['status'] as int],
      firedAt: json['firedAt'] != null
          ? DateTime.parse(json['firedAt'] as String)
          : null,
      error: json['error'] as String?,
      priority: json['priority'] as int? ?? 5,
      notes: json['notes'] as String?,
    );
  }
}

/// Fire mission manager
class FireMissionManager {
  final List<FireMission> _missions = [];
  FireMission? _activeMission;
  
  List<FireMission> get missions => List.unmodifiable(_missions);
  FireMission? get activeMission => _activeMission;
  
  /// Create new fire mission
  FireMission createMission({
    required String name,
    required Position mortarPosition,
    required String mortarType,
    List<FireMissionTarget>? targets,
  }) {
    final mission = FireMission(
      name: name,
      mortarPosition: mortarPosition,
      targets: targets ?? [],
      mortarType: mortarType,
    );
    
    _missions.add(mission);
    _activeMission = mission;
    
    return mission;
  }
  
  /// Add target to active mission
  void addTarget(FireMissionTarget target) {
    if (_activeMission == null) return;
    
    final targets = List<FireMissionTarget>.from(_activeMission!.targets)
      ..add(target);
    
    _missions.remove(_activeMission);
    _activeMission = FireMission(
      id: _activeMission!.id,
      name: _activeMission!.name,
      mortarPosition: _activeMission!.mortarPosition,
      targets: targets,
      mortarType: _activeMission!.mortarType,
      createdAt: _activeMission!.createdAt,
      status: _activeMission!.status,
      currentTargetIndex: _activeMission!.currentTargetIndex,
    );
    _missions.add(_activeMission!);
  }
  
  /// Remove target from active mission
  void removeTarget(String targetId) {
    if (_activeMission == null) return;
    
    final targets = _activeMission!.targets
        .where((t) => t.id != targetId)
        .toList();
    
    _missions.remove(_activeMission);
    _activeMission = FireMission(
      id: _activeMission!.id,
      name: _activeMission!.name,
      mortarPosition: _activeMission!.mortarPosition,
      targets: targets,
      mortarType: _activeMission!.mortarType,
      createdAt: _activeMission!.createdAt,
      status: _activeMission!.status,
      currentTargetIndex: _activeMission!.currentTargetIndex,
    );
    _missions.add(_activeMission!);
  }
  
  /// Set active mission
  void setActiveMission(String missionId) {
    _activeMission = _missions.firstWhere((m) => m.id == missionId);
  }
  
  /// Delete mission
  void deleteMission(String missionId) {
    _missions.removeWhere((m) => m.id == missionId);
    if (_activeMission?.id == missionId) {
      _activeMission = _missions.isNotEmpty ? _missions.first : null;
    }
  }
  
  /// Fire next target in active mission
  bool fireNext() {
    if (_activeMission == null) return false;
    return _activeMission!.nextTarget();
  }
  
  /// Reorder targets by priority
  void sortByPriority() {
    if (_activeMission == null) return;
    
    final sorted = List<FireMissionTarget>.from(_activeMission!.targets)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    
    _activeMission = FireMission(
      id: _activeMission!.id,
      name: _activeMission!.name,
      mortarPosition: _activeMission!.mortarPosition,
      targets: sorted,
      mortarType: _activeMission!.mortarType,
      createdAt: _activeMission!.createdAt,
      status: _activeMission!.status,
    );
  }
  
  /// Clear all missions
  void clear() {
    _missions.clear();
    _activeMission = null;
  }
  
  /// Export all missions to JSON
  List<Map<String, dynamic>> export() {
    return _missions.map((m) => m.toJson()).toList();
  }
  
  /// Import missions from JSON
  void import(List<dynamic> json) {
    for (final item in json) {
      _missions.add(FireMission.fromJson(item as Map<String, dynamic>));
    }
    if (_missions.isNotEmpty && _activeMission == null) {
      _activeMission = _missions.first;
    }
  }
}

enum FireMissionStatus {
  planned,
  active,
  completed,
  cancelled,
}

enum TargetStatus {
  planned,
  ready,
  firing,
  fired,
  cancelled,
}
