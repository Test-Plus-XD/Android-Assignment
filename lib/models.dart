import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// Model for restaurant.
class Restaurant {
  final String nameEn;
  final String nameTc;
  final String addressEn;
  final String addressTc;
  final String districtEn;
  final String districtTc;
  final double latitude;
  final double longitude;
  final List<String> keywordEn;
  final List<String> keywordTc;
  final String image;

  Restaurant({
    required this.nameEn,
    required this.nameTc,
    required this.addressEn,
    required this.addressTc,
    required this.districtEn,
    required this.districtTc,
    required this.latitude,
    required this.longitude,
    required this.keywordEn,
    required this.keywordTc,
    required this.image,
  });

  // Create a Restaurant object from JSON.
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      nameEn: json['Name_EN'] ?? '',
      nameTc: json['Name_TC'] ?? '',
      addressEn: json['Address_EN'] ?? '',
      addressTc: json['Address_TC'] ?? '',
      districtEn: json['District_EN'] ?? '',
      districtTc: json['District_TC'] ?? '',
      latitude: (json['Latitude'] as num).toDouble(),
      longitude: (json['Longitude'] as num).toDouble(),
      keywordEn: (json['Keyword_EN'] as List<dynamic>).map((e) => e.toString()).toList(),
      keywordTc: (json['Keyword_TC'] as List<dynamic>).map((e) => e.toString()).toList(),
      image: 'assets/images/Placeholder.png', // Default placeholder image.
    );
  }
}

// Load restaurants from JSON assets.
Future<List<Restaurant>> loadRestaurantsFromAssets() async {
  final String jsonString = await rootBundle.loadString('assets/sample_restaurants.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
  final List<dynamic> restaurantList = jsonMap['restaurants'] as List<dynamic>;
  return restaurantList.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
}