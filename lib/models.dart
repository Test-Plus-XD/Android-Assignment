import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/services.dart' show rootBundle;
import 'config.dart';

// Restaurant model with bilingual support
class Restaurant {
  final String id;
  final String? nameEn;
  final String? nameTc;
  final String? addressEn;
  final String? addressTc;
  final String? districtEn;
  final String? districtTc;
  final double? latitude;
  final double? longitude;
  final List<String>? keywordEn;
  final List<String>? keywordTc;
  final String? imageUrl;
  final Map<String, dynamic>? menu;
  final Map<String, dynamic>? openingHours;
  final int? seats;
  final Map<String, dynamic>? contacts;
  // Owner ID field for restaurant claiming feature
  final String? ownerId;

  Restaurant({
    required this.id,
    this.nameEn,
    this.nameTc,
    this.addressEn,
    this.addressTc,
    this.districtEn,
    this.districtTc,
    this.latitude,
    this.longitude,
    this.keywordEn,
    this.keywordTc,
    this.imageUrl,
    this.menu,
    this.openingHours,
    this.seats,
    this.contacts,
    this.ownerId,
  });

  // Creates Restaurant from JSON (handles both Algolia and API responses)
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert value to double
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Helper to safely convert value to int
    int? toInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to safely cast list of strings
    List<String>? toStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    // Helper to safely cast map
    Map<String, dynamic>? toMap(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    }

    final geoloc = json['_geoloc'] as Map?;
    String? imageUrl = json['ImageUrl'] as String? ?? json['imageUrl'] as String? ?? json['Image'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) imageUrl = AppConfig.placeholderUrl;

    return Restaurant(
      id: json['objectID']?.toString() ?? json['id']?.toString() ?? '',
      nameEn: json['Name_EN'] as String? ?? json['name_en'] as String?,
      nameTc: json['Name_TC'] as String? ?? json['name_tc'] as String?,
      addressEn: json['Address_EN'] as String? ?? json['address_en'] as String?,
      addressTc: json['Address_TC'] as String? ?? json['address_tc'] as String?,
      districtEn: json['District_EN'] as String? ?? json['district_en'] as String?,
      districtTc: json['District_TC'] as String? ?? json['district_tc'] as String?,
      latitude: toDouble(geoloc?['lat']) ?? toDouble(json['Latitude']) ?? toDouble(json['latitude']),
      longitude: toDouble(geoloc?['lng']) ?? toDouble(json['Longitude']) ?? toDouble(json['longitude']),
      keywordEn: toStringList(json['Keyword_EN'] ?? json['keyword_en']),
      keywordTc: toStringList(json['Keyword_TC'] ?? json['keyword_tc']),
      imageUrl: imageUrl,
      menu: toMap(json['Menu'] ?? json['menu']),
      openingHours: toMap(json['Opening_Hours'] ?? json['openingHours']),
      seats: toInt(json['Seats'] ?? json['seats']),
      contacts: toMap(json['Contacts'] ?? json['contacts']),
      ownerId: json['ownerId'] as String?,
    );
  }

  // Converts Restaurant to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Name_EN': nameEn,
      'Name_TC': nameTc,
      'Address_EN': addressEn,
      'Address_TC': addressTc,
      'District_EN': districtEn,
      'District_TC': districtTc,
      'Latitude': latitude,
      'Longitude': longitude,
      'Keyword_EN': keywordEn,
      'Keyword_TC': keywordTc,
      'ImageUrl': imageUrl,
      'Menu': menu,
      'Opening_Hours': openingHours,
      'Seats': seats,
      'Contacts': contacts,
      if (ownerId != null) 'ownerId': ownerId,
    };
  }

  // Returns restaurant name in appropriate language
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (nameTc ?? nameEn ?? 'Unknown')
        : (nameEn ?? nameTc ?? 'Unknown');
  }

  // Returns restaurant address in appropriate language
  String getDisplayAddress(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (addressTc ?? addressEn ?? 'Unknown')
        : (addressEn ?? addressTc ?? 'Unknown');
  }

  // Returns district name in appropriate language
  String getDisplayDistrict(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (districtTc ?? districtEn ?? 'Unknown')
        : (districtEn ?? districtTc ?? 'Unknown');
  }

  // Returns keywords in appropriate language
  List<String> getDisplayKeywords(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (keywordTc ?? keywordEn ?? [])
        : (keywordEn ?? keywordTc ?? []);
  }
}

// District filter option model
class DistrictOption {
  final String en;
  final String tc;

  const DistrictOption({required this.en, required this.tc});

  // Returns display label based on language preference
  String getLabel(bool isTraditionalChinese) {
    return isTraditionalChinese ? tc : en;
  }
}

// Hardcoded Hong Kong districts list
class HongKongDistricts {
  // All available districts with bilingual labels
  static const List<DistrictOption> all = [
    DistrictOption(en: 'Islands', tc: '離島'),
    DistrictOption(en: 'Kwai Tsing', tc: '葵青'),
    DistrictOption(en: 'North', tc: '北區'),
    DistrictOption(en: 'Sai Kung', tc: '西貢'),
    DistrictOption(en: 'Sha Tin', tc: '沙田'),
    DistrictOption(en: 'Tai Po', tc: '大埔'),
    DistrictOption(en: 'Tsuen Wan', tc: '荃灣'),
    DistrictOption(en: 'Tuen Mun', tc: '屯門'),
    DistrictOption(en: 'Yuen Long', tc: '元朗'),
    DistrictOption(en: 'Kowloon City', tc: '九龍城'),
    DistrictOption(en: 'Kwun Tong', tc: '觀塘'),
    DistrictOption(en: 'Sham Shui Po', tc: '深水埗'),
    DistrictOption(en: 'Wong Tai Sin', tc: '黃大仙'),
    DistrictOption(en: 'Yau Tsim Mong', tc: '油尖旺'),
    DistrictOption(en: 'Central and Western', tc: '中西區'),
    DistrictOption(en: 'Eastern', tc: '東區'),
    DistrictOption(en: 'Southern', tc: '南區'),
    DistrictOption(en: 'Wan Chai', tc: '灣仔'),
  ];

  // "All Districts" option for UI
  static const DistrictOption allDistricts =
  DistrictOption(en: 'All Districts', tc: '所有地區');

  // Returns full list including "All Districts" option
  static List<DistrictOption> get withAllOption => [allDistricts, ...all];

  // Finds district by English name
  static DistrictOption? findByEn(String en) {
    try {
      return all.firstWhere((d) => d.en == en);
    } catch (_) {
      return null;
    }
  }
}

// Keyword filter option model
class KeywordOption {
  final String en;
  final String tc;

  const KeywordOption({required this.en, required this.tc});

  // Returns display label based on language preference
  String getLabel(bool isTraditionalChinese) {
    return isTraditionalChinese ? tc : en;
  }
}

// Hardcoded keywords list (vegetarian/vegan restaurant types)
class RestaurantKeywords {
  // Common keywords for vegetarian restaurants
  static const List<KeywordOption> all = [
    KeywordOption(en: 'Vegan', tc: '全素'),
    KeywordOption(en: 'Vegetarian', tc: '素食'),
    KeywordOption(en: 'Plant-Based', tc: '植物性'),
    KeywordOption(en: 'Organic', tc: '有機'),
    KeywordOption(en: 'Buffet', tc: '自助餐'),
    KeywordOption(en: 'Chinese', tc: '中式'),
    KeywordOption(en: 'Western', tc: '西式'),
    KeywordOption(en: 'Japanese', tc: '日式'),
    KeywordOption(en: 'Thai', tc: '泰式'),
    KeywordOption(en: 'Indian', tc: '印度'),
  ];

  // "All Categories" option for UI
  static const KeywordOption allCategories =
  KeywordOption(en: 'All Categories', tc: '所有分類');

  // Returns full list including "All Categories" option
  static List<KeywordOption> get withAllOption => [allCategories, ...all];

  // Finds keyword by English name
  static KeywordOption? findByEn(String en) {
    try {
      return all.firstWhere((k) => k.en == en);
    } catch (_) {
      return null;
    }
  }
}

/// User preferences model
///
/// Provides structured access to user preference fields with default values
class UserPreferences {
  final String language;
  final bool notifications;
  final String theme;

  UserPreferences({
    required this.language,
    required this.notifications,
    required this.theme,
  });

  /// Creates UserPreferences from JSON with fallback defaults
  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserPreferences(
        language: 'EN',
        notifications: false,
        theme: 'light',
      );
    }
    return UserPreferences(
      language: json['language'] as String? ?? 'EN',
      notifications: json['notifications'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'light',
    );
  }

  /// Converts UserPreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'notifications': notifications,
      'theme': theme,
    };
  }

  /// Creates a copy with updated fields
  UserPreferences copyWith({
    String? language,
    bool? notifications,
    String? theme,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      notifications: notifications ?? this.notifications,
      theme: theme ?? this.theme,
    );
  }
}

// User model
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final String? phoneNumber;
  final String? type;
  final String? bio;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final DateTime? lastLoginAt;
  final int? loginCount;
  // Restaurant ID field for claimed restaurants
  final String? restaurantId;

  User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    this.phoneNumber,
    this.type,
    this.bio,
    this.preferences,
    this.createdAt,
    this.modifiedAt,
    this.lastLoginAt,
    this.loginCount,
    this.restaurantId,
  });

  // Checks if user is a restaurant owner type
  bool get isRestaurantOwner => type?.toLowerCase() == 'restaurant';

  // Checks if user is a diner type
  bool get isDiner => type?.toLowerCase() == 'diner';

  // Checks if user has claimed a restaurant
  bool get hasClaimedRestaurant => restaurantId != null && restaurantId!.isNotEmpty;

  /// Gets structured preferences with default values
  UserPreferences getPreferences() {
    return UserPreferences.fromJson(preferences);
  }

  // Creates User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse a DateTime string
    DateTime? toDateTime(dynamic value) {
      if (value is String) return DateTime.tryParse(value);
      // If the data is from Firestore, it might be a Timestamp
      if (value is Timestamp) return value.toDate();
      return null;
    }
    return User(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      type: json['type'] as String?,
      bio: json['bio'] as String?,
      preferences: json['preferences'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['preferences']): null,
      createdAt: toDateTime(json['createdAt']) != null ? DateTime.parse(json['createdAt'] as String) : null,
      modifiedAt: toDateTime(json['modifiedAt']) != null ? DateTime.parse(json['modifiedAt'] as String) : null,
      lastLoginAt: toDateTime(json['lastLoginAt']) != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      loginCount: json['loginCount'] as int?,
      restaurantId: json['restaurantId'] as String?,
    );
  }

  // Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (type != null) 'type': type,
      if (bio != null) 'bio': bio,
      if (preferences != null) 'preferences': preferences,
      if (restaurantId != null) 'restaurantId': restaurantId,
    };
  }
}

// Review model with enhanced fields for images and timestamps
class Review {
  final String? id;
  final String review;
  final String language;
  final String restaurantNameEn;
  final String restaurantNameTc;
  final String uid;
  final String? displayName;
  final String? photoURL;
  // Optional image URL for review photos
  final String? imageUrl;
  // Rating value (1-5 stars)
  final int? rating;
  // Restaurant ID reference
  final String? restaurantId;
  // Review creation timestamp
  final DateTime? dateTime;

  Review({
    this.id,
    required this.review,
    required this.language,
    required this.restaurantNameEn,
    required this.restaurantNameTc,
    required this.uid,
    this.displayName,
    this.photoURL,
    this.imageUrl,
    this.rating,
    this.restaurantId,
    this.dateTime,
  });

  // Creates Review from JSON with enhanced field handling
  factory Review.fromJson(Map<String, dynamic> json) {
    // Helper to parse DateTime from various formats
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return Review(
      id: json['id'] as String?,
      review: json['review'] ?? json['comment'] ?? '',
      language: json['language'] ?? '',
      restaurantNameEn: json['Name_EN'] ?? json['restaurantNameEn'] ?? '',
      restaurantNameTc: json['Name_TC'] ?? json['restaurantNameTc'] ?? '',
      uid: json['uid'] ?? json['userId'] ?? '',
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      imageUrl: json['imageUrl'] as String?,
      rating: json['rating'] as int?,
      restaurantId: json['restaurantId'] as String?,
      dateTime: parseDateTime(json['dateTime'] ?? json['createdAt']),
    );
  }

  // Converts Review to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'review': review,
      'language': language,
      'Name_EN': restaurantNameEn,
      'Name_TC': restaurantNameTc,
      'uid': uid,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (rating != null) 'rating': rating,
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (dateTime != null) 'dateTime': dateTime!.toIso8601String(),
    };
  }
}

// Loads reviews from JSON assets
Future<List<Review>> loadReviewsFromAssets() async {
  final String jsonString = await rootBundle.loadString('assets/sample_reviews.json');
  final List<dynamic> reviewList = json.decode(jsonString) as List<dynamic>;
  return reviewList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
}

// Chat message model for real-time messaging via Socket.IO
class ChatMessage {
  final String? id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  // Indicates if message contains an image URL
  final bool isImage;
  // Optional sender photo URL
  final String? senderPhotoUrl;

  ChatMessage({
    this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isImage = false,
    this.senderPhotoUrl,
  });

  // Creates ChatMessage from JSON response
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Helper to parse DateTime from various formats
    DateTime parseTimestamp(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return ChatMessage(
      id: json['id'] as String?,
      roomId: json['roomId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['userId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? json['displayName'] as String? ?? 'Anonymous',
      content: json['content'] as String? ?? json['message'] as String? ?? '',
      timestamp: parseTimestamp(json['timestamp'] ?? json['createdAt']),
      isImage: json['isImage'] as bool? ?? _isImageUrl(json['content'] as String? ?? ''),
      senderPhotoUrl: json['senderPhotoUrl'] as String? ?? json['photoURL'] as String?,
    );
  }

  // Converts ChatMessage to JSON for API/Socket requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isImage': isImage,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
    };
  }

  // Helper to detect if content is an image URL
  static bool _isImageUrl(String content) {
    final lowerContent = content.toLowerCase();
    return lowerContent.startsWith('http') &&
           (lowerContent.contains('.jpg') ||
            lowerContent.contains('.jpeg') ||
            lowerContent.contains('.png') ||
            lowerContent.contains('.gif') ||
            lowerContent.contains('firebasestorage'));
  }
}

// Gemini AI conversation message for maintaining chat history
class GeminiMessage {
  final String role;
  final String content;

  GeminiMessage({
    required this.role,
    required this.content,
  });

  // Creates message from JSON
  factory GeminiMessage.fromJson(Map<String, dynamic> json) {
    return GeminiMessage(
      role: json['role'] as String? ?? 'user',
      content: json['parts'] as String? ?? json['content'] as String? ?? '',
    );
  }

  // Converts to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': content,
    };
  }
}