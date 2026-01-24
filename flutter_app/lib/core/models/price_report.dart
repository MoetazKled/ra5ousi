import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';

/// Modèle représentant un signalement de prix.
/// 
/// Contient les informations sur un prix signalé par un utilisateur
/// pour un produit dans un commerce donné.
class PriceReport extends Equatable {
  final String id;
  final String productId;
  final String? productName;
  final String vendorId;
  final String? vendorName;
  final String? vendorAddress;
  final LatLng? vendorLocation;
  final String userId;
  final String? userName;
  final double price;
  final String? unitId;
  final String? unitSymbol;
  final double quantity;
  final String currency;
  final bool isPromotion;
  final DateTime? promoEndDate;
  final String? photoUrl;
  final String? notes;
  final double confidenceScore;
  final int upvotes;
  final int downvotes;
  final bool isVerified;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Propriétés calculées
  final double? distanceMeters;
  final String? priceColor;

  const PriceReport({
    required this.id,
    required this.productId,
    this.productName,
    required this.vendorId,
    this.vendorName,
    this.vendorAddress,
    this.vendorLocation,
    required this.userId,
    this.userName,
    required this.price,
    this.unitId,
    this.unitSymbol,
    this.quantity = 1,
    this.currency = 'TND',
    this.isPromotion = false,
    this.promoEndDate,
    this.photoUrl,
    this.notes,
    this.confidenceScore = 0.5,
    this.upvotes = 0,
    this.downvotes = 0,
    this.isVerified = false,
    this.isActive = true,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.distanceMeters,
    this.priceColor,
  });

  /// Crée un PriceReport depuis un Map JSON (Supabase).
  factory PriceReport.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    if (json['latitude'] != null && json['longitude'] != null) {
      location = LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
    }

    return PriceReport(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name_fr'] as String? ?? json['product_name'] as String?,
      vendorId: json['vendor_id'] as String,
      vendorName: json['vendor_name'] as String?,
      vendorAddress: json['vendor_address'] as String?,
      vendorLocation: location,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      price: (json['price'] as num).toDouble(),
      unitId: json['unit_id'] as String?,
      unitSymbol: json['unit_symbol'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      currency: json['currency'] as String? ?? 'TND',
      isPromotion: json['is_promotion'] as bool? ?? false,
      promoEndDate: json['promo_end_date'] != null
          ? DateTime.parse(json['promo_end_date'] as String)
          : null,
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.5,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(Duration(days: AppConfig.priceValidityDays)),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      priceColor: json['price_color'] as String?,
    );
  }

  /// Convertit en Map JSON pour insertion.
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'vendor_id': vendorId,
      'user_id': userId,
      'price': price,
      'unit_id': unitId,
      'quantity': quantity,
      'currency': currency,
      'is_promotion': isPromotion,
      'promo_end_date': promoEndDate?.toIso8601String(),
      'photo_url': photoUrl,
      'notes': notes,
    };
  }

  /// Prix formaté avec devise.
  String get formattedPrice {
    final priceStr = price.toStringAsFixed(3);
    return '$priceStr ${AppConfig.currencySymbol}';
  }

  /// Prix formaté avec unité.
  String get formattedPriceWithUnit {
    final unit = unitSymbol ?? 'unité';
    return '${formattedPrice}/$unit';
  }

  /// Formate la distance de manière lisible.
  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  /// Score de confiance en pourcentage.
  int get confidencePercent => (confidenceScore * 100).round();

  /// Différence entre upvotes et downvotes.
  int get voteScore => upvotes - downvotes;

  /// Indique si le prix est encore valide.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Âge du signalement en texte.
  String get ageText {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else {
      return 'Il y a ${(diff.inDays / 7).floor()} semaine${diff.inDays >= 14 ? 's' : ''}';
    }
  }

  /// Copie avec modifications.
  PriceReport copyWith({
    String? id,
    String? productId,
    String? productName,
    String? vendorId,
    String? vendorName,
    String? vendorAddress,
    LatLng? vendorLocation,
    String? userId,
    String? userName,
    double? price,
    String? unitId,
    String? unitSymbol,
    double? quantity,
    String? currency,
    bool? isPromotion,
    DateTime? promoEndDate,
    String? photoUrl,
    String? notes,
    double? confidenceScore,
    int? upvotes,
    int? downvotes,
    bool? isVerified,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? distanceMeters,
    String? priceColor,
  }) {
    return PriceReport(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorAddress: vendorAddress ?? this.vendorAddress,
      vendorLocation: vendorLocation ?? this.vendorLocation,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      price: price ?? this.price,
      unitId: unitId ?? this.unitId,
      unitSymbol: unitSymbol ?? this.unitSymbol,
      quantity: quantity ?? this.quantity,
      currency: currency ?? this.currency,
      isPromotion: isPromotion ?? this.isPromotion,
      promoEndDate: promoEndDate ?? this.promoEndDate,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      priceColor: priceColor ?? this.priceColor,
    );
  }

  @override
  List<Object?> get props => [id, productId, vendorId, price, updatedAt];
}
