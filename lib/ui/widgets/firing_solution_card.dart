import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';

/// Card displaying firing solution results
class FiringSolutionCard extends StatelessWidget {
  final FiringSolution solution;
  final bool compact;
  final VoidCallback? onSave;
  final VoidCallback? onCopy;

  const FiringSolutionCard({
    super.key,
    required this.solution,
    this.compact = false,
    this.onSave,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.explore, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'FIRING SOLUTION',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.accent,
                    ),
                  ),
                  const Spacer(),
                  if (solution.heightAdjusted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HEIGHT ADJ',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Main values - Azimuth and Elevation (largest)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMainValue(
                      context,
                      'AZIMUTH',
                      '${solution.azimuthDisplay} mil',
                      Icons.compass_calibration,
                      subValue: '${solution.azimuthDegreesDisplay}°',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: AppTheme.gridLine,
                  ),
                  Expanded(
                    child: _buildMainValue(
                      context,
                      'ELEVATION',
                      '${solution.elevationDisplay} mil',
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, indent: 16, endIndent: 16),
            
            // Secondary values
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSecondaryValue('CHARGE', '${solution.charge}'),
                  _buildSecondaryValue('DISTANCE', solution.distanceDisplay),
                  _buildSecondaryValue('TOF', solution.timeOfFlightDisplay),
                ],
              ),
            ),
            
            // Correction notice
            if (solution.correction != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        solution.correction!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onSave != null)
                    TextButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('SAVE TARGET'),
                    ),
                  if (onCopy != null)
                    TextButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('COPY'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactValue('AZ', solution.azimuthDisplay),
              _buildCompactValue('EL', solution.elevationDisplay),
              _buildCompactValue('CH', '${solution.charge}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                solution.distanceDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                solution.timeOfFlightDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainValue(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    String? subValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.accent,
            shadows: [
              Shadow(
                color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        if (subValue != null)
          Text(
            subValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
              color: AppTheme.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryValue(String label, String value) {
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
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactValue(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }
}
