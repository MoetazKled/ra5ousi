import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/theme_config.dart';
import 'core/router/app_router.dart';
import 'core/services/location_service.dart';

/// Point d'entrée principal de l'application PriceMap Tunisia.
/// 
/// Cette application permet aux utilisateurs de comparer les prix
/// de produits et services dans leur zone géographique.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration de l'orientation (portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialiser Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PriceMapApp(),
    ),
  );
}

/// Widget racine de l'application PriceMap Tunisia.
/// 
/// Utilise Riverpod pour la gestion d'état et GoRouter pour la navigation.
class PriceMapApp extends ConsumerWidget {
  const PriceMapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PriceMap Tunisia',
      debugShowCheckedModeBanner: false,
      
      // Configuration du thème
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Configuration du routeur
      routerConfig: router,
      
      // Localisation
      locale: const Locale('fr', 'TN'),
      supportedLocales: const [
        Locale('fr', 'TN'),
        Locale('ar', 'TN'),
      ],
      
      // Builder pour initialiser les services globaux
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Client Supabase accessible globalement.
final supabase = Supabase.instance.client;
