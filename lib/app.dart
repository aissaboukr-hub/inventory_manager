import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:inventory_manager/config/routes.dart';
import 'package:inventory_manager/config/theme.dart';
import 'package:inventory_manager/data/datasources/local/database.dart';
import 'package:inventory_manager/data/repositories/inventory_repository_impl.dart';
import 'package:inventory_manager/domain/repositories/inventory_repository.dart';
import 'package:inventory_manager/features/home/presentation/bloc/home_bloc.dart';
import 'package:inventory_manager/features/inventory/presentation/bloc/inventory_bloc.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase();

    // Material 3: Configuration système pour edge-to-edge
    _configureSystemUI();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<InventoryRepository>(
          create: (_) => InventoryRepositoryImpl(database),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              repository: context.read<InventoryRepository>(),
            )..add(const LoadInventoriesEvent()),
          ),
          BlocProvider<InventoryBloc>(
            create: (context) => InventoryBloc(
              repository: context.read<InventoryRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Inventory Manager',
          debugShowCheckedModeBanner: false,

          // Material 3: Thèmes définis dans theme.dart
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // Material 3: Page transitions Material par défaut
          // Pour Flutter 3.16+: Utilise MaterialPageTransitionsBuilder par défaut avec Material 3
          
          // Material 3: Scroll behavior optimisé
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),

          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,

          // Material 3: Localisation pour les composants Material
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
          ],

          // Material 3: Builder pour le système de navigation et scaffold
          builder: (context, child) {
            return MediaQuery(
              // Material 3: Respect des paddings système (notches, etc.)
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.zero,
              ),
              child: child!,
            );
          },
        ),
      ),
    );
  }

  /// Configure l'interface système pour Material 3 edge-to-edge
  void _configureSystemUI() {
    // Material 3: Mode edge-to-edge pour Android moderne
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // Material 3: Style de la barre de statut et navigation
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Transparent pour l'effet edge-to-edge
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        
        // Icônes sombres par défaut (s'adapte au thème)
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}