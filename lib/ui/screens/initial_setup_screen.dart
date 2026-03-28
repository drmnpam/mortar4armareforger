import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../data/managers/map_data_manager.dart';
import '../../data/managers/ballistic_data_manager.dart';
import '../../storage/storage.dart';

/// Initial setup screen for first app launch
/// Guides user through selecting map and mortar type
class InitialSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const InitialSetupScreen({super.key, required this.onComplete});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final MapDataManager _mapManager = MapDataManager();
  final BallisticDataManager _ballisticManager = BallisticDataManager();
  final StorageService _storage = StorageService();
  
  bool _isLoading = true;
  int _currentStep = 0;
  
  String? _selectedMap;
  String? _selectedMortar;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _storage.initialize();
    await _mapManager.initialize();
    await _ballisticManager.initialize();
    
    // Copy default data to device on first run
    await _mapManager.copyDefaultsToDevice();
    await _ballisticManager.copyDefaultsToDevice();
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading data packs...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildMapSelectionStep();
      case 2:
        return _buildMortarSelectionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore,
            size: 80,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 32),
          Text(
            'MORTAR CALCULATOR',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Arma Reforger Fire Control System',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Let\'s set up your mortar calculator for first use.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('GET STARTED'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSelectionStep() {
    final maps = _mapManager.availableMaps;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 1: SELECT MAP',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the terrain you\'ll be operating on:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: maps.length,
              itemBuilder: (context, index) {
                final map = maps[index];
                final isSelected = _selectedMap == map.name;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? AppTheme.primary.withOpacity(0.2) : null,
                  child: InkWell(
                    onTap: () => setState(() => _selectedMap = map.name),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.map,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  map.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${map.worldSizeM.toInt()}m × ${map.worldSizeM.toInt()}m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                Text(
                                  map.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _selectedMap != null
                    ? () => setState(() => _currentStep = 2)
                    : null,
                child: const Text('NEXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMortarSelectionStep() {
    final mortars = _ballisticManager.availableMortars;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 2: SELECT MORTAR',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your mortar type:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.builder(
              itemCount: mortars.length,
              itemBuilder: (context, index) {
                final mortar = mortars[index];
                final table = _ballisticManager.getTable(mortar);
                final isSelected = _selectedMortar == mortar;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? AppTheme.primary.withOpacity(0.2) : null,
                  child: InkWell(
                    onTap: () => setState(() => _selectedMortar = mortar),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.explore,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mortar,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppTheme.accent : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (table != null) ...[
                                  Text(
                                    '${table.caliberMm}mm - ${table.origin}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    'Range: ${table.minRangeM.toInt()}m - ${table.maxRangeM.toInt()}m',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text('BACK'),
              ),
              ElevatedButton(
                onPressed: _selectedMortar != null ? _completeSetup : null,
                child: const Text('COMPLETE SETUP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _completeSetup() async {
    // Save preferences
    if (_selectedMap != null) {
      await _storage.setPreferredMap(_selectedMap!);
      await _mapManager.selectMap(_selectedMap!);
    }
    
    if (_selectedMortar != null) {
      await _storage.setPreferredMortar(_selectedMortar!);
      _ballisticManager.selectMortar(_selectedMortar!);
    }
    
    // Mark setup as complete
    await _storage.saveSetting('setup_complete', true);
    
    widget.onComplete();
  }
}
