import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modèle représentant un commerce/point de vente.
/// 
/// Contient toutes les informations d'un commerce y compris
/// sa localisation géographique pour l'affichage sur la carte.
class Vendor extends Equatable {
  final String id;
  final String? googlePlaceId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final LatLng location;
  final String? address;
  final String? city;
  final String? governorate;
  final String? phone;
  final String? website;
  final List<String> photoUrls;
  final Map<String, dynamic>? openingHours;
  final String? ownerId;
  final bool isVerified;
  final bool isActive;
  final double ratingAvg;
  final int ratingCount;
  final int priceReportCount;
  final DateTime? lastPriceUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Propriétés calculées pour la carte
  final double? distanceMeters;
  final String? priceColor; // 'green', 'orange', 'red'

  const Vendor({
    required this.id,
    this.googlePlaceId,
    required this.name,
    this.nameAr,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.location,
    this.address,
    this.city,
    this.governorate,
    this.phone,
    this.website,
    this.photoUrls = const [],
    this.openingHours,
    this.ownerId,
    this.isVerified = false,
    this.isActive = true,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.priceReportCount = 0,
    this.lastPriceUpdate,
    required this.createdAt,
    required this.updatedAt,
    this.distanceMeters,
    this.priceColor,
  });

  /// Crée un Vendor depuis un Map JSON (Supabase).
  factory Vendor.fromJson(Map<String, dynamic> json) {
    // Parser la localisation PostGIS
    LatLng location;
    if (json['latitude'] != null && json['longitude'] != null) {
      location = LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    } else if (json['location'] != null) {
      // Format PostGIS: POINT(lng lat) ou objet avec coordinates
      final loc = json['location'];
      if (loc is Map && loc['coordinates'] != null) {
        final coords = loc['coordinates'] as List;
        location = LatLng(coords[1].toDouble(), coords[0].toDouble());
      } else {
        // Position par défaut si parsing échoue
        location = const LatLng(36.8065, 10.1815);
      }
    } else {
      location = const LatLng(36.8065, 10.1815);
    }

    return Vendor(
      id: json['id'] as String,
      googlePlaceId: json['google_place_id'] as String?,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      location: location,
      address: json['address'] as String?,
      city: json['city'] as String?,
      governorate: json['governorate'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? [],
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      ownerId: json['owner_id'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      priceReportCount: json['price_report_count'] as int? ?? 0,
      lastPriceUpdate: json['last_price_update'] != null
          ? DateTime.parse(json['last_price_update'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      priceColor: json['price_color'] as String?,
    );
  }

  /// Convertit en Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'google_place_id': googlePlaceId,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'category_id': categoryId,
      'address': address,
      'city': city,
      'governorate': governorate,
      'phone': phone,
      'website': website,
      'photo_urls': photoUrls,
      'opening_hours': openingHours,
      'owner_id': ownerId,
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }

  /// Retourne la première photo ou null.
  String? get primaryPhoto => photoUrls.isNotEmpty ? photoUrls.first : null;

  /// Formate la distance de manière lisible.
  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  /// Copie avec modifications.
  Vendor copyWith({
    String? id,
    String? googlePlaceId,
    String? name,
    String? nameAr,
    String? description,
    String? categoryId,
    String? categoryName,
    LatLng? location,
    String? address,
    String? city,
    String? governorate,
    String? phone,
    String? website,
    List<String>? photoUrls,
    Map<String, dynamic>? openingHours,
    String? ownerId,
    bool? isVerified,
    bool? isActive,
    double? ratingAvg,
    int? ratingCount,
    int? priceReportCount,
    DateTime? lastPriceUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceMeters,
    String? priceColor,
  }) {
    return Vendor(
      id: id ?? this.id,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      governorate: governorate ?? this.governorate,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      photoUrls: photoUrls ?? this.photoUrls,
      openingHours: openingHours ?? this.openingHours,
      ownerId: ownerId ?? this.ownerId,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      priceReportCount: priceReportCount ?? this.priceReportCount,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      priceColor: priceColor ?? this.priceColor,
    );
  }

  @override
  List<Object?> get props => [id, name, location, updatedAt];
}
