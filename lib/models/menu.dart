import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// MenuItem model (based on API.md Menu Item structure)
///
/// Represents a menu item with bilingual support and availability tracking
class MenuItem {
  final String id;
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? category;
  final String? image;
  final bool? available;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  MenuItem({
    required this.id,
    this.nameEn,
    this.nameTc,
    this.descriptionEn,
    this.descriptionTc,
    this.price,
    this.category,
    this.image,
    this.available,
    this.createdAt,
    this.modifiedAt,
  });

  /// Creates MenuItem from JSON (API response)
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return MenuItem(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String?,
      nameTc: json['nameTc'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      descriptionTc: json['descriptionTc'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      category: json['category'] as String?,
      image: json['image'] as String?,
      available: json['available'] as bool? ?? true,
      createdAt: parseDateTime(json['createdAt']),
      modifiedAt: parseDateTime(json['modifiedAt']),
    );
  }

  /// Converts MenuItem to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nameEn != null) 'nameEn': nameEn,
      if (nameTc != null) 'nameTc': nameTc,
      if (descriptionEn != null) 'descriptionEn': descriptionEn,
      if (descriptionTc != null) 'descriptionTc': descriptionTc,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (image != null) 'image': image,
      if (available != null) 'available': available,
    };
  }

  /// Returns menu item name in appropriate language
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (nameTc ?? nameEn ?? 'Unknown')
        : (nameEn ?? nameTc ?? 'Unknown');
  }

  /// Returns menu item description in appropriate language
  String getDisplayDescription(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (descriptionTc ?? descriptionEn ?? '')
        : (descriptionEn ?? descriptionTc ?? '');
  }

  /// Formats price with currency symbol
  String getFormattedPrice() {
    if (price == null) return '';
    return 'HK\$${price!.toStringAsFixed(0)}';
  }
}

/// Create menu item request model
///
/// Request payload for creating a new menu item
class CreateMenuItemRequest {
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? category;
  final String? image;
  final bool? available;

  CreateMenuItemRequest({
    this.nameEn,
    this.nameTc,
    this.descriptionEn,
    this.descriptionTc,
    this.price,
    this.category,
    this.image,
    this.available,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nameEn != null && nameEn!.isNotEmpty) 'nameEn': nameEn,
      if (nameTc != null && nameTc!.isNotEmpty) 'nameTc': nameTc,
      if (descriptionEn != null && descriptionEn!.isNotEmpty) 'descriptionEn': descriptionEn,
      if (descriptionTc != null && descriptionTc!.isNotEmpty) 'descriptionTc': descriptionTc,
      if (price != null) 'price': price,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (available != null) 'available': available,
    };
  }
}

/// Update menu item request model
///
/// Request payload for updating an existing menu item
class UpdateMenuItemRequest {
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? category;
  final String? image;
  final bool? available;

  UpdateMenuItemRequest({
    this.nameEn,
    this.nameTc,
    this.descriptionEn,
    this.descriptionTc,
    this.price,
    this.category,
    this.image,
    this.available,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (nameEn != null) data['nameEn'] = nameEn;
    if (nameTc != null) data['nameTc'] = nameTc;
    if (descriptionEn != null) data['descriptionEn'] = descriptionEn;
    if (descriptionTc != null) data['descriptionTc'] = descriptionTc;
    if (price != null) data['price'] = price;
    if (category != null) data['category'] = category;
    if (image != null) data['image'] = image;
    if (available != null) data['available'] = available;
    return data;
  }
}
