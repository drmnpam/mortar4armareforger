import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.explore,
                            size: 64,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MORTAR CALCULATOR',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Arma Reforger Fire Control',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Main Menu Buttons
                    _MenuButton(
                      icon: Icons.calculate,
                      title: 'NUMERIC CALCULATOR',
                      subtitle: 'Enter coordinates manually',
                      onTap: () => context.push('/numeric'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _MenuButton(
                      icon: Icons.map,
                      title: 'MAP CALCULATOR',
                      subtitle: 'Visual map interface',
                      onTap: () => context.push('/map'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _MenuButton(
                      icon: Icons.table_chart,
                      title: 'BALLISTIC TABLES',
                      subtitle: 'View firing tables',
                      onTap: () => context.push('/tables'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _MenuButton(
                      icon: Icons.bookmark,
                      title: 'SAVED TARGETS',
                      subtitle: 'Manage target list',
                      onTap: () => context.push('/saved'),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/settings'),
                            icon: const Icon(Icons.settings),
                            label: const Text('SETTINGS'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'OFFLINE MODE',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
