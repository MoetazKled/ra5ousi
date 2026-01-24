/// Configuration de l'application PriceMap Tunisia.
/// 
/// Contient toutes les constantes de configuration comme les URLs,
/// clés API, et paramètres par défaut.
class AppConfig {
  AppConfig._();

  // ============================================================================
  // SUPABASE
  // ============================================================================
  
  /// URL du projet Supabase.
  static const String supabaseUrl = 'https://jygnfrvfrbkdvvgeykii.supabase.co';
  
  /// Clé anonyme Supabase pour l'authentification publique.
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5Z25mcnZmcmJrZHZ2Z2V5a2lpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkyODEyMTcsImV4cCI6MjA4NDg1NzIxN30.xmoC2KwfsmViP2iqQ6msEa9DZhhBT8U5hkW4bOZ3nyw';

  // ============================================================================
  // GOOGLE MAPS
  // ============================================================================
  
  /// Clé API Google Maps.
  static const String googleMapsApiKey = 'AIzaSyC01IA_Rc0rW8vQOZ_JU8nIK4nDLzD0j_A';

  // ============================================================================
  // LOCALISATION PAR DÉFAUT (Tunis, Tunisie)
  // ============================================================================
  
  /// Latitude par défaut (Centre de Tunis).
  static const double defaultLatitude = 36.8065;
  
  /// Longitude par défaut (Centre de Tunis).
  static const double defaultLongitude = 10.1815;
  
  /// Zoom par défaut sur la carte.
  static const double defaultZoom = 14.0;

  // ============================================================================
  // PARAMÈTRES DE RECHERCHE
  // ============================================================================
  
  /// Rayon de recherche par défaut en mètres.
  static const int defaultSearchRadiusMeters = 5000;
  
  /// Rayon minimum de recherche en mètres.
  static const int minSearchRadiusMeters = 500;
  
  /// Rayon maximum de recherche en mètres.
  static const int maxSearchRadiusMeters = 20000;
  
  /// Nombre maximum de résultats par recherche.
  static const int maxSearchResults = 50;

  // ============================================================================
  // PRIX & VALIDATION
  // ============================================================================
  
  /// Devise par défaut.
  static const String defaultCurrency = 'TND';
  
  /// Symbole de la devise.
  static const String currencySymbol = 'DT';
  
  /// Durée de validité d'un prix en jours.
  static const int priceValidityDays = 7;

  // ============================================================================
  // GAMIFICATION
  // ============================================================================
  
  /// Points pour un signalement de prix.
  static const int pointsForPriceReport = 10;
  
  /// Points bonus pour une photo.
  static const int pointsForPhoto = 5;
  
  /// Points pour un vote.
  static const int pointsForVote = 2;
  
  /// Points pour ajouter un commerce.
  static const int pointsForVendorAdd = 20;

  // ============================================================================
  // LIMITES
  // ============================================================================
  
  /// Taille maximale d'une image en octets (5 MB).
  static const int maxImageSizeBytes = 5 * 1024 * 1024;
  
  /// Nombre maximum de photos par signalement.
  static const int maxPhotosPerReport = 3;
}
