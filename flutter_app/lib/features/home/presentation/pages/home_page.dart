import 'package:flutter/material.dart';

/// Page d'accueil (placeholder).
/// 
/// Cette page peut être utilisée comme écran de bienvenue
/// ou redirigera directement vers la carte.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pour cette app, la page principale est la carte
    // Cette page peut servir d'onboarding ou de landing page
    return const Scaffold(
      body: Center(
        child: Text('Bienvenue sur PriceMap Tunisia'),
      ),
    );
  }
}
