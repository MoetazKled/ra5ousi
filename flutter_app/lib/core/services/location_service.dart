import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';

/// État de la localisation de l'utilisateur.
class LocationState {
  final LatLng? currentPosition;
  final bool isLoading;
  final String? error;
  final bool permissionGranted;

  const LocationState({
    this.currentPosition,
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
  });

  LocationState copyWith({
    LatLng? currentPosition,
    bool? isLoading,
    String? error,
    bool? permissionGranted,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }

  /// Position par défaut (Tunis) si la localisation n'est pas disponible.
  LatLng get position => currentPosition ?? const LatLng(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );
}

/// Provider pour la gestion de la localisation.
final locationServiceProvider = StateNotifierProvider<LocationService, LocationState>((ref) {
  return LocationService();
});

/// Service de gestion de la géolocalisation.
/// 
/// Gère les permissions, récupère la position actuelle et fournit
/// des mises à jour en temps réel.
class LocationService extends StateNotifier<LocationState> {
  LocationService() : super(const LocationState());

  /// Vérifie et demande les permissions de localisation.
  Future<bool> checkAndRequestPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'Les services de localisation sont désactivés.',
          permissionGranted: false,
        );
        return false;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            error: 'Permission de localisation refusée.',
            permissionGranted: false,
          );
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          error: 'Permission de localisation définitivement refusée. '
                 'Veuillez l\'activer dans les paramètres.',
          permissionGranted: false,
        );
        return false;
      }

      state = state.copyWith(permissionGranted: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la vérification des permissions: $e',
      );
      return false;
    }
  }

  /// Récupère la position actuelle de l'utilisateur.
  Future<LatLng?> getCurrentPosition() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Vérifier les permissions d'abord
      if (!state.permissionGranted) {
        final hasPermission = await checkAndRequestPermission();
        if (!hasPermission) return null;
      }

      // Récupérer la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      
      state = state.copyWith(
        currentPosition: latLng,
        isLoading: false,
      );

      return latLng;
    } on LocationServiceDisabledException {
      state = state.copyWith(
        isLoading: false,
        error: 'Les services de localisation sont désactivés.',
      );
      return null;
    } on PermissionDeniedException {
      state = state.copyWith(
        isLoading: false,
        error: 'Permission de localisation refusée.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de récupérer la position: $e',
      );
      return null;
    }
  }

  /// Récupère la dernière position connue (plus rapide).
  Future<LatLng?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        final latLng = LatLng(position.latitude, position.longitude);
        state = state.copyWith(currentPosition: latLng);
        return latLng;
      }
    } catch (e) {
      // Ignorer l'erreur, on utilisera la position par défaut
    }
    return null;
  }

  /// Calcule la distance entre deux points en mètres.
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Formate une distance en chaîne lisible.
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Écoute les mises à jour de position en temps réel.
  Stream<LatLng> get positionStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Mise à jour tous les 50 mètres
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Ouvre les paramètres de localisation du système.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Ouvre les paramètres de l'application.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

/// Provider pour obtenir la position actuelle (simplifié).
final currentPositionProvider = FutureProvider<LatLng?>((ref) async {
  final locationService = ref.watch(locationServiceProvider.notifier);
  return locationService.getCurrentPosition();
});
