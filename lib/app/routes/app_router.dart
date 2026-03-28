import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ui/screens/main_screen.dart';
import '../../ui/screens/numeric_calculator_screen.dart';
import '../../ui/screens/map_calculator_screen.dart';
import '../../ui/screens/tables_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/saved_targets_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/numeric',
        name: 'numeric',
        builder: (context, state) => const NumericCalculatorScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapCalculatorScreen(),
      ),
      GoRoute(
        path: '/tables',
        name: 'tables',
        builder: (context, state) => const TablesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/saved',
        name: 'saved',
        builder: (context, state) => const SavedTargetsScreen(),
      ),
    ],
  );
}
