import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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

/// User model
///
/// Represents a user account with profile information and preferences
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final String? phoneNumber;
  final String? type;
  final String? bio;
  final String? restaurantId;
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
    this.restaurantId,
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

  /// Creates User from JSON
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
      restaurantId: json['restaurantId'] as String?,
      preferences: json['preferences'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['preferences']): null,
      createdAt: toDateTime(json['createdAt']),
      modifiedAt: toDateTime(json['modifiedAt']),
      lastLoginAt: toDateTime(json['lastLoginAt']),
      loginCount: json['loginCount'] as int?,
    );
  }

  /// Converts User to JSON
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
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (preferences != null) 'preferences': preferences,
    };
  }
}
