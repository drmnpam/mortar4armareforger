import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../weapons/weapon_registry.dart';
import '../../ballistics/weapon_tables.dart';
import '../../models/models.dart';

/// Numeric calculator screen for distance-based firing solution
/// User inputs distance, mortar altitude, and target altitude
/// App calculates elevation, charge, and time of flight using ballistic tables
class NumericCalculatorScreen extends StatefulWidget {
  const NumericCalculatorScreen({super.key});

  @override
  State<NumericCalculatorScreen> createState() => _NumericCalculatorScreenState();
}

class _NumericCalculatorScreenState extends State<NumericCalculatorScreen> {
  final _distanceController = TextEditingController();
  final _mortarAltController = TextEditingController();
  final _targetAltController = TextEditingController();
  final _milsController = TextEditingController();
  final _degreesController = TextEditingController();

  Weapon? _selectedWeapon;
  String? _selectedCharge;
  bool _autoCharge = true;
  List<Weapon> _availableWeapons = [];
  List<String> _availableCharges = [];

  FiringSolution? _solution;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeapons();
  }

  Future<void> _loadWeapons() async {
    await WeaponBallisticTables.initialize();
    final weapons = allWeapons;
    if (weapons.isNotEmpty) {
      setState(() {
        _availableWeapons = weapons;
        _selectedWeapon = weapons.first;
        _updateAvailableCharges();
      });
    }
  }

  void _updateAvailableCharges() {
    final weapon = _selectedWeapon;
    if (weapon != null && weapon.hasCharges) {
      _availableCharges = weapon.charges.map((c) => c.toString()).toList();
      if (_autoCharge) {
        _selectedCharge = null;
      } else {
        _selectedCharge = _availableCharges.first;
      }
    } else {
      _availableCharges = [];
      _selectedCharge = null;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _mortarAltController.dispose();
    _targetAltController.dispose();
    _milsController.dispose();
    _degreesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('NUMERIC CALCULATOR'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weapon selection
            _buildSectionTitle('WEAPON TYPE'),
            _buildWeaponSelector(),

            const SizedBox(height: 24),

            // Charge mode
            if (_availableCharges.isNotEmpty) ...[
              _buildSectionTitle('CHARGE MODE'),
              _buildChargeModeSelector(),
              const SizedBox(height: 24),
            ],

            // Manual charge selection if not auto
            if (!_autoCharge && _availableCharges.isNotEmpty) ...[
              _buildSectionTitle('CHARGE'),
              _buildChargeSelector(),
              const SizedBox(height: 24),
            ],

            // Inputs
            _buildSectionTitle('TARGET DATA'),
            _buildDistanceInput(),
            const SizedBox(height: 16),
            _buildAltitudeInputs(),

            const SizedBox(height: 32),

            // Azimuth Converter Section
            _buildSectionTitle('AZIMUTH CONVERTER'),
            _buildAzimuthConverter(),

            const SizedBox(height: 32),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.danger),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              ),

            // Calculate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                child: const Text('CALCULATE'),
              ),
            ),

            const SizedBox(height: 32),

            // Results
            if (_solution != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.accent,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildWeaponSelector() {
    if (_availableWeapons.isEmpty) {
      return const Text('Loading weapons...');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Weapon>(
          value: _selectedWeapon,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceLight,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          items: _availableWeapons.map((weapon) {
            return DropdownMenuItem<Weapon>(
              value: weapon,
              child: Text(weapon.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedWeapon = value;
                _updateAvailableCharges();
                _solution = null;
                _error = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildChargeModeSelector() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('AUTO'),
            selected: _autoCharge,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _autoCharge = true;
                  _selectedCharge = null;
                  _solution = null;
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('MANUAL'),
            selected: !_autoCharge,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _autoCharge = false;
                  if (_availableCharges.isNotEmpty) {
                    _selectedCharge = _availableCharges.first;
                  }
                  _solution = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChargeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCharge,
          isExpanded: true,
          dropdownColor: AppTheme.surfaceLight,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
          items: _availableCharges.map((charge) {
            return DropdownMenuItem(
              value: charge,
              child: Text('Charge $charge'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCharge = value;
              _solution = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDistanceInput() {
    return TextField(
      controller: _distanceController,
      decoration: const InputDecoration(
        labelText: 'Distance to target (meters)',
        hintText: 'Enter distance (e.g., 1500)',
        prefixIcon: Icon(Icons.straighten),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildAltitudeInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _mortarAltController,
            decoration: const InputDecoration(
              labelText: 'Mortar altitude (m)',
              hintText: '0',
              prefixIcon: Icon(Icons.location_on),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _targetAltController,
            decoration: const InputDecoration(
              labelText: 'Target altitude (m)',
              hintText: '0',
              prefixIcon: Icon(Icons.flag),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  void _calculate() {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final mortarAlt = double.tryParse(_mortarAltController.text) ?? 0;
    final targetAlt = double.tryParse(_targetAltController.text) ?? 0;

    if (distance <= 0) {
      setState(() {
        _error = 'Please enter a valid distance';
        _solution = null;
      });
      return;
    }

    if (_selectedWeapon == null) {
      setState(() {
        _error = 'Please select a weapon';
        _solution = null;
      });
      return;
    }

    // Get weapon info from registry
    final weapon = _selectedWeapon!;
    final minRange = weapon.minRange;
    final maxRange = weapon.maxRange;

    if (distance < minRange) {
      setState(() {
        _error = 'Below minimum range (${minRange.toStringAsFixed(0)}m)';
        _solution = null;
      });
      return;
    }

    if (distance > maxRange) {
      setState(() {
        _error = 'Out of range (max ${maxRange.toStringAsFixed(0)}m)';
        _solution = null;
      });
      return;
    }

    // Determine charge
    String? charge;
    if (_autoCharge) {
      charge = WeaponBallisticTables.selectCharge(weapon.tableId, distance);
    } else {
      charge = _selectedCharge;
    }

    if (charge == null && _availableCharges.isNotEmpty) {
      setState(() {
        _error = 'Cannot determine charge for this distance';
        _solution = null;
      });
      return;
    }

    // Get firing solution from ballistic table
    final solution = WeaponBallisticTables.getFiringSolution(
      weapon.tableId,
      distance,
      charge ?? '1',
    );

    if (solution == null) {
      setState(() {
        _error = 'Distance out of range for this weapon/charge';
        _solution = null;
      });
      return;
    }

    final heightDiff = targetAlt - mortarAlt;
    final int chargeNum = int.tryParse(charge ?? '1') ?? 1;

    setState(() {
      _error = null;
      _solution = FiringSolution(
        distance: distance,
        azimuth: 0,
        elevation: solution['elevation'] ?? 0,
        charge: chargeNum,
        timeOfFlight: solution['timeOfFlight'] ?? 0,
        heightDifference: heightDiff,
        mortarType: weapon.name,
        heightAdjusted: heightDiff.abs() > 1.0,
      );
      _selectedCharge = charge;
    });
  }

  Widget _buildResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIRING SOLUTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildResultRow('DISTANCE', '${_solution!.distance.toStringAsFixed(0)} m'),
            _buildResultRow('ELEVATION', '${_solution!.elevation.toStringAsFixed(0)} mils'),
            _buildResultRow('CHARGE', '${_solution!.charge}'),
            _buildResultRow('TIME OF FLIGHT', '${_solution!.timeOfFlight.toStringAsFixed(1)} s'),
            if (_solution!.heightAdjusted)
              _buildResultRow('HEIGHT DIFF', '${_solution!.heightDifference.toStringAsFixed(1)} m'),
          ],
        ),
      ),
    );
  }

  Widget _buildAzimuthConverter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine),
      ),
      child: Column(
        children: [
          // MILS input
          TextField(
            controller: _milsController,
            decoration: InputDecoration(
              labelText: 'Mils',
              hintText: 'Enter mils (0-6400)',
              prefixIcon: const Icon(Icons.explore),
              suffixText: 'mil',
              suffixStyle: TextStyle(color: AppTheme.textMuted),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final mils = double.tryParse(value);
              if (mils != null) {
                final degrees = mils * 0.05625;
                _degreesController.text = degrees.toStringAsFixed(1);
              } else {
                _degreesController.clear();
              }
            },
          ),
          const SizedBox(height: 12),
          // Arrow icon
          Icon(Icons.arrow_downward, color: AppTheme.textMuted, size: 20),
          const SizedBox(height: 12),
          // DEGREES input
          TextField(
            controller: _degreesController,
            decoration: InputDecoration(
              labelText: 'Degrees',
              hintText: 'Enter degrees (0-360)',
              prefixIcon: const Icon(Icons.compass_calibration),
              suffixText: '°',
              suffixStyle: TextStyle(color: AppTheme.textMuted),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final degrees = double.tryParse(value);
              if (degrees != null) {
                final mils = degrees * 17.7777778;
                _milsController.text = mils.round().toString();
              } else {
                _milsController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
