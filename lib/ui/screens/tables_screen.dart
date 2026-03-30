import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../weapons/weapon_registry.dart';
import '../../ballistics/ballistics.dart';
import '../widgets/ballistic_table_view.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize tables
    BallisticTables.initialize();
    
    // Use weapon registry for all weapons
    final weapons = allWeapons;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('BALLISTIC TABLES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: DefaultTabController(
        length: weapons.length,
        child: Column(
          children: [
            // Tab bar for all weapon types
            Container(
              color: AppTheme.surface,
              child: TabBar(
                isScrollable: true,
                tabs: weapons.map((weapon) {
                  return Tab(text: weapon.name);
                }).toList(),
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accent,
              ),
            ),
            
            // Tab views
            Expanded(
              child: TabBarView(
                children: weapons.map((weapon) {
                  return _WeaponTableView(weapon: weapon);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeaponTableView extends StatelessWidget {
  final Weapon weapon;

  const _WeaponTableView({required this.weapon});

  @override
  Widget build(BuildContext context) {
    // Mortars show charge tabs
    if (weapon.type == WeaponType.mortar) {
      final tables = BallisticTables.getTables(weapon.tableId);
      if (tables.isEmpty) {
        return _buildNoDataView(weapon);
      }
      
      return DefaultTabController(
        length: tables.length,
        child: Column(
          children: [
            // Charge tabs
            Container(
              color: AppTheme.surfaceLight,
              child: TabBar(
                isScrollable: true,
                tabs: tables.map((table) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('CH ${table.charge}'),
                        const SizedBox(width: 4),
                        Text(
                          '${table.minRange.toInt()}-${table.maxRange.toInt()}m',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accent,
              ),
            ),
            
            // Table views
            Expanded(
              child: TabBarView(
                children: tables.map((table) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: BallisticTableView(table: table),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }
    
    // Artillery - single table view
    if (weapon.type == WeaponType.artillery) {
      return _ArtilleryTableView(weapon: weapon);
    }
    
    // Angle tables (D30)
    if (weapon.type == WeaponType.angleTable) {
      return _AngleTableView(weapon: weapon);
    }
    
    return _buildNoDataView(weapon);
  }
  
  Widget _buildNoDataView(Weapon weapon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No ballistic table data for ${weapon.name}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtilleryTableView extends StatelessWidget {
  final Weapon weapon;

  const _ArtilleryTableView({required this.weapon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Artillery Table',
            weapon.name,
            '${weapon.minRange.toInt()} - ${weapon.maxRange.toInt()} meters',
          ),
          const SizedBox(height: 16),
          Text(
            'Range → Elevation → Time of Flight',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildPlaceholderTable(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String subtitle, String range) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Effective Range: $range',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderTable() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction,
                size: 48,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Artillery table loading from WeaponBallisticTables',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AngleTableView extends StatelessWidget {
  final Weapon weapon;

  const _AngleTableView({required this.weapon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Angle Table',
            weapon.name,
            '${weapon.minRange.toInt()} - ${weapon.maxRange.toInt()} meters',
          ),
          const SizedBox(height: 16),
          Text(
            'Range → Angle',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildPlaceholderTable(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String subtitle, String range) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Effective Range: $range',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderTable() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.construction,
                size: 48,
                color: AppTheme.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Angle table loading from WeaponBallisticTables',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
