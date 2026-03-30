import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import '../../models/models.dart';

/// Storage service for offline data persistence
class StorageService {
  static const String _savedTargetsBox = 'saved_targets';
  static const String _settingsBox = 'settings';
  static const String _mapStateBox = 'map_state';
  static const String _calcHistoryBox = 'calc_history';

  bool _initialized = false;

  /// Initialize Hive storage
  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox<String>(_savedTargetsBox);
    await Hive.openBox<dynamic>(_settingsBox);
    await Hive.openBox<String>(_mapStateBox);
    await Hive.openBox<String>(_calcHistoryBox);

    _initialized = true;
  }

  // ==================== SAVED TARGETS ====================

  /// Save a target
  Future<void> saveTarget(SavedTarget target) async {
    await initialize();
    final box = Hive.box<String>(_savedTargetsBox);
    await box.put(target.id, jsonEncode(target.toJson()));
  }

  /// Get all saved targets
  Future<List<SavedTarget>> getSavedTargets() async {
    await initialize();
    final box = Hive.box<String>(_savedTargetsBox);
    return box.values
        .map((json) => SavedTarget.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Delete a target
  Future<void> deleteTarget(String id) async {
    await initialize();
    final box = Hive.box<String>(_savedTargetsBox);
    await box.delete(id);
  }

  /// Update target with new solution
  Future<void> updateTargetSolution(String id, FiringSolution solution) async {
    await initialize();
    final box = Hive.box<String>(_savedTargetsBox);
    final json = box.get(id);
    if (json != null) {
      final target = SavedTarget.fromJson(jsonDecode(json));
      final updated = target.copyWith(lastSolution: solution);
      await box.put(id, jsonEncode(updated.toJson()));
    }
  }

  // ==================== SETTINGS ====================

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    await initialize();
    final box = Hive.box<dynamic>(_settingsBox);
    await box.put(key, value);
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_initialized) return defaultValue;
    final box = Hive.box<dynamic>(_settingsBox);
    final value = box.get(key, defaultValue: defaultValue);
    return value is T ? value : defaultValue;
  }

  /// Get preferred mortar type
  String getPreferredMortar() {
    return getSetting<String>('preferred_mortar', defaultValue: 'M252') ??
        'M252';
  }

  /// Save preferred mortar type
  Future<void> setPreferredMortar(String mortar) async {
    await saveSetting('preferred_mortar', mortar);
  }

  /// Get auto charge selection preference
  bool getAutoCharge() {
    return getSetting<bool>('auto_charge', defaultValue: true) ?? true;
  }

  /// Save auto charge preference
  Future<void> setAutoCharge(bool value) async {
    await saveSetting('auto_charge', value);
  }

  /// Get preferred map
  String? getPreferredMap() {
    return getSetting<String>('preferred_map');
  }

  /// Save preferred map
  Future<void> setPreferredMap(String? mapName) async {
    if (mapName != null) {
      await saveSetting('preferred_map', mapName);
    }
  }

  /// Get registered custom maps.
  List<Map<String, dynamic>> getCustomMaps() {
    final json = getSetting<String>('custom_maps');
    if (json == null || json.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Persist registered custom maps.
  Future<void> setCustomMaps(List<Map<String, dynamic>> maps) async {
    await saveSetting('custom_maps', jsonEncode(maps));
  }

  /// Get last mortar position
  Position? getLastMortarPosition() {
    final json = getSetting<String>('last_mortar_pos');
    if (json != null) {
      try {
        return Position.fromJson(jsonDecode(json));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Save last mortar position
  Future<void> setLastMortarPosition(Position position) async {
    await saveSetting('last_mortar_pos', jsonEncode(position.toJson()));
  }

  // ==================== MAP STATE ====================

  /// Save map state
  Future<void> saveMapState(String mapName, Map<String, dynamic> state) async {
    await initialize();
    final box = Hive.box<String>(_mapStateBox);
    await box.put(mapName, jsonEncode(state));
  }

  /// Load map state
  Map<String, dynamic>? loadMapState(String mapName) {
    if (!_initialized) return null;
    final box = Hive.box<String>(_mapStateBox);
    final json = box.get(mapName);
    if (json != null) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ==================== CALCULATION HISTORY ====================

  /// Add calculation to history
  Future<void> addToHistory(
      FiringSolution solution, Position mortar, Position target) async {
    await initialize();
    final box = Hive.box<String>(_calcHistoryBox);
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'solution': solution.toJson(),
      'mortar': mortar.toJson(),
      'target': target.toJson(),
    };

    final history = box.get('history');
    List<dynamic> list;
    if (history != null) {
      list = jsonDecode(history) as List<dynamic>;
      list.insert(0, entry);
      // Keep only last 50 entries
      if (list.length > 50) {
        list = list.sublist(0, 50);
      }
    } else {
      list = [entry];
    }

    await box.put('history', jsonEncode(list));
  }

  /// Get calculation history
  List<Map<String, dynamic>> getHistory() {
    if (!_initialized) return [];
    final box = Hive.box<String>(_calcHistoryBox);
    final history = box.get('history');
    if (history != null) {
      try {
        return (jsonDecode(history) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// Clear history
  Future<void> clearHistory() async {
    await initialize();
    final box = Hive.box<String>(_calcHistoryBox);
    await box.delete('history');
  }

  // ==================== UTILITIES ====================

  /// Clear all data
  Future<void> clearAll() async {
    await initialize();
    await Hive.box<String>(_savedTargetsBox).clear();
    await Hive.box<dynamic>(_settingsBox).clear();
    await Hive.box<String>(_mapStateBox).clear();
    await Hive.box<String>(_calcHistoryBox).clear();
  }

  /// Export all data as JSON
  Future<String> exportData() async {
    await initialize();
    final data = {
      'saved_targets': Hive.box<String>(_savedTargetsBox).values.toList(),
      'settings': Hive.box<dynamic>(_settingsBox).toMap(),
      'map_state': Hive.box<String>(_mapStateBox).toMap(),
      'history': Hive.box<String>(_calcHistoryBox).get('history'),
    };
    return jsonEncode(data);
  }

  /// Import data from JSON
  Future<void> importData(String jsonData) async {
    await initialize();
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    // Import saved targets
    if (data['saved_targets'] != null) {
      final box = Hive.box<String>(_savedTargetsBox);
      final targets = data['saved_targets'] as List<dynamic>;
      for (final target in targets) {
        final decoded = jsonDecode(target as String) as Map<String, dynamic>;
        await box.put(decoded['id'], target);
      }
    }

    // Import settings
    if (data['settings'] != null) {
      final box = Hive.box<dynamic>(_settingsBox);
      final settings = data['settings'] as Map<String, dynamic>;
      for (final entry in settings.entries) {
        await box.put(entry.key, entry.value);
      }
    }

    // Import map state
    if (data['map_state'] != null) {
      final box = Hive.box<String>(_mapStateBox);
      final mapStates = data['map_state'] as Map<String, dynamic>;
      for (final entry in mapStates.entries) {
        await box.put(entry.key, entry.value);
      }
    }

    // Import history
    if (data['history'] != null) {
      final box = Hive.box<String>(_calcHistoryBox);
      await box.put('history', data['history'] as String);
    }
  }

  /// Close all boxes
  Future<void> close() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
  }

  // ==================== NEW CALIBRATION SYSTEM ====================

  /// Save calibration mode setting
  Future<void> setCalibrationMode(String mode) async {
    await saveSetting('calibration_mode', mode);
  }

  /// Get calibration mode setting
  String? getCalibrationMode() {
    return getSetting<String>('calibration_mode');
  }

  /// Save map calibration data
  Future<void> saveMapCalibration(String mapName, Map<String, dynamic> calibration) async {
    await initialize();
    final box = Hive.box<String>(_mapStateBox);
    await box.put('${mapName}_calibration', jsonEncode(calibration));
  }

  /// Load map calibration data
  Map<String, dynamic>? loadMapCalibration(String mapName) {
    if (!_initialized) return null;
    final box = Hive.box<String>(_mapStateBox);
    final json = box.get('${mapName}_calibration');
    if (json != null) {
      try {
        return jsonDecode(json) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ==================== CUSTOM WEAPONS ====================

  /// Save custom weapons list
  Future<void> setCustomWeapons(List<Map<String, dynamic>> weapons) async {
    await initialize();
    final box = Hive.box<dynamic>(_settingsBox);
    await box.put('custom_weapons', jsonEncode(weapons));
  }

  /// Get custom weapons list
  List<Map<String, dynamic>> getCustomWeapons() {
    if (!_initialized) return [];
    final box = Hive.box<dynamic>(_settingsBox);
    final json = box.get('custom_weapons');
    if (json != null) {
      try {
        return (jsonDecode(json as String) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}
