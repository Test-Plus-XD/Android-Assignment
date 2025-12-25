import '../config.dart';

/// Restaurant model with bilingual support
///
/// Represents a restaurant with all its details including location,
/// contact information, opening hours, and multilingual content.
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

  /// Creates Restaurant from JSON (handles both Algolia and API responses)
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

  /// Converts Restaurant to JSON for API requests
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

  /// Returns restaurant name in appropriate language
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (nameTc ?? nameEn ?? 'Unknown')
        : (nameEn ?? nameTc ?? 'Unknown');
  }

  /// Returns restaurant address in appropriate language
  String getDisplayAddress(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (addressTc ?? addressEn ?? 'Unknown')
        : (addressEn ?? addressTc ?? 'Unknown');
  }

  /// Returns district name in appropriate language
  String getDisplayDistrict(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (districtTc ?? districtEn ?? 'Unknown')
        : (districtEn ?? districtTc ?? 'Unknown');
  }

  /// Returns keywords in appropriate language
  List<String> getDisplayKeywords(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (keywordTc ?? keywordEn ?? [])
        : (keywordEn ?? keywordTc ?? []);
  }
}
