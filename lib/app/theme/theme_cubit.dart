import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../storage/services/storage_service.dart';
import 'app_theme.dart';

class ThemeState extends Equatable {
  final AppThemeMode mode;
  final bool highContrast;

  const ThemeState({
    this.mode = AppThemeMode.dark,
    this.highContrast = false,
  });

  ThemeData get materialTheme => AppTheme.themeFor(
        mode: mode,
        highContrast: highContrast,
      );

  ThemeState copyWith({
    AppThemeMode? mode,
    bool? highContrast,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  @override
  List<Object?> get props => [mode, highContrast];
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _themeModeKey = 'theme_mode';
  static const _highContrastKey = 'high_contrast';

  final StorageService _storageService;

  ThemeCubit({required StorageService storageService})
      : _storageService = storageService,
        super(const ThemeState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _storageService.initialize();

    final modeSetting = _storageService.getSetting<String>(
          _themeModeKey,
          defaultValue: 'dark',
        ) ??
        'dark';
    final highContrast = _storageService.getSetting<bool>(
          _highContrastKey,
          defaultValue: false,
        ) ??
        false;

    final mode = modeSetting == 'night' ? AppThemeMode.night : AppThemeMode.dark;
    await _applyTheme(mode: mode, highContrast: highContrast, persist: false);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _applyTheme(
      mode: mode,
      highContrast: state.highContrast,
      persist: true,
    );
  }

  Future<void> setHighContrast(bool value) async {
    await _applyTheme(
      mode: state.mode,
      highContrast: value,
      persist: true,
    );
  }

  Future<void> _applyTheme({
    required AppThemeMode mode,
    required bool highContrast,
    required bool persist,
  }) async {
    AppTheme.setTheme(
      mode: mode,
      highContrast: highContrast,
    );

    emit(ThemeState(mode: mode, highContrast: highContrast));

    if (!persist) {
      return;
    }

    await _storageService.saveSetting(
      _themeModeKey,
      mode == AppThemeMode.night ? 'night' : 'dark',
    );
    await _storageService.saveSetting(_highContrastKey, highContrast);
  }
}
