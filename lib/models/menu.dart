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

    // Handle both naming conventions: camelCase (nameEn) and snake_case (Name_EN)
    String? getNameEn() {
      return json['nameEn'] as String? ?? json['Name_EN'] as String?;
    }

    String? getNameTc() {
      return json['nameTc'] as String? ?? json['Name_TC'] as String?;
    }

    String? getDescriptionEn() {
      return json['descriptionEn'] as String? ?? json['Description_EN'] as String?;
    }

    String? getDescriptionTc() {
      return json['descriptionTc'] as String? ?? json['Description_TC'] as String?;
    }

    return MenuItem(
      id: json['id'] as String,
      nameEn: getNameEn(),
      nameTc: getNameTc(),
      descriptionEn: getDescriptionEn(),
      descriptionTc: getDescriptionTc(),
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
    // API expects Name_EN, Name_TC, Description_EN, Description_TC format
    return {
      if (nameEn != null && nameEn!.isNotEmpty) 'Name_EN': nameEn,
      if (nameTc != null && nameTc!.isNotEmpty) 'Name_TC': nameTc,
      if (descriptionEn != null && descriptionEn!.isNotEmpty) 'Description_EN': descriptionEn,
      if (descriptionTc != null && descriptionTc!.isNotEmpty) 'Description_TC': descriptionTc,
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
    // API expects Name_EN, Name_TC, Description_EN, Description_TC format
    final Map<String, dynamic> data = {};
    if (nameEn != null) data['Name_EN'] = nameEn;
    if (nameTc != null) data['Name_TC'] = nameTc;
    if (descriptionEn != null) data['Description_EN'] = descriptionEn;
    if (descriptionTc != null) data['Description_TC'] = descriptionTc;
    if (price != null) data['price'] = price;
    if (category != null) data['category'] = category;
    if (image != null) data['image'] = image;
    if (available != null) data['available'] = available;
    return data;
  }
}
