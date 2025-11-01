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
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0.0,
      keywordEn: (json['Keyword_EN'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keywordTc: (json['Keyword_TC'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      image: (json['Image'] != null ? 'assets/images/${json['Image']}' : 'assets/images/Placeholder.png'), // Use the image from JSON if it exists, otherwise use the placeholder.
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

// Model for user.
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

  // Create a User object from JSON.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}

// Model for a review.
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

// Load reviews from JSON assets.
Future<List<Review>> loadReviewsFromAssets() async {
  final String jsonString = await rootBundle.loadString('assets/sample_reviews.json');
  final List<dynamic> reviewList = json.decode(jsonString) as List<dynamic>;
  return reviewList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
}