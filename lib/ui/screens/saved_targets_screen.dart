import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../models/models.dart';
import '../../storage/storage.dart';
import '../widgets/firing_solution_card.dart';

class SavedTargetsScreen extends StatefulWidget {
  const SavedTargetsScreen({super.key});

  @override
  State<SavedTargetsScreen> createState() => _SavedTargetsScreenState();
}

class _SavedTargetsScreenState extends State<SavedTargetsScreen> {
  late StorageService _storage;
  List<SavedTarget> _targets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _storage = StorageService();
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    await _storage.initialize();
    final targets = await _storage.getSavedTargets();
    setState(() {
      _targets = targets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('SAVED TARGETS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_targets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete all',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _targets.isEmpty
              ? _buildEmptyState()
              : _buildTargetList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTargetDialog,
        icon: const Icon(Icons.add_location),
        label: const Text('ADD TARGET'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'NO SAVED TARGETS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a target',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _targets.length,
      itemBuilder: (context, index) {
        final target = _targets[index];
        return _TargetCard(
          target: target,
          onDelete: () => _deleteTarget(target.id),
          onEdit: () => _showEditTargetDialog(target),
          onLoad: () => _loadTarget(target),
        );
      },
    );
  }

  void _showAddTargetDialog() {
    final nameController = TextEditingController();
    final xController = TextEditingController();
    final yController = TextEditingController();
    final altController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('ADD TARGET', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Target Name',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: xController,
                      decoration: InputDecoration(
                        labelText: 'X',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: yController,
                      decoration: InputDecoration(
                        labelText: 'Y',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: altController,
                decoration: InputDecoration(
                  labelText: 'Altitude (optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                maxLines: 2,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  xController.text.isEmpty ||
                  yController.text.isEmpty) {
                return;
              }

              final target = SavedTarget(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                position: Position(
                  x: double.parse(xController.text),
                  y: double.parse(yController.text),
                  altitude: double.tryParse(altController.text) ?? 0,
                ),
                description: descController.text.isEmpty ? null : descController.text,
                createdAt: DateTime.now(),
              );

              await _storage.saveTarget(target);
              if (mounted) {
                Navigator.pop(context);
                _loadTargets();
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditTargetDialog(SavedTarget target) {
    final nameController = TextEditingController(text: target.name);
    final xController = TextEditingController(text: target.position.x.toString());
    final yController = TextEditingController(text: target.position.y.toString());
    final altController = TextEditingController(text: target.position.altitude.toString());
    final descController = TextEditingController(text: target.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('EDIT TARGET', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Target Name',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: xController,
                      decoration: InputDecoration(
                        labelText: 'X',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: yController,
                      decoration: InputDecoration(
                        labelText: 'Y',
                        labelStyle: TextStyle(color: AppTheme.textSecondary),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: altController,
                decoration: InputDecoration(
                  labelText: 'Altitude (optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                maxLines: 2,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = target.copyWith(
                name: nameController.text,
                position: Position(
                  x: double.parse(xController.text),
                  y: double.parse(yController.text),
                  altitude: double.tryParse(altController.text) ?? 0,
                ),
                description: descController.text.isEmpty ? null : descController.text,
              );

              await _storage.saveTarget(updated);
              if (mounted) {
                Navigator.pop(context);
                _loadTargets();
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _deleteTarget(String id) async {
    await _storage.deleteTarget(id);
    _loadTargets();
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete All Targets?', style: TextStyle(color: AppTheme.danger)),
        content: Text(
          'This will permanently delete all ${_targets.length} saved targets.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              for (final target in _targets) {
                await _storage.deleteTarget(target.id);
              }
              if (mounted) {
                Navigator.pop(context);
                _loadTargets();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  void _loadTarget(SavedTarget target) {
    // Navigate to numeric calculator with this target pre-filled
    // This would require passing data to the ballistics cubit
    context.push('/numeric');
  }
}

class _TargetCard extends StatelessWidget {
  final SavedTarget target;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onLoad;

  const _TargetCard({
    required this.target,
    required this.onDelete,
    required this.onEdit,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onLoad,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.danger),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                target.position.toGridReference(precision: 3),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.accent,
                  fontFamily: 'monospace',
                ),
              ),
              if (target.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  target.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (target.lastSolution != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                FiringSolutionCard(
                  solution: target.lastSolution!,
                  compact: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
