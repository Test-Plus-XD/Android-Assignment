/// Models Module
///
/// This file re-exports all model classes from their respective domain files.
/// Import this file to access all models in the application.
///
/// Organization:
/// - models/restaurant.dart - Restaurant model and related classes
/// - models/user.dart - User and UserPreferences models
/// - models/review.dart - Review models (Review, ReviewStats, requests)
/// - models/menu.dart - MenuItem models (MenuItem and request classes)
/// - models/booking.dart - Booking model
/// - models/chat.dart - Chat models (ChatRoom, ChatMessage, TypingIndicator)
/// - models/gemini.dart - AI/Gemini models for Google Gemini integration
/// - models/docupipe.dart - DocuPipe models for document processing
/// - models/search.dart - Search models (SearchResponse, FacetValue, AdvancedSearchRequest)
/// - models/image.dart - Image models (ImageMetadata)
library;

// Re-export all models
export 'models/restaurant.dart';
export 'models/user.dart';
export 'models/review.dart';
export 'models/menu.dart';
export 'models/booking.dart';
export 'models/chat.dart';
export 'models/gemini.dart';
export 'models/docupipe.dart';
export 'models/search.dart';
export 'models/image.dart';
