import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/app_router.dart';
import 'theme/theme_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeCubit(
            storageService: _storageService,
          ),
        ),
        BlocProvider(
          create: (_) => BallisticsCubit(),
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
  }
}
