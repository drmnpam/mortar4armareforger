import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../ballistics/ballistics.dart';
import '../../storage/storage.dart';

part 'ballistics_state.dart';

class BallisticsCubit extends Cubit<BallisticsState> {
  final StorageService? _storage;
  
  BallisticsCubit({StorageService? storage}) 
    : _storage = storage,
      super(BallisticsState.initial()) {
    _initialize();
  }
  
  void _initialize() {
    BallisticTables.initialize();
    _loadPreferences();
  }
  
  void _loadPreferences() {
    if (_storage != null) {
      final mortar = _storage!.getPreferredMortar();
      final autoCharge = _storage!.getAutoCharge();
      emit(state.copyWith(
        selectedMortar: mortar,
        autoCharge: autoCharge,
      ));
    }
  }
  
  /// Set mortar position
  void setMortarPosition(Position position) {
    emit(state.copyWith(
      mortarPosition: position,
      solution: null,
    ));
    _storage?.setLastMortarPosition(position);
  }
  
  /// Set target position
  void setTargetPosition(Position position) {
    emit(state.copyWith(
      targetPosition: position,
      solution: null,
    ));
  }
  
  /// Set mortar X coordinate
  void setMortarX(double value) {
    final current = state.mortarPosition;
    setMortarPosition(current.copyWith(x: value));
  }
  
  /// Set mortar Y coordinate
  void setMortarY(double value) {
    final current = state.mortarPosition;
    setMortarPosition(current.copyWith(y: value));
  }
  
  /// Set mortar altitude
  void setMortarAltitude(double value) {
    final current = state.mortarPosition;
    setMortarPosition(current.copyWith(altitude: value));
  }
  
  /// Set target X coordinate
  void setTargetX(double value) {
    final current = state.targetPosition;
    setTargetPosition(current.copyWith(x: value));
  }
  
  /// Set target Y coordinate
  void setTargetY(double value) {
    final current = state.targetPosition;
    setTargetPosition(current.copyWith(y: value));
  }
  
  /// Set target altitude
  void setTargetAltitude(double value) {
    final current = state.targetPosition;
    setTargetPosition(current.copyWith(altitude: value));
  }
  
  /// Set mortar type
  void setMortarType(String type) {
    emit(state.copyWith(
      selectedMortar: type,
      solution: null,
    ));
    _storage?.setPreferredMortar(type);
  }
  
  /// Set specific charge (null for auto)
  void setCharge(int? charge) {
    emit(state.copyWith(
      preferredCharge: charge,
      solution: null,
    ));
  }
  
  /// Toggle auto charge selection
  void toggleAutoCharge() {
    final newValue = !state.autoCharge;
    emit(state.copyWith(
      autoCharge: newValue,
      preferredCharge: newValue ? null : 0,
    ));
    _storage?.setAutoCharge(newValue);
  }
  
  /// Calculate firing solution
  void calculate() {
    if (state.mortarPosition.x == 0 && state.mortarPosition.y == 0) {
      emit(state.copyWith(
        errorMessage: 'Set mortar position',
        solution: null,
      ));
      return;
    }
    
    if (state.targetPosition.x == 0 && state.targetPosition.y == 0) {
      emit(state.copyWith(
        errorMessage: 'Set target position',
        solution: null,
      ));
      return;
    }
    
    try {
      final solution = BallisticSolver.calculate(
        mortarPosition: state.mortarPosition,
        targetPosition: state.targetPosition,
        mortarType: state.selectedMortar,
        preferredCharge: state.autoCharge ? null : state.preferredCharge,
      );
      
      emit(state.copyWith(
        solution: solution,
        errorMessage: null,
      ));
      
      // Save to history
      _storage?.addToHistory(solution, state.mortarPosition, state.targetPosition);
    } on BallisticException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
        solution: null,
      ));
    }
  }
  
  /// Clear current solution
  void clear() {
    emit(state.copyWith(
      solution: null,
      errorMessage: null,
    ));
  }
  
  /// Swap mortar and target positions
  void swapPositions() {
    emit(state.copyWith(
      mortarPosition: state.targetPosition,
      targetPosition: state.mortarPosition,
      solution: null,
    ));
  }
  
  /// Calculate all charge options
  List<FiringSolution> getAllChargeSolutions() {
    if (state.mortarPosition.x == 0 || state.targetPosition.x == 0) {
      return [];
    }
    
    try {
      return BallisticSolver.calculateAllCharges(
        mortarPosition: state.mortarPosition,
        targetPosition: state.targetPosition,
        mortarType: state.selectedMortar,
      );
    } on BallisticException {
      return [];
    }
  }
  
  /// Check if solution is valid
  bool get hasValidInput {
    return (state.mortarPosition.x != 0 || state.mortarPosition.y != 0) &&
           (state.targetPosition.x != 0 || state.targetPosition.y != 0);
  }
}
