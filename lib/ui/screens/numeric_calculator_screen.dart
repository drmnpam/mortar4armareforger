import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../ballistics/cubit/ballistics_cubit.dart';
import '../../ballistics/ballistics.dart';
import '../widgets/firing_solution_card.dart';
import '../widgets/coordinate_input.dart';

class NumericCalculatorScreen extends StatelessWidget {
  const NumericCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildMortarCard(context, state),
                  
                  const SizedBox(height: 8),
                  
                  // Swap Button
                  Center(
                    child: IconButton(
                      onPressed: () => context.read<BallisticsCubit>().swapPositions(),
                      icon: const Icon(Icons.swap_vert),
                      color: AppTheme.accent,
                      tooltip: 'Swap positions',
                    ),
                  ),
                  
                  // Target Position Card
                  _buildTargetCard(context, state),
                  
                  const SizedBox(height: 16),
                  
                  // Calculate Button
                  ElevatedButton.icon(
                    onPressed: context.read<BallisticsCubit>().hasValidInput
                        ? () => context.read<BallisticsCubit>().calculate()
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

  Widget _buildMortarCard(BuildContext context, BallisticsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'MORTAR POSITION',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CoordinateInput(
                    label: 'X COORD',
                    value: state.mortarPosition.x,
                    onChanged: (v) => context.read<BallisticsCubit>().setMortarX(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CoordinateInput(
                    label: 'Y COORD',
                    value: state.mortarPosition.y,
                    onChanged: (v) => context.read<BallisticsCubit>().setMortarY(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CoordinateInput(
              label: 'ALTITUDE (optional)',
              value: state.mortarPosition.altitude,
              onChanged: (v) => context.read<BallisticsCubit>().setMortarAltitude(v),
              suffix: 'm',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(BuildContext context, BallisticsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.danger, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TARGET POSITION',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CoordinateInput(
                    label: 'X COORD',
                    value: state.targetPosition.x,
                    onChanged: (v) => context.read<BallisticsCubit>().setTargetX(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CoordinateInput(
                    label: 'Y COORD',
                    value: state.targetPosition.y,
                    onChanged: (v) => context.read<BallisticsCubit>().setTargetY(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CoordinateInput(
              label: 'ALTITUDE (optional)',
              value: state.targetPosition.altitude,
              onChanged: (v) => context.read<BallisticsCubit>().setTargetAltitude(v),
              suffix: 'm',
            ),
          ],
        ),
      ),
    );
  }
}
