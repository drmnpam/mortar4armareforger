import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_cubit.dart';
import '../../ballistics/ballistics.dart';
import '../../storage/storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StorageService _storage;
  String _preferredMortar = 'M252';

  @override
  void initState() {
    super.initState();
    _storage = StorageService();
    _loadSettings();
  }

  void _loadSettings() async {
    await _storage.initialize();
    setState(() {
      _preferredMortar = _storage.getPreferredMortar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mortars = BallisticTables.availableMortars;
    final themeState = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Ballistics
            _SectionHeader('BALLISTICS'),

            Card(
              child: Column(
                children: [
                  // Preferred mortar
                  ListTile(
                    leading: Icon(Icons.explore, color: AppTheme.accent),
                    title: const Text('Preferred Mortar'),
                    subtitle: Text(_preferredMortar),
                    trailing: DropdownButton<String>(
                      value: _preferredMortar,
                      dropdownColor: AppTheme.surfaceLight,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: AppTheme.accent),
                      items: mortars.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style: TextStyle(color: AppTheme.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _preferredMortar = value);
                          _storage.setPreferredMortar(value);
                        }
                      },
                    ),
                  ),

                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.bolt, color: AppTheme.accent),
                    title: const Text('Charge Selection'),
                    subtitle: const Text('Always AUTO'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Display
            _SectionHeader('DISPLAY'),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.palette, color: AppTheme.accent),
                    title: const Text('Theme Mode'),
                    subtitle: const Text('Dark / Night (red)'),
                    trailing: SegmentedButton<AppThemeMode>(
                      segments: const [
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.night,
                          label: Text('Night'),
                          icon: Icon(Icons.nights_stay),
                        ),
                      ],
                      selected: {themeState.mode},
                      onSelectionChanged: (selection) {
                        context
                            .read<ThemeCubit>()
                            .setThemeMode(selection.first);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.contrast, color: AppTheme.accent),
                    title: const Text('High Contrast'),
                    subtitle: const Text('Enhanced visibility for outdoor use'),
                    value: themeState.highContrast,
                    activeColor: AppTheme.primary,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setHighContrast(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Data Management
            _SectionHeader('DATA MANAGEMENT'),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.save, color: AppTheme.accent),
                    title: const Text('Export Data'),
                    subtitle: const Text('Save all settings and targets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.restore, color: AppTheme.accent),
                    title: const Text('Import Data'),
                    subtitle: const Text('Restore from backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: AppTheme.danger),
                    title: Text('Clear All Data',
                        style: TextStyle(color: AppTheme.danger)),
                    subtitle:
                        const Text('Delete all saved targets and settings'),
                    onTap: _confirmClearData,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: About
            _SectionHeader('ABOUT'),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.explore, color: AppTheme.accent, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mortar Calculator',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Version 1.0.0',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A ballistic calculator for Arma Reforger. '
                      'Designed for offline use in the field.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported mortars: ${mortars.join(", ")}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      final data = await _storage.exportData();
      await Clipboard.setData(ClipboardData(text: data));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _importData() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title:
            Text('Import Data', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Paste exported data here...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
          ),
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _storage.importData(controller.text);
                if (mounted) {
                  Navigator.pop(context);
                  _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data imported successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title:
            Text('Clear All Data?', style: TextStyle(color: AppTheme.danger)),
        content: Text(
          'This will permanently delete all saved targets, settings, and calculation history.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _storage.clearAll();
              if (mounted) {
                Navigator.pop(context);
                _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}
