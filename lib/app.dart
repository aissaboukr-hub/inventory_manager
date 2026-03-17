import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/config/routes.dart';
import 'package:inventory_manager/config/theme.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/data/repositories/inventory_repository_impl.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';
import 'package:inventory_manager/features/home/presentation/bloc/home_bloc.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase();
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<InventoryRepository>(
          create: (_) => InventoryRepositoryImpl(database),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => HomeBloc(
              repository: context.read<InventoryRepository>(),
            )..add(LoadInventoriesEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Inventory Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          localizationsDelegates: const [
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],
        ),
      ),
    );
  }
}