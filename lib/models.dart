import 'dart:convert';
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

// User model
class User {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? phoneNumber;

  User({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
    this.phoneNumber,
  });

  // Creates User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  // Converts User to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
    };
  }
}

// Review model
class Review {
  final String review;
  final String language;
  final String restaurantNameEn;
  final String restaurantNameTc;
  final String uid;
  final String? displayName;
  final String? photoURL;

  Review({
    required this.review,
    required this.language,
    required this.restaurantNameEn,
    required this.restaurantNameTc,
    required this.uid,
    this.displayName,
    this.photoURL,
  });

  // Creates Review from JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      review: json['review'] ?? '',
      language: json['language'] ?? '',
      restaurantNameEn: json['Name_EN'] ?? '',
      restaurantNameTc: json['Name_TC'] ?? '',
      uid: json['uid'] ?? '',
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
    );
  }
}

// Loads reviews from JSON assets
Future<List<Review>> loadReviewsFromAssets() async {
  final String jsonString = await rootBundle.loadString('assets/sample_reviews.json');
  final List<dynamic> reviewList = json.decode(jsonString) as List<dynamic>;
  return reviewList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
}
