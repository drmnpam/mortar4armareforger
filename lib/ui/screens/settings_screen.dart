import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_cubit.dart';
import '../../ballistics/ballistics.dart';
import '../../models/models.dart';
import '../../storage/storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late StorageService _storage;
  String _preferredMortar = 'M252';
  CalibrationMode _calibrationMode = CalibrationMode.automatic;

  @override
  void initState() {
    super.initState();
    _storage = StorageService();
    _loadSettings();
  }

  void _loadSettings() async {
    await _storage.initialize();
    BallisticTables.initialize();
    final customTables = await CustomBallisticTablesStorage.loadAll();
    BallisticTables.importCustomTables(customTables);
    final mortars = BallisticTables.availableMortars;
    final preferred = _storage.getPreferredMortar();
    final selected = mortars.contains(preferred)
        ? preferred
        : (mortars.firstOrNull ?? 'M252');
    
    // Load calibration mode
    final modeJson = _storage.getCalibrationMode();
    final mode = CalibrationModeExtension.fromJson(modeJson ?? 'automatic');
    
    if (!mounted) return;
    setState(() {
      _preferredMortar = selected;
      _calibrationMode = mode;
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
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.table_chart, color: AppTheme.accent),
                    title: const Text('Add Custom Table'),
                    subtitle: const Text('Ballistic tables import/export JSON'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showBallisticTablesDialog,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.palette, color: AppTheme.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Theme Mode'),
                              SizedBox(height: 4),
                              Text('Dark / Night (red)'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: SegmentedButton<AppThemeMode>(
                              segments: const [
                                ButtonSegment<AppThemeMode>(
                                  value: AppThemeMode.dark,
                                  label: Text('Dark'),
                                ),
                                ButtonSegment<AppThemeMode>(
                                  value: AppThemeMode.night,
                                  label: Text('Night'),
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
                        ),
                      ],
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

            // Section: Grid Calibration
            _SectionHeader('GRID CALIBRATION'),

            Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.grid_on, color: AppTheme.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Calibration Mode'),
                              SizedBox(height: 4),
                              Text('100m reference or manual'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: SegmentedButton<CalibrationMode>(
                              segments: const [
                                ButtonSegment<CalibrationMode>(
                                  value: CalibrationMode.automatic,
                                  label: Text('Auto'),
                                ),
                                ButtonSegment<CalibrationMode>(
                                  value: CalibrationMode.manual,
                                  label: Text('Manual'),
                                ),
                              ],
                              selected: {_calibrationMode},
                              onSelectionChanged: (selection) {
                                final mode = selection.first;
                                setState(() => _calibrationMode = mode);
                                _storage.setCalibrationMode(mode.jsonValue);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Future<void> _showBallisticTablesDialog() async {
    String? selectedMortar = BallisticTables.customMortars.firstOrNull;
    String? localError;
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> importFromFile() async {
              try {
                setSheetState(() {
                  busy = true;
                  localError = null;
                });
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: const ['json'],
                );
                final path = result?.files.single.path;
                if (path == null || path.isEmpty) {
                  setSheetState(() => busy = false);
                  return;
                }

                final raw = await File(path).readAsString();
                final payloads = BallisticTables.parseImportPayload(raw);
                BallisticTables.importCustomTables(payloads);
                await CustomBallisticTablesStorage.saveAll(
                  BallisticTables.exportCustomTables(),
                );

                if (!mounted) return;
                setState(() {
                  if (!BallisticTables.availableMortars
                      .contains(_preferredMortar)) {
                    _preferredMortar =
                        BallisticTables.availableMortars.firstOrNull ?? 'M252';
                  }
                });
                setSheetState(() {
                  selectedMortar ??= BallisticTables.customMortars.firstOrNull;
                  busy = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Custom ballistic table imported')),
                );
              } catch (e) {
                setSheetState(() {
                  localError = 'Import failed: $e';
                  busy = false;
                });
              }
            }

            Future<void> exportAllCustomTables() async {
              try {
                setSheetState(() {
                  busy = true;
                  localError = null;
                });
                final payload =
                    BallisticTables.exportCustomTablesJson(pretty: true);
                final file = await CustomBallisticTablesStorage.exportToFile(
                  fileNamePrefix: 'custom_ballistic_tables',
                  jsonPayload: payload,
                );
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Custom ballistic tables export',
                );
                setSheetState(() => busy = false);
              } catch (e) {
                setSheetState(() {
                  localError = 'Export failed: $e';
                  busy = false;
                });
              }
            }

            Future<void> exportSelectedMortar() async {
              try {
                if (selectedMortar == null) {
                  setSheetState(() => localError = 'No custom mortar selected');
                  return;
                }
                setSheetState(() {
                  busy = true;
                  localError = null;
                });
                final payload =
                    BallisticTables.exportMortarAsJson(selectedMortar!);
                final file = await CustomBallisticTablesStorage.exportToFile(
                  fileNamePrefix: selectedMortar!,
                  jsonPayload:
                      const JsonEncoder.withIndent('  ').convert(payload),
                );
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Ballistic table: $selectedMortar',
                );
                setSheetState(() => busy = false);
              } catch (e) {
                setSheetState(() {
                  localError = 'Export failed: $e';
                  busy = false;
                });
              }
            }

            final customMortars = BallisticTables.customMortars;
            final allMortars = BallisticTables.availableMortars;
            if (selectedMortar != null &&
                !customMortars.contains(selectedMortar)) {
              selectedMortar = customMortars.firstOrNull;
            }

            return SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: 760,
                    maxHeight: MediaQuery.of(context).size.height * 0.70,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.gridLine),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'BALLISTIC TABLES',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Text(
                          'Import and export custom mortar tables as JSON files.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: busy ? null : importFromFile,
                                icon: const Icon(Icons.file_open),
                                label: const Text('IMPORT JSON'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: busy ? null : exportAllCustomTables,
                                icon: const Icon(Icons.ios_share),
                                label: const Text('EXPORT ALL CUSTOM'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (customMortars.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: selectedMortar,
                            decoration: const InputDecoration(
                              labelText: 'Export custom mortar',
                            ),
                            items: customMortars
                                .map(
                                  (mortar) => DropdownMenuItem(
                                    value: mortar,
                                    child: Text(mortar),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (value) {
                                    setSheetState(() => selectedMortar = value);
                                  },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy ? null : exportSelectedMortar,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('EXPORT SELECTED'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'Available mortars (${allMortars.length}): ${allMortars.join(", ")}',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          customMortars.isEmpty
                              ? 'Custom mortars: none'
                              : 'Custom mortars (${customMortars.length}): ${customMortars.join(", ")}',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        if (localError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            localError!,
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
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
