import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';

/// Table view for ballistic data
class BallisticTableView extends StatelessWidget {
  final BallisticTable table;
  final double? highlightRange;

  const BallisticTableView({
    super.key,
    required this.table,
    this.highlightRange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table info header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Range: ${table.minRange.toInt()}m - ${table.maxRange.toInt()}m | ${table.table.length} entries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'RANGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'ELEV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'TOF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Table rows
        ...table.table.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isHighlighted = highlightRange != null &&
              (row.range - highlightRange!).abs() < 50;
          final isEven = index % 2 == 0;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppTheme.primary.withOpacity(0.3)
                  : isEven
                      ? AppTheme.surface
                      : AppTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.gridLine,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${row.range.toInt()}m',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isHighlighted ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row.elevation.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isHighlighted ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${row.timeOfFlight.toStringAsFixed(1)}s',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: isHighlighted ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Compact table row for lists
class BallisticTableRow extends StatelessWidget {
  final BallisticRow row;
  final bool isHighlighted;

  const BallisticTableRow({
    super.key,
    required this.row,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted ? AppTheme.primary.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${row.range.toInt()}m',
            style: TextStyle(
              fontFamily: 'monospace',
              color: isHighlighted ? AppTheme.accent : AppTheme.textPrimary,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${row.elevation.toStringAsFixed(1)} mil',
            style: TextStyle(
              fontFamily: 'monospace',
              color: isHighlighted ? AppTheme.accent : AppTheme.textSecondary,
            ),
          ),
          Text(
            '${row.timeOfFlight.toStringAsFixed(1)}s',
            style: TextStyle(
              fontFamily: 'monospace',
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
