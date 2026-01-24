import 'package:equatable/equatable.dart';

/// Modèle représentant un produit ou service.
/// 
/// Supporte une hiérarchie (parent/enfants) pour organiser
/// les produits en catégories (ex: Viande > Bœuf > Filet).
class Product extends Equatable {
  final String id;
  final String? parentId;
  final String nameFr;
  final String? nameAr;
  final String slug;
  final String? descriptionFr;
  final String? descriptionAr;
  final String? categoryId;
  final String? categoryName;
  final String? unitId;
  final String? unitSymbol;
  final String? barcode;
  final String? imageUrl;
  final Map<String, List<String>> aliases;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    this.parentId,
    required this.nameFr,
    this.nameAr,
    required this.slug,
    this.descriptionFr,
    this.descriptionAr,
    this.categoryId,
    this.categoryName,
    this.unitId,
    this.unitSymbol,
    this.barcode,
    this.imageUrl,
    this.aliases = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un Product depuis un Map JSON (Supabase).
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parser les aliases
    Map<String, List<String>> aliases = {};
    if (json['aliases'] != null) {
      final aliasMap = json['aliases'] as Map<String, dynamic>;
      aliases = aliasMap.map((key, value) => MapEntry(
        key,
        (value as List).cast<String>(),
      ));
    }

    return Product(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      nameFr: json['name_fr'] as String,
      nameAr: json['name_ar'] as String?,
      slug: json['slug'] as String,
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      unitId: json['unit_id'] as String?,
      unitSymbol: json['unit_symbol'] as String?,
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      aliases: aliases,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convertit en Map JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'slug': slug,
      'description_fr': descriptionFr,
      'description_ar': descriptionAr,
      'category_id': categoryId,
      'unit_id': unitId,
      'barcode': barcode,
      'image_url': imageUrl,
      'aliases': aliases,
      'is_active': isActive,
    };
  }

  /// Retourne le nom selon la locale.
  String getName({String locale = 'fr'}) {
    if (locale == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
      return nameAr!;
    }
    return nameFr;
  }

  /// Retourne la description selon la locale.
  String? getDescription({String locale = 'fr'}) {
    if (locale == 'ar' && descriptionAr != null) {
      return descriptionAr;
    }
    return descriptionFr;
  }

  /// Copie avec modifications.
  Product copyWith({
    String? id,
    String? parentId,
    String? nameFr,
    String? nameAr,
    String? slug,
    String? descriptionFr,
    String? descriptionAr,
    String? categoryId,
    String? categoryName,
    String? unitId,
    String? unitSymbol,
    String? barcode,
    String? imageUrl,
    Map<String, List<String>>? aliases,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      slug: slug ?? this.slug,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unitId: unitId ?? this.unitId,
      unitSymbol: unitSymbol ?? this.unitSymbol,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      aliases: aliases ?? this.aliases,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, nameFr, slug, updatedAt];
}
