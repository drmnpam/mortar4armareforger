import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_theme.dart';
import '../../ballistics/advanced_ballistics.dart';
import '../../models/models.dart';
import 'firing_solution_card.dart';

/// Bottom panel for firing solution display
/// Shows large azimuth and elevation numbers
class FiringSolutionPanel extends StatelessWidget {
  final FiringSolution solution;
  final VoidCallback? onCopy;
  final VoidCallback? onSave;
  final VoidCallback? onFire;
  final bool isFireMission;
  final String? missionStatus;

  const FiringSolutionPanel({
    super.key,
    required this.solution,
    this.onCopy,
    this.onSave,
    this.onFire,
    this.isFireMission = false,
    this.missionStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status bar
              if (missionStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign, size: 16, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        missionStatus!,
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Main values - Large display
              Row(
                children: [
                  // Azimuth - Left
                  Expanded(
                    child: _LargeValueDisplay(
                      label: 'AZIMUTH',
                      value: AzimuthCalculator.format(solution.azimuth),
                      subValue: AzimuthCalculator.getCardinalDirection(solution.azimuth),
                      icon: Icons.compass_calibration,
                    ),
                  ),
                  
                  // Divider
                  Container(
                    width: 1,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: AppTheme.gridLine,
                  ),
                  
                  // Elevation - Right
                  Expanded(
                    child: _LargeValueDisplay(
                      label: 'ELEVATION',
                      value: solution.elevation.toStringAsFixed(1),
                      subValue: '${solution.elevation.round()} mils',
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Secondary info row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoPill(
                      label: 'CHARGE',
                      value: '${solution.charge}',
                      color: AppTheme.warning,
                    ),
                    _InfoPill(
                      label: 'DIST',
                      value: '${solution.distance.toStringAsFixed(0)}m',
                    ),
                    _InfoPill(
                      label: 'TOF',
                      value: '${solution.timeOfFlight.toStringAsFixed(1)}s',
                    ),
                  ],
                ),
              ),
              
              // Correction notice
              if (solution.correction != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          solution.correction!,
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  // Copy button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('COPY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surfaceLight,
                        foregroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Save button
                  if (onSave != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('SAVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceLight,
                          foregroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  
                  if (isFireMission && onFire != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onFire,
                        icon: const Icon(Icons.campaign, size: 20),
                        label: const Text(
                          'FIRE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeValueDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;

  const _LargeValueDisplay({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Large value
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.accent,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppTheme.accent.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        
        // Sub value
        if (subValue != null)
          Text(
            subValue!,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoPill({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color?.withOpacity(0.2) ?? AppTheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: color != null
                ? Border.all(color: color!.withOpacity(0.3))
                : null,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: color ?? AppTheme.accent,
            ),
          ),
        ),
      ],
    );
  }
}
