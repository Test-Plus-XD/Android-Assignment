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
// NOTE: DistrictOption, KeywordOption, and PaymentOption models have been moved to:
// - lib/constants/districts.dart
// - lib/constants/keywords.dart
// - lib/constants/payments.dart
// Import those files to use the constants.

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
  });

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
    };
  }
}

// Review model (based on API.md Review structure)
class Review {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoURL;
  final String restaurantId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String? imageUrl;
  final DateTime dateTime;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Review({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoURL,
    required this.restaurantId,
    required this.rating,
    this.comment,
    this.imageUrl,
    required this.dateTime,
    this.createdAt,
    this.modifiedAt,
  });

  // Creates Review from JSON (API response)
  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String? ?? 'Anonymous',
      userPhotoURL: json['userPhotoURL'] as String?,
      restaurantId: json['restaurantId'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      imageUrl: json['imageUrl'] as String?,
      dateTime: parseDateTime(json['dateTime'] ?? json['createdAt']),
      createdAt: json['createdAt'] != null ? parseDateTime(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? parseDateTime(json['modifiedAt']) : null,
    );
  }

  // Converts Review to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      if (userPhotoURL != null) 'userPhotoURL': userPhotoURL,
      'restaurantId': restaurantId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Get star count as integer (1-5)
  int get starCount => rating.round();
}

// Review statistics model (from API.md)
class ReviewStats {
  final String restaurantId;
  final int totalReviews;
  final double averageRating;

  ReviewStats({
    required this.restaurantId,
    required this.totalReviews,
    required this.averageRating,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      restaurantId: json['restaurantId'] as String,
      totalReviews: json['totalReviews'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }
}

// Create review request model
class CreateReviewRequest {
  final String restaurantId;
  final double rating;
  final String? comment;
  final String? dateTime;

  CreateReviewRequest({
    required this.restaurantId,
    required this.rating,
    this.comment,
    this.dateTime,
    String? imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (dateTime != null) 'dateTime': dateTime,
    };
  }
}

// Update review request model
class UpdateReviewRequest {
  final double? rating;
  final String? comment;

  UpdateReviewRequest({this.rating, this.comment, String? imageUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;
    return data;
  }
}

// Booking model
class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  final String status; // pending/confirmed/completed/cancelled
  final String paymentStatus; // unpaid/paid/refunded
  final String? specialRequests;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  Booking({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.dateTime,
    required this.numberOfGuests,
    required this.status,
    required this.paymentStatus,
    this.specialRequests,
    this.createdAt,
    this.modifiedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      return DateTime.now();
    }

    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      restaurantId: json['restaurantId'] as String,
      restaurantName: json['restaurantName'] as String,
      dateTime: parseDateTime(json['dateTime']),
      numberOfGuests: json['numberOfGuests'] as int,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      specialRequests: json['specialRequests'] as String?,
      createdAt: json['createdAt'] != null ? parseDateTime(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? parseDateTime(json['modifiedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'dateTime': dateTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      'status': status,
      'paymentStatus': paymentStatus,
      if (specialRequests != null) 'specialRequests': specialRequests,
    };
  }
}

// MenuItem model (based on API.md Menu Item structure)
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

  // Creates MenuItem from JSON (API response)
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

  // Converts MenuItem to JSON for API requests
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

  // Returns menu item name in appropriate language
  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (nameTc ?? nameEn ?? 'Unknown')
        : (nameEn ?? nameTc ?? 'Unknown');
  }

  // Returns menu item description in appropriate language
  String getDisplayDescription(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (descriptionTc ?? descriptionEn ?? '')
        : (descriptionEn ?? descriptionTc ?? '');
  }

  // Formats price with currency symbol
  String getFormattedPrice() {
    if (price == null) return '';
    return 'HK\$${price!.toStringAsFixed(0)}';
  }
}

// Create menu item request model
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

// Update menu item request model
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

// ============================================================================
// Image Upload Models
// ============================================================================

/// Metadata for uploaded images
class ImageMetadata {
  final String name;
  final int size;
  final String contentType;
  final DateTime timeCreated;
  final DateTime updated;
  final String? downloadURL;

  ImageMetadata({
    required this.name,
    required this.size,
    required this.contentType,
    required this.timeCreated,
    required this.updated,
    this.downloadURL,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      name: json['name'] as String,
      size: json['size'] as int,
      contentType: json['contentType'] as String,
      timeCreated: DateTime.parse(json['timeCreated'] as String),
      updated: DateTime.parse(json['updated'] as String),
      downloadURL: json['downloadURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'contentType': contentType,
      'timeCreated': timeCreated.toIso8601String(),
      'updated': updated.toIso8601String(),
      if (downloadURL != null) 'downloadURL': downloadURL,
    };
  }

  /// Format file size in human-readable format
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ============================================================================
// CHAT MODELS
// ============================================================================

/// Chat room model representing a conversation between users
class ChatRoom {
  final String roomId;
  final List<String> participants;
  final String? roomName;
  final String type; // 'direct' or 'group'
  final String? createdBy;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int messageCount;
  final List<User>? participantsData;

  ChatRoom({
    required this.roomId,
    required this.participants,
    this.roomName,
    required this.type,
    this.createdBy,
    this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.messageCount = 0,
    this.participantsData,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    List<User>? participantsData;
    if (json['participantsData'] != null) {
      participantsData = (json['participantsData'] as List)
          .map((userData) => User.fromJson(userData as Map<String, dynamic>))
          .toList();
    }

    return ChatRoom(
      roomId: json['roomId'] as String,
      participants: (json['participants'] as List).map((e) => e.toString()).toList(),
      roomName: json['roomName'] as String?,
      type: json['type'] as String? ?? 'direct',
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt'] as String) : null,
      messageCount: json['messageCount'] as int? ?? 0,
      participantsData: participantsData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'participants': participants,
      if (roomName != null) 'roomName': roomName,
      'type': type,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      'messageCount': messageCount,
      if (participantsData != null) 'participantsData': participantsData!.map((u) => u.toJson()).toList(),
    };
  }

  /// Get room display name based on type and participants
  String getDisplayName(String currentUserId, bool isTraditionalChinese) {
    if (roomName != null && roomName!.isNotEmpty) {
      return roomName!;
    }

    if (type == 'group') {
      return isTraditionalChinese ? '群組聊天' : 'Group Chat';
    }

    // For direct chat, show the other participant's name
    if (participantsData != null && participantsData!.isNotEmpty) {
      final otherUser = participantsData!.firstWhere(
        (user) => user.uid != currentUserId,
        orElse: () => participantsData!.first,
      );
      return otherUser.displayName ?? otherUser.email ?? (isTraditionalChinese ? '未知用戶' : 'Unknown User');
    }

    return isTraditionalChinese ? '聊天' : 'Chat';
  }
}

/// Chat message model
class ChatMessage {
  final String messageId;
  final String roomId;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final bool edited;
  final bool deleted;
  final String? imageUrl;

  ChatMessage({
    required this.messageId,
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.message,
    required this.timestamp,
    this.edited = false,
    this.deleted = false,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      edited: json['edited'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'edited': edited,
      'deleted': deleted,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? messageId,
    String? roomId,
    String? userId,
    String? displayName,
    String? message,
    DateTime? timestamp,
    bool? edited,
    bool? deleted,
    String? imageUrl,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Typing indicator model
class TypingIndicator {
  final String roomId;
  final String userId;
  final String displayName;
  final bool isTyping;

  TypingIndicator({
    required this.roomId,
    required this.userId,
    required this.displayName,
    required this.isTyping,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      roomId: json['roomId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      isTyping: json['isTyping'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'userId': userId,
      'displayName': displayName,
      'isTyping': isTyping,
    };
  }
}

// ==================== AI/Gemini Models ====================

/// Chat history item for Gemini conversations
class GeminiChatHistory {
  final String role; // 'user' or 'model'
  final String content;

  GeminiChatHistory({
    required this.role,
    required this.content,
  });

  factory GeminiChatHistory.fromJson(Map<String, dynamic> json) {
    return GeminiChatHistory(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': [{'text': content}],
    };
  }
}

/// Request model for Gemini generate endpoint
class GeminiGenerateRequest {
  final String prompt;
  final String? model;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final int? topK;

  GeminiGenerateRequest({
    required this.prompt,
    this.model,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.topK,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'prompt': prompt,
    };
    if (model != null) json['model'] = model;
    if (temperature != null) json['temperature'] = temperature;
    if (maxTokens != null) json['maxTokens'] = maxTokens;
    if (topP != null) json['topP'] = topP;
    if (topK != null) json['topK'] = topK;
    return json;
  }
}

/// Response model for Gemini generate endpoint
class GeminiGenerateResponse {
  final String result;
  final String model;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  GeminiGenerateResponse({
    required this.result,
    required this.model,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });

  factory GeminiGenerateResponse.fromJson(Map<String, dynamic> json) {
    return GeminiGenerateResponse(
      result: json['result'] ?? '',
      model: json['model'] ?? 'gemini-2.5-flash-lite-preview-09-2025',
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
      totalTokens: json['totalTokens'],
    );
  }
}

/// Request model for Gemini chat endpoint
class GeminiChatRequest {
  final String message;
  final List<GeminiChatHistory>? history;
  final String? model;

  GeminiChatRequest({
    required this.message,
    this.history,
    this.model,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'message': message,
    };
    if (history != null) {
      json['history'] = history!.map((h) => h.toJson()).toList();
    }
    if (model != null) json['model'] = model;
    return json;
  }
}

/// Response model for Gemini chat endpoint
class GeminiChatResponse {
  final String result;
  final String model;
  final List<GeminiChatHistory>? history;

  GeminiChatResponse({
    required this.result,
    required this.model,
    this.history,
  });

  factory GeminiChatResponse.fromJson(Map<String, dynamic> json) {
    List<GeminiChatHistory>? historyList;
    if (json['history'] != null) {
      historyList = (json['history'] as List)
          .map((h) => GeminiChatHistory(
                role: h['role'] ?? 'user',
                content: h['parts'] != null && h['parts'].isNotEmpty
                    ? h['parts'][0]['text'] ?? ''
                    : '',
              ))
          .toList();
    }

    return GeminiChatResponse(
      result: json['result'] ?? '',
      model: json['model'] ?? 'gemini-2.5-flash-lite-preview-09-2025',
      history: historyList,
    );
  }
}

/// Request model for restaurant description generation
class GeminiRestaurantDescriptionRequest {
  final String name;
  final String? cuisine;
  final String? district;
  final List<String>? keywords;
  final String? language;

  GeminiRestaurantDescriptionRequest({
    required this.name,
    this.cuisine,
    this.district,
    this.keywords,
    this.language,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
    };
    if (cuisine != null) json['cuisine'] = cuisine;
    if (district != null) json['district'] = district;
    if (keywords != null) json['keywords'] = keywords;
    if (language != null) json['language'] = language;
    return json;
  }
}

/// Response model for restaurant description generation
class GeminiRestaurantDescriptionResponse {
  final String description;
  final Map<String, dynamic>? restaurant;

  GeminiRestaurantDescriptionResponse({
    required this.description,
    this.restaurant,
  });

  factory GeminiRestaurantDescriptionResponse.fromJson(
      Map<String, dynamic> json) {
    return GeminiRestaurantDescriptionResponse(
      description: json['description'] ?? '',
      restaurant: json['restaurant'],
    );
  }
}

// ============================================================================
// Advanced Search Models
// ============================================================================

/// Enhanced search response with pagination metadata
class SearchResponse {
  final List<Restaurant> hits;
  final int nbHits;
  final int page;
  final int nbPages;
  final int hitsPerPage;
  final String? processingTimeMS;

  SearchResponse({
    required this.hits,
    required this.nbHits,
    required this.page,
    required this.nbPages,
    required this.hitsPerPage,
    this.processingTimeMS,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      hits: (json['hits'] as List?)
              ?.map((hit) => Restaurant.fromJson(hit as Map<String, dynamic>))
              .toList() ??
          [],
      nbHits: json['nbHits'] ?? 0,
      page: json['page'] ?? 0,
      nbPages: json['nbPages'] ?? 0,
      hitsPerPage: json['hitsPerPage'] ?? 20,
      processingTimeMS: json['processingTimeMS']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hits': hits.map((h) => h.toJson()).toList(),
      'nbHits': nbHits,
      'page': page,
      'nbPages': nbPages,
      'hitsPerPage': hitsPerPage,
      if (processingTimeMS != null) 'processingTimeMS': processingTimeMS,
    };
  }

  bool get hasNextPage => page < nbPages - 1;
  bool get hasPreviousPage => page > 0;
  bool get isEmpty => hits.isEmpty;
  bool get isNotEmpty => hits.isNotEmpty;
}

/// Facet value with count for filtering
class FacetValue {
  final String value;
  final int count;

  FacetValue({
    required this.value,
    required this.count,
  });

  factory FacetValue.fromJson(Map<String, dynamic> json) {
    return FacetValue(
      value: json['value'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'count': count,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacetValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value ($count)';
}

/// Advanced search request with all filter options
class AdvancedSearchRequest {
  final String? query;
  final List<String>? districts;
  final List<String>? keywords;
  final int page;
  final int hitsPerPage;
  final String? aroundLatLng; // "lat,lng" format
  final int? aroundRadius; // in meters
  final Map<String, dynamic>? filters; // Custom filters

  AdvancedSearchRequest({
    this.query,
    this.districts,
    this.keywords,
    this.page = 0,
    this.hitsPerPage = 20,
    this.aroundLatLng,
    this.aroundRadius,
    this.filters,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'page': page,
      'hitsPerPage': hitsPerPage,
    };

    if (query != null && query!.isNotEmpty) {
      json['query'] = query;
    }
    if (districts != null && districts!.isNotEmpty) {
      json['districts'] = districts;
    }
    if (keywords != null && keywords!.isNotEmpty) {
      json['keywords'] = keywords;
    }
    if (aroundLatLng != null) {
      json['aroundLatLng'] = aroundLatLng;
    }
    if (aroundRadius != null) {
      json['aroundRadius'] = aroundRadius;
    }
    if (filters != null && filters!.isNotEmpty) {
      json['filters'] = filters;
    }

    return json;
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> params = {
      'page': page.toString(),
      'hitsPerPage': hitsPerPage.toString(),
    };

    if (query != null && query!.isNotEmpty) {
      params['query'] = query!;
    }
    if (districts != null && districts!.isNotEmpty) {
      params['districts'] = districts!.join(',');
    }
    if (keywords != null && keywords!.isNotEmpty) {
      params['keywords'] = keywords!.join(',');
    }
    if (aroundLatLng != null) {
      params['aroundLatLng'] = aroundLatLng!;
    }
    if (aroundRadius != null) {
      params['aroundRadius'] = aroundRadius.toString();
    }

    return params;
  }
}