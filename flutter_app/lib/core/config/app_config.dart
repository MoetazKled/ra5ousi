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
  /// À remplacer par votre URL réelle en production.
  static const String supabaseUrl = 'https://your-project.supabase.co';
  
  /// Clé anonyme Supabase pour l'authentification publique.
  /// À remplacer par votre clé réelle en production.
  static const String supabaseAnonKey = 'your-anon-key';

  // ============================================================================
  // GOOGLE MAPS
  // ============================================================================
  
  /// Clé API Google Maps.
  /// À configurer dans la Google Cloud Console.
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

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
