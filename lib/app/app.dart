import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import '../ballistics/cubit/ballistics_cubit.dart';
import '../maps/cubit/map_cubit.dart';
import '../storage/services/storage_service.dart';

class MortarCalculatorApp extends StatelessWidget {
  const MortarCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => BallisticsCubit(),
        ),
        BlocProvider(
          create: (_) => MapCubit(
            storageService: StorageService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Mortar Calculator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
