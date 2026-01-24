import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/contribute/presentation/pages/contribute_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/vendor/presentation/pages/vendor_detail_page.dart';
import '../widgets/main_scaffold.dart';

/// Provider pour le routeur de l'application.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentification
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      
      // Shell Route pour la navigation principale avec Bottom Nav
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // Onglet Explorer (Carte)
          GoRoute(
            path: '/explore',
            name: 'explore',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MapPage(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              // Détail d'un commerce
              GoRoute(
                path: 'vendor/:vendorId',
                name: 'vendor-detail',
                builder: (context, state) {
                  final vendorId = state.pathParameters['vendorId']!;
                  return VendorDetailPage(vendorId: vendorId);
                },
              ),
            ],
          ),
          
          // Onglet Recherche
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SearchPage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Onglet Contribuer
          GoRoute(
            path: '/contribute',
            name: 'contribute',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ContributePage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Onglet Profil
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
    ],
    
    // Gestion des erreurs
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'Une erreur est survenue',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Transition en fondu pour les changements d'onglets.
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation,
    child: child,
  );
}

/// Extension pour simplifier la navigation.
extension GoRouterExtension on BuildContext {
  /// Navigue vers la page d'exploration (carte).
  void goToExplore() => go('/explore');
  
  /// Navigue vers la recherche.
  void goToSearch() => go('/search');
  
  /// Navigue vers la contribution.
  void goToContribute() => go('/contribute');
  
  /// Navigue vers le profil.
  void goToProfile() => go('/profile');
  
  /// Navigue vers le détail d'un commerce.
  void goToVendor(String vendorId) => go('/explore/vendor/$vendorId');
  
  /// Affiche le modal d'ajout de prix.
  void showAddPriceModal() {
    // Sera implémenté avec le modal bottom sheet
  }
}
