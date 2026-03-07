/// Advertisement model
///
/// Represents a restaurant advertisement with bilingual support (EN/TC).
/// Each ad is tied to a specific restaurant and created via a Stripe
/// checkout payment (HK$10 per advertisement).
///
/// Status values: active / inactive
///
/// API field mapping:
///   Title_EN / Title_TC     → titleEn / titleTc
///   Content_EN / Content_TC → contentEn / contentTc
///   Image_EN / Image_TC     → imageEn / imageTc
class Advertisement {
  final String id;
  // Bilingual title fields
  final String? titleEn;
  final String? titleTc;
  // Bilingual content/description fields
  final String? contentEn;
  final String? contentTc;
  // Bilingual image URLs (Firebase Storage)
  final String? imageEn;
  final String? imageTc;
  // Restaurant this advertisement belongs to
  final String restaurantId;
  // User who created this advertisement
  final String? userId;
  // Status: 'active' or 'inactive'
  final String status;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Advertisement({
    required this.id,
    this.titleEn,
    this.titleTc,
    this.contentEn,
    this.contentTc,
    this.imageEn,
    this.imageTc,
    required this.restaurantId,
    this.userId,
    required this.status,
    this.createdAt,
    this.modifiedAt,
  });

  /// Whether this advertisement is currently active and visible to users
  bool get isActive => status == 'active';

  /// Get the title in the preferred language, falling back to the other language
  String? getTitle({bool isTraditionalChinese = false}) {
    if (isTraditionalChinese) {
      return titleTc ?? titleEn;
    }
    return titleEn ?? titleTc;
  }

  /// Get the content in the preferred language, falling back to the other language
  String? getContent({bool isTraditionalChinese = false}) {
    if (isTraditionalChinese) {
      return contentTc ?? contentEn;
    }
    return contentEn ?? contentTc;
  }

  /// Get the image URL in the preferred language, falling back to the other language
  String? getImage({bool isTraditionalChinese = false}) {
    if (isTraditionalChinese) {
      return imageTc ?? imageEn;
    }
    return imageEn ?? imageTc;
  }

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] as String,
      titleEn: json['Title_EN'] as String?,
      titleTc: json['Title_TC'] as String?,
      contentEn: json['Content_EN'] as String?,
      contentTc: json['Content_TC'] as String?,
      imageEn: json['Image_EN'] as String?,
      imageTc: json['Image_TC'] as String?,
      restaurantId: json['restaurantId'] as String,
      userId: json['userId'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.tryParse(json['modifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (titleEn != null) 'Title_EN': titleEn,
      if (titleTc != null) 'Title_TC': titleTc,
      if (contentEn != null) 'Content_EN': contentEn,
      if (contentTc != null) 'Content_TC': contentTc,
      if (imageEn != null) 'Image_EN': imageEn,
      if (imageTc != null) 'Image_TC': imageTc,
      'restaurantId': restaurantId,
      if (userId != null) 'userId': userId,
      'status': status,
    };
  }
}

/// Request model for creating a new advertisement.
/// Used by AdvertisementService.createAdvertisement() to package form data
/// before sending to the API.
class CreateAdvertisementRequest {
  final String restaurantId;
  final String? titleEn;
  final String? titleTc;
  final String? contentEn;
  final String? contentTc;
  final String? imageEn;
  final String? imageTc;

  CreateAdvertisementRequest({
    required this.restaurantId,
    this.titleEn,
    this.titleTc,
    this.contentEn,
    this.contentTc,
    this.imageEn,
    this.imageTc,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      if (titleEn != null) 'Title_EN': titleEn,
      if (titleTc != null) 'Title_TC': titleTc,
      if (contentEn != null) 'Content_EN': contentEn,
      if (contentTc != null) 'Content_TC': contentTc,
      if (imageEn != null) 'Image_EN': imageEn,
      if (imageTc != null) 'Image_TC': imageTc,
    };
  }
}
