import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/app_router.dart';
import 'theme/theme_cubit.dart';
import '../ballistics/ballistics.dart';
import '../ballistics/cubit/ballistics_cubit.dart';
import '../maps/cubit/map_cubit.dart';
import '../storage/services/storage_service.dart';

class MortarCalculatorApp extends StatefulWidget {
  const MortarCalculatorApp({super.key});

  @override
  State<MortarCalculatorApp> createState() => _MortarCalculatorAppState();
}

class _MortarCalculatorAppState extends State<MortarCalculatorApp> {
  late final StorageService _storageService;
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _storageService.initialize();
    BallisticTables.initialize();
    final customTables = await CustomBallisticTablesStorage.loadAll();
    BallisticTables.importCustomTables(customTables);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF0E1014),
              body: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ThemeCubit(
                storageService: _storageService,
              ),
            ),
            BlocProvider(
              create: (_) => BallisticsCubit(storage: _storageService),
            ),
            BlocProvider(
              create: (_) => MapCubit(
                storageService: _storageService,
              ),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              return MaterialApp.router(
                title: 'Mortar Calculator',
                debugShowCheckedModeBanner: false,
                theme: state.materialTheme,
                routerConfig: AppRouter.router,
              );
            },
          ),
        );
      },
    );
  }
}
