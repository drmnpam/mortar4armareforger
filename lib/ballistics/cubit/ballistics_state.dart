part of 'ballistics_cubit.dart';

class BallisticsState extends Equatable {
  static const Object _unset = Object();

  final Position mortarPosition;
  final Position targetPosition;
  final String selectedMortar;
  final FiringSolution? solution;
  final String? errorMessage;

  const BallisticsState({
    required this.mortarPosition,
    required this.targetPosition,
    required this.selectedMortar,
    this.solution,
    this.errorMessage,
  });

  factory BallisticsState.initial() {
    return const BallisticsState(
      mortarPosition: Position(x: 0, y: 0, altitude: 0),
      targetPosition: Position(x: 0, y: 0, altitude: 0),
      selectedMortar: 'M252',
      solution: null,
      errorMessage: null,
    );
  }

  BallisticsState copyWith({
    Position? mortarPosition,
    Position? targetPosition,
    String? selectedMortar,
    Object? solution = _unset,
    Object? errorMessage = _unset,
    bool clearError = false,
    bool clearSolution = false,
  }) {
    return BallisticsState(
      mortarPosition: mortarPosition ?? this.mortarPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      selectedMortar: selectedMortar ?? this.selectedMortar,
      solution: clearSolution
          ? null
          : (solution == _unset ? this.solution : solution as FiringSolution?),
      errorMessage: clearError
          ? null
          : (errorMessage == _unset
              ? this.errorMessage
              : errorMessage as String?),
    );
  }

  @override
  List<Object?> get props => [
        mortarPosition,
        targetPosition,
        selectedMortar,
        solution,
        errorMessage,
      ];
}
