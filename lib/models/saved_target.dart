import 'package:equatable/equatable.dart';
import 'position.dart';
import 'firing_solution.dart';

/// Saved target with metadata
class SavedTarget extends Equatable {
  final String id;
  final String name;
  final Position position;
  final String? description;
  final DateTime createdAt;
  final FiringSolution? lastSolution;

  const SavedTarget({
    required this.id,
    required this.name,
    required this.position,
    this.description,
    required this.createdAt,
    this.lastSolution,
  });

  SavedTarget copyWith({
    String? id,
    String? name,
    Position? position,
    String? description,
    DateTime? createdAt,
    FiringSolution? lastSolution,
  }) {
    return SavedTarget(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      lastSolution: lastSolution ?? this.lastSolution,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position.toJson(),
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'lastSolution': lastSolution?.toJson(),
  };

  factory SavedTarget.fromJson(Map<String, dynamic> json) {
    return SavedTarget(
      id: json['id'] as String,
      name: json['name'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSolution: json['lastSolution'] != null
          ? FiringSolution.fromJson(json['lastSolution'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, position, createdAt];

  @override
  String toString() => 'SavedTarget($name, $position)';
}
