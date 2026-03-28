import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../ballistics/cubit/ballistics_cubit.dart';
import '../../ballistics/ballistics.dart';
import '../widgets/firing_solution_card.dart';
import '../widgets/coordinate_input.dart';

class NumericCalculatorScreen extends StatefulWidget {
  const NumericCalculatorScreen({super.key});

  @override
  State<NumericCalculatorScreen> createState() => _NumericCalculatorScreenState();
}

class _NumericCalculatorScreenState extends State<NumericCalculatorScreen> {
  double _distance = 0;
  double _mortarAltitude = 0;
  double _targetAltitude = 0;

  @override
  void initState() {
    super.initState();
    final state = context.read<BallisticsCubit>().state;
    final dx = state.targetPosition.x - state.mortarPosition.x;
    final dy = state.targetPosition.y - state.mortarPosition.y;
    _distance = state.solution?.distance ?? math.sqrt(dx * dx + dy * dy);
    _mortarAltitude = state.mortarPosition.altitude;
    _targetAltitude = state.targetPosition.altitude;
  }

  @override
  Widget build(BuildContext context) {
    final canCalculate = _distance > 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('NUMERIC CALCULATOR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<BallisticsCubit, BallisticsState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mortar Type Selector
                  _buildMortarSelector(context, state),
                  
                  const SizedBox(height: 16),
                  
                  // Mortar Position Card
                  _buildMortarCard(context),
                  
                  const SizedBox(height: 16),
                  
                  // Calculate Button
                  ElevatedButton.icon(
                    onPressed: canCalculate
                        ? () => context.read<BallisticsCubit>().calculateFromDistance(
                              distance: _distance,
                              mortarAltitude: _mortarAltitude,
                              targetAltitude: _targetAltitude,
                            )
                        : null,
                    icon: const Icon(Icons.calculate),
                    label: const Text('CALCULATE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Error Message
                  if (state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.danger),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: TextStyle(color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Firing Solution
                  if (state.solution != null)
                    FiringSolutionCard(solution: state.solution!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMortarSelector(BuildContext context, BallisticsState state) {
    final mortars = BallisticTables.availableMortars;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MORTAR TYPE',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: mortars.map((mortar) {
                final isSelected = state.selectedMortar == mortar;
                return ChoiceChip(
                  label: Text(mortar),
                  selected: isSelected,
                  onSelected: (_) => context.read<BallisticsCubit>().setMortarType(mortar),
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'CHARGE:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(state.autoCharge ? 'AUTO' : 'MANUAL'),
                  selected: state.autoCharge,
                  onSelected: (_) => context.read<BallisticsCubit>().toggleAutoCharge(),
                  selectedColor: AppTheme.accent.withOpacity(0.3),
                  checkmarkColor: AppTheme.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMortarCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'INPUT DATA',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CoordinateInput(
              label: 'DISTANCE TO TARGET',
              value: _distance,
              onChanged: (v) => setState(() => _distance = v),
              suffix: 'm',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CoordinateInput(
                    label: 'MORTAR ALTITUDE',
                    value: _mortarAltitude,
                    onChanged: (v) => setState(() => _mortarAltitude = v),
                    suffix: 'm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CoordinateInput(
                    label: 'TARGET ALTITUDE',
                    value: _targetAltitude,
                    onChanged: (v) => setState(() => _targetAltitude = v),
                    suffix: 'm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter range and both heights to get elevation/charge without map coordinates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
