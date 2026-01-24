import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../main.dart';

/// État de l'authentification.
class AuthState {
  final User? user;
  final Map<String, dynamic>? profile;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? user,
    Map<String, dynamic>? profile,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearUser ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// L'utilisateur est-il connecté ?
  bool get isAuthenticated => user != null;

  /// Nom d'affichage de l'utilisateur.
  String get displayName {
    if (profile != null && profile!['display_name'] != null) {
      return profile!['display_name'] as String;
    }
    if (user?.email != null) {
      return user!.email!.split('@').first;
    }
    return 'Utilisateur';
  }

  /// Points de l'utilisateur.
  int get points => profile?['points'] as int? ?? 0;

  /// Niveau de l'utilisateur.
  int get level => profile?['level'] as int? ?? 1;

  /// Avatar URL.
  String? get avatarUrl => profile?['avatar_url'] as String?;
}

/// Provider principal pour l'authentification.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});

/// Notifier pour la gestion de l'authentification.
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _initialize();
  }

  /// Initialise l'état d'authentification.
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Écouter les changements d'auth
      supabase.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.session?.user);
      });

      // Vérifier la session actuelle
      final user = _service.currentUser;
      if (user != null) {
        await _loadUserProfile(user);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur d\'initialisation: $e');
    } finally {
      state = state.copyWith(isLoading: false, isInitialized: true);
    }
  }

  /// Gère les changements d'état d'authentification.
  Future<void> _handleAuthStateChange(User? user) async {
    if (user != null) {
      await _loadUserProfile(user);
    } else {
      state = state.copyWith(clearUser: true);
    }
  }

  /// Charge le profil utilisateur.
  Future<void> _loadUserProfile(User user) async {
    try {
      final profile = await _service.getCurrentUserProfile();
      state = state.copyWith(
        user: user,
        profile: profile,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        user: user,
        error: 'Erreur lors du chargement du profil',
      );
    }
  }

  /// Connexion avec email et mot de passe.
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.signInWithEmail(email, password);
      
      if (response.user != null) {
        await _loadUserProfile(response.user!);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de la connexion',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion: $e',
      );
      return false;
    }
  }

  /// Inscription avec email et mot de passe.
  Future<bool> signUpWithEmail(String email, String password, {String? displayName}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.signUpWithEmail(
        email,
        password,
        displayName: displayName,
      );
      
      if (response.user != null) {
        await _loadUserProfile(response.user!);
        return true;
      }
      
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de l\'inscription',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur d\'inscription: $e',
      );
      return false;
    }
  }

  /// Connexion avec Google.
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.signInWithGoogle();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de connexion Google: $e',
      );
    }
  }

  /// Déconnexion.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.signOut();
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur de déconnexion: $e',
      );
    }
  }

  /// Réinitialisation du mot de passe.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur: $e',
      );
      return false;
    }
  }

  /// Met à jour le profil.
  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? preferredLanguage,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _service.updateUserProfile(
        displayName: displayName,
        phone: phone,
        preferredLanguage: preferredLanguage,
      );

      // Recharger le profil
      if (state.user != null) {
        await _loadUserProfile(state.user!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur de mise à jour: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Recharge le profil utilisateur.
  Future<void> refreshProfile() async {
    if (state.user != null) {
      await _loadUserProfile(state.user!);
    }
  }

  /// Traduit les erreurs d'authentification Supabase.
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (message.contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email';
    }
    if (message.contains('User already registered')) {
      return 'Un compte existe déjà avec cet email';
    }
    if (message.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (message.contains('Invalid email')) {
      return 'Adresse email invalide';
    }
    return message;
  }
}

/// Provider pour vérifier si l'utilisateur est connecté.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider pour les statistiques de l'utilisateur.
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return {'points': 0, 'level': 1, 'price_reports_count': 0, 'votes_count': 0};
  }

  final service = ref.watch(supabaseServiceProvider);
  return service.getUserStats(authState.user!.id);
});
