/// Configuration des variables d'environnement.
/// 
/// Ce fichier contient les clés API et configurations sensibles.
/// Dans un projet réel, ces valeurs devraient être injectées via :
/// - flutter run --dart-define=SUPABASE_URL=xxx
/// - Fichier .env avec flutter_dotenv
/// - Variables d'environnement CI/CD
class EnvConfig {
  EnvConfig._();

  // ============================================================================
  // SUPABASE
  // ============================================================================
  
  /// URL du projet Supabase.
  /// Projet: jygnfrvfrbkdvvgeykii
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jygnfrvfrbkdvvgeykii.supabase.co',
  );

  /// Clé anonyme Supabase.
  /// Récupérer depuis: Supabase Dashboard > Settings > API > anon key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // À remplir !
  );

  // ============================================================================
  // GOOGLE MAPS
  // ============================================================================
  
  /// Clé API Google Maps.
  /// Récupérer depuis: Google Cloud Console > Identifiants
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // À remplir !
  );

  // ============================================================================
  // VALIDATION
  // ============================================================================
  
  /// Vérifie que toutes les configurations sont présentes.
  static bool get isConfigured {
    return supabaseAnonKey.isNotEmpty && googleMapsApiKey.isNotEmpty;
  }

  /// Message d'erreur si la configuration est incomplète.
  static String get configurationError {
    final missing = <String>[];
    
    if (supabaseAnonKey.isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }
    if (googleMapsApiKey.isEmpty) {
      missing.add('GOOGLE_MAPS_API_KEY');
    }
    
    if (missing.isEmpty) return '';
    
    return 'Configuration manquante: ${missing.join(', ')}. '
           'Consultez SETUP_GUIDE.md pour les instructions.';
  }
}
