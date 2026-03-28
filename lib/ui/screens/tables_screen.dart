import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../ballistics/ballistics.dart';
import '../widgets/ballistic_table_view.dart';

class TablesScreen extends StatelessWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize tables
    BallisticTables.initialize();
    final mortars = BallisticTables.availableMortars;
    
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
        length: mortars.length,
        child: Column(
          children: [
            // Tab bar for mortar types
            Container(
              color: AppTheme.surface,
              child: TabBar(
                isScrollable: true,
                tabs: mortars.map((mortar) {
                  return Tab(text: mortar);
                }).toList(),
                labelColor: AppTheme.accent,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.accent,
              ),
            ),
            
            // Tab views
            Expanded(
              child: TabBarView(
                children: mortars.map((mortar) {
                  return _MortarTableView(mortar: mortar);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MortarTableView extends StatelessWidget {
  final String mortar;

  const _MortarTableView({required this.mortar});

  @override
  Widget build(BuildContext context) {
    final tables = BallisticTables.getTables(mortar);
    
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
}
