part of 'ballistics_cubit.dart';

class BallisticsState extends Equatable {
  final Position mortarPosition;
  final Position targetPosition;
  final String selectedMortar;
  final bool autoCharge;
  final int? preferredCharge;
  final FiringSolution? solution;
  final String? errorMessage;
  
  const BallisticsState({
    required this.mortarPosition,
    required this.targetPosition,
    required this.selectedMortar,
    required this.autoCharge,
    this.preferredCharge,
    this.solution,
    this.errorMessage,
  });
  
  factory BallisticsState.initial() {
    return const BallisticsState(
      mortarPosition: Position(x: 0, y: 0, altitude: 0),
      targetPosition: Position(x: 0, y: 0, altitude: 0),
      selectedMortar: 'M252',
      autoCharge: true,
      preferredCharge: null,
      solution: null,
      errorMessage: null,
    );
  }
  
  BallisticsState copyWith({
    Position? mortarPosition,
    Position? targetPosition,
    String? selectedMortar,
    bool? autoCharge,
    int? preferredCharge,
    FiringSolution? solution,
    String? errorMessage,
    bool clearError = false,
    bool clearSolution = false,
  }) {
    return BallisticsState(
      mortarPosition: mortarPosition ?? this.mortarPosition,
      targetPosition: targetPosition ?? this.targetPosition,
      selectedMortar: selectedMortar ?? this.selectedMortar,
      autoCharge: autoCharge ?? this.autoCharge,
      preferredCharge: preferredCharge ?? this.preferredCharge,
      solution: clearSolution ? null : solution ?? this.solution,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    mortarPosition,
    targetPosition,
    selectedMortar,
    autoCharge,
    preferredCharge,
    solution,
    errorMessage,
  ];
}
