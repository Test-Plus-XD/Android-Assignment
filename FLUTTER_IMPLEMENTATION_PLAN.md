# Flutter Native Android Implementation Plan - PourRice

> **Project:** PourRice Restaurant Discovery Application (Native Android)
> **Platform:** Android (Native features prioritized)
> **Target:** Match or exceed Ionic v1.7.0 feature set
> **Last Updated:** 2025-12-24
> **API Documentation:** `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md`
> **API Backend:** Vercel Express (https://vercel-express-api-alpha.vercel.app)
> **Socket.IO Server:** Railway (https://railway-socket-production.up.railway.app)
> **Maps:** Google Maps (Native Android)

---

## 🤖 AI Agent Instructions

This document is designed for AI agents to implement features systematically. When implementing:

1. **Reference API Documentation First:** Always check `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md` for:
   - Exact endpoint paths and HTTP methods
   - Required headers (`x-api-passcode: PourRice`, `Authorization: Bearer <token>`)
   - Request/response formats
   - Authentication requirements
   - Error response formats

2. **Follow Native Android Patterns:** This app uses:
   - Android-specific features (notifications, GPS, camera)
   - Google Maps SDK (NOT Leaflet or flutter_map)
   - Material Design 3
   - Provider state management

3. **Implementation Order:** Follow priority order below (Reviews → Menu → Chat → AI → Booking)

4. **Code Standards:**
   - All API calls must include proper headers
   - All DateTime must be ISO 8601 formatted
   - Bilingual support (EN/TC) for all user-facing strings
   - Error handling with user-friendly messages
   - Loading states for all async operations

5. **Testing Requirements:**
   - Test with real API endpoints (no mocks in production code)
   - Verify bilingual display
   - Test error scenarios
   - Verify authentication flows

---

## Table of Contents
1. [Current State Analysis](#current-state-analysis)
2. [Missing Features Gap Analysis](#missing-features-gap-analysis)
3. [Implementation Roadmap](#implementation-roadmap)
4. [Detailed Implementation Guide](#detailed-implementation-guide)
5. [Architecture & Design Patterns](#architecture--design-patterns)
6. [API Integration Reference](#api-integration-reference)
7. [Testing Strategy](#testing-strategy)
8. [Performance Optimization](#performance-optimization)

---

## Current State Analysis

### What Flutter Project Has ✅
- ✅ Firebase Authentication (Email/Password, Google OAuth)
- ✅ User profile management with API integration
- ✅ Restaurant search via Algolia
- ✅ Basic restaurant list and detail views
- ✅ Bilingual support (EN/TC) with toggle
- ✅ Dark/light theme with toggle
- ✅ Bottom navigation (Home, Search, Account)
- ✅ Drawer navigation
- ✅ Location services (GPS, distance calculation)
- ✅ Notification service structure (channels setup)
- ✅ Provider state management
- ✅ Basic models (Restaurant, User, Review)
- ✅ Config management (API URLs, Algolia)

### What Ionic Project Has (Missing from Flutter) ❌

**High Priority (Native Android Features):**
- ✅ **Review System** - Create, update, delete reviews with rating ⭐ **PRIORITY 1** ✅ COMPLETED
- ✅ **Menu Management** - View and manage restaurant menus (sub-collection) ⭐ **PRIORITY 2** ✅ COMPLETED
- ✅ **Image Upload** - Firebase Storage integration with Android camera/gallery ⭐ **PRIORITY 3** ✅ COMPLETED
- ✅ **Real-time Chat** - Socket.IO integration for chat ⭐ **PRIORITY 4** ✅ COMPLETED
- ✅ **AI Assistant** - Google Gemini integration ⭐ **PRIORITY 5** ✅ COMPLETED
- ✅ **Interactive Maps** - Google Maps with markers and info windows ⭐ **PRIORITY 6** ✅ COMPLETED (Already implemented)
- ✅ **Restaurant Detail Page** - Enhanced with hero image, info cards, opening hours ⭐ **PRIORITY 7** ✅ COMPLETED
- ✅ **Restaurant Owner Dashboard** - Store management with claim functionality ⭐ **PRIORITY 8** ✅ COMPLETED

**Medium Priority:**
- ✅ **Advanced Search** - Faceted search, advanced filters ⭐ **PRIORITY 9** ✅ COMPLETED
- ✅ **Constants System** - Centralized constants (districts, keywords, payments) ⭐ **PRIORITY 10** ✅ COMPLETED
- ✅ **Swiper/Carousel System** - Android-optimized carousels ⭐ **PRIORITY 11** ✅ COMPLETED
- ✅ **Booking System** - Complete booking CRUD operations ⭐ **PRIORITY 12** ✅ COMPLETED
- ✅ **Document Processing** - DocuPipe integration for menu extraction (Admin feature) ⭐ **PRIORITY 13** ✅ COMPLETED

**Code Quality:**
- ✅ **Models Refactoring** - Split models.dart (1408 lines) into 10 domain files ✅ COMPLETED

**Not Applicable for Native Android:**
- ⚠️ **PWA Features** - Not needed (web-specific)
- ⚠️ **Adaptive Responsive Layout** - Not needed (Android-only app)

---

## Missing Features Gap Analysis

### Priority 1: Review System (Essential for Discovery)
**Impact:** HIGH - User engagement and restaurant discovery
**API Reference:** See `API.md` - Review Routes (`/API/Reviews`)

#### 1.1 Review Service
**API Endpoints (from API.md):**
- `GET /API/Reviews?restaurantId=X` - List reviews for restaurant
- `GET /API/Reviews?userId=X` - List reviews by user
- `GET /API/Reviews/:id` - Get single review
- `POST /API/Reviews` - Create review (requires auth)
- `PUT /API/Reviews/:id` - Update review (requires auth, own review only)
- `DELETE /API/Reviews/:id` - Delete review (requires auth, own review only)
- `GET /API/Reviews/Restaurant/:restaurantId/stats` - Get aggregate stats
```dart
// lib/services/review_service.dart
class ReviewService extends ChangeNotifier {
  // CRUD Operations (see API.md for endpoint details)
  Future<List<Review>> getReviews({String? restaurantId, String? userId});
  Future<Review?> getReview(String reviewId);
  Future<String> createReview(CreateReviewRequest request);
  Future<void> updateReview(String reviewId, UpdateReviewRequest request);
  Future<void> deleteReview(String reviewId);
  Future<ReviewStats> getReviewStats(String restaurantId);

  // State management
  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;
}
```

#### 1.2 Review Models
**Data Structure (from API.md):**
**According to API.md, Review documents contain:**
```dart
// lib/models/review.dart
class Review {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoURL;
  final String restaurantId;
  final double rating; // 1-5 stars
  final String? comment;
  final String? imageUrl;
  final DateTime dateTime;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}

class ReviewStats {
  final String restaurantId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int>? ratingDistribution; // {1: 5, 2: 10, 3: 20, 4: 30, 5: 35}
}
```

#### 1.3 Review Widgets
- **ReviewCard** - Display single review with rating stars
- **ReviewForm** - Create/edit review with star selector
- **ReviewStatsWidget** - Display aggregate stats
- **ReviewList** - Scrollable list of reviews

### Priority 2: Menu System (Restaurant Feature)
**Impact:** HIGH - Restaurant information completeness
**API Reference:** See `API.md` - Menu Item Routes (`/API/Restaurants/:restaurantId/menu`)

**IMPORTANT:** Menus are stored as **sub-collections** in Firestore, NOT as array fields.

#### 2.1 Menu Service
**API Endpoints (from API.md):**
- `GET /API/Restaurants/:restaurantId/menu` - List all menu items
- `GET /API/Restaurants/:restaurantId/menu/:menuItemId` - Get single item
- `POST /API/Restaurants/:restaurantId/menu` - Create item
- `PUT /API/Restaurants/:restaurantId/menu/:menuItemId` - Update item
- `DELETE /API/Restaurants/:restaurantId/menu/:menuItemId` - Delete item
```dart
// lib/services/menu_service.dart
class MenuService extends ChangeNotifier {
  Future<List<MenuItem>> getMenuItems(String restaurantId);
  Future<MenuItem?> getMenuItem(String restaurantId, String menuItemId);
  Future<String> createMenuItem(String restaurantId, CreateMenuItemRequest request);
  Future<void> updateMenuItem(String restaurantId, String menuItemId, UpdateMenuItemRequest request);
  Future<void> deleteMenuItem(String restaurantId, String menuItemId);
}
```

#### 2.2 Menu Models
**Data Structure (from API.md):**
```dart
// lib/models/menu_item.dart
class MenuItem {
  final String id;
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? image;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  String getDisplayName(bool isTraditionalChinese);
  String getDisplayDescription(bool isTraditionalChinese);
}
```

#### 2.3 Menu Widgets
- **MenuItemCard** - Display single menu item
- **MenuList** - Grouped menu items by category
- **MenuItemForm** - Create/edit menu item (restaurant owner only)

### Priority 3: Image Upload (Native Android Feature)
**Impact:** HIGH - Native camera/gallery integration
**API Reference:** See `API.md` - Image Upload Routes (`/API/Images`)

**Native Android Features:**
- Camera integration (android.permission.CAMERA)
- Gallery access (READ_EXTERNAL_STORAGE)
- Image compression before upload
- Progress indicators

#### 3.1 Image Upload Service
**API Endpoints (from API.md):**
- `POST /API/Images/upload?folder=X` - Upload image (multipart/form-data)
- `DELETE /API/Images/delete` - Delete image by filePath
- `GET /API/Images/metadata?filePath=X` - Get image metadata

**Folder Organization (from API.md):**
- `Menu/{restaurantId}` - Menu item images
- `Restaurants/{restaurantId}` - Restaurant images
- `Profiles` - User profile pictures
- `Chat` - Chat attachments
- `Banners` - Promotional content
- `General` - Default folder
```dart
// lib/services/image_service.dart
class ImageService extends ChangeNotifier {
  Future<String> uploadImage(File imageFile, String folder);
  Future<void> deleteImage(String filePath);
  Future<ImageMetadata?> getImageMetadata(String filePath);

  // Helper: Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery});
}

class ImageMetadata {
  final String name;
  final int size;
  final String contentType;
  final DateTime timeCreated;
  final DateTime updated;
}
```

**Android-Specific Dependencies:**
- `image_picker: ^1.0.7` - Android camera/gallery access
- `image_cropper: ^5.0.1` - Image cropping (optional)
- `flutter_image_compress: ^2.1.0` - Reduce file size before upload
- `permission_handler: ^11.3.0` - Handle Android permissions
- `http_parser: ^4.0.2` - Parse multipart responses
- `path: ^1.8.3` - File path manipulation

**Android Permissions Required (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### 3.2 Image Upload Widgets
- **ImagePickerButton** - Button with camera/gallery picker
- **ImagePreview** - Display selected image before upload
- **UploadProgressIndicator** - Progress during upload

### Priority 4: Real-time Chat (Socket.IO)
**Impact:** HIGH - Real-time engagement
**API Reference:** See `API.md` - Chat Routes (`/API/Chat`)
**Socket.IO Server:** Railway (https://railway-socket-production.up.railway.app)

**IMPORTANT:** Chat uses Socket.IO server on Railway, separate from REST API.

#### 4.1 Chat Service
**REST API Endpoints (from API.md):**
- `GET /API/Chat/Rooms` - List chat rooms (requires auth)
- `GET /API/Chat/Rooms/:roomId` - Get room details (requires auth)
- `POST /API/Chat/Rooms` - Create chat room (requires auth)
- `GET /API/Chat/Rooms/:roomId/Messages?limit=50` - Get messages (requires auth)
- `POST /API/Chat/Rooms/:roomId/Messages` - Save message (requires auth)
- `PUT /API/Chat/Rooms/:roomId/Messages/:messageId` - Edit message (requires auth)
- `DELETE /API/Chat/Rooms/:roomId/Messages/:messageId` - Delete message (requires auth)
- `GET /API/Chat/Records/:uid` - Get user's chat history (requires auth)
- `GET /API/Chat/Stats/:uid` - Get chat statistics (requires auth)

**Socket.IO Events:**
- `connection` - Connect to server
- `join_room` - Join a chat room
- `send_message` - Send message (real-time)
- `message_received` - Receive message (real-time)
- `typing` - Typing indicator
- `user_online` / `user_offline` - Online status
```dart
// lib/services/chat_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService extends ChangeNotifier {
  IO.Socket? _socket;

  // Connection management
  Future<void> connect(String userId);
  void disconnect();

  // Room operations
  Future<List<ChatRoom>> getChatRooms();
  Future<ChatRoom?> getChatRoom(String roomId);
  Future<String> createChatRoom(List<String> participants, {String? roomName});
  Future<void> joinRoom(String roomId);
  Future<void> leaveRoom(String roomId);

  // Message operations
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50});
  Future<void> sendMessage(String roomId, String message);
  Future<void> editMessage(String roomId, String messageId, String newMessage);
  Future<void> deleteMessage(String roomId, String messageId);

  // Real-time events
  Stream<ChatMessage> get messageStream;
  Stream<TypingIndicator> get typingStream;
  Stream<bool> get connectionStatusStream;
}
```

**Dependencies:**
- `socket_io_client: ^3.1.3` - Socket.IO client for real-time messaging

#### 4.2 Chat Models
**Data Structure (from API.md):**
```dart
// lib/models/chat.dart
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
}

class ChatMessage {
  final String messageId;
  final String roomId;
  final String userId;
  final String displayName;
  final String message;
  final DateTime timestamp;
  final bool edited;
  final bool deleted;
}

class TypingIndicator {
  final String roomId;
  final String userId;
  final String displayName;
  final bool isTyping;
}
```

#### 4.3 Chat Widgets
- **ChatRoomList** - List of chat rooms
- **ChatBubble** - Single message bubble
- **ChatInput** - Message input with send button
- **TypingIndicator** - Shows who's typing
- **ChatRoomPage** - Full chat interface

### Priority 5: AI Assistant (Google Gemini)
**Impact:** MEDIUM - Modern UX enhancement
**API Reference:** See `API.md` - AI Content Generation (Gemini) (`/API/Gemini`)

#### 5.1 Gemini Service
**API Endpoints (from API.md):**
- `POST /API/Gemini/generate` - Generate text content
- `POST /API/Gemini/chat` - Chat with conversation history
- `POST /API/Gemini/restaurant-description` - Generate restaurant descriptions

**Request Format (from API.md):**
```dart
// lib/services/gemini_service.dart
class GeminiService extends ChangeNotifier {
  Future<String> generate(String prompt);
  Future<String> chat(String message, {List<ChatHistory>? history});
  Future<String> generateRestaurantDescription({
    required String name,
    String? cuisine,
    List<String>? specialties,
    String? atmosphere,
  });

  // Helper methods
  Future<String> askAboutRestaurant(String question, String restaurantName);
  Future<String> getDiningRecommendation(Map<String, dynamic> preferences);
}

class ChatHistory {
  final String role; // 'user' or 'model'
  final String content;
}
```

#### 5.2 AI Widgets
- **GeminiChatButton** - Floating action button for AI chat
- **GeminiChatRoomPage** - Full chat interface with AI
- **SuggestionChips** - Quick question chips

### Priority 6: Google Maps Integration (Native Android)
**Impact:** HIGH - Location visualization
**Platform:** Google Maps Android SDK

**IMPORTANT:** This app uses Google Maps, NOT Leaflet or flutter_map.

#### 6.1 Google Maps Setup

**Dependencies:**
```yaml
dependencies:
  google_maps_flutter: ^2.5.3
```

**Android Configuration:**

1. **Add Google Maps API Key to AndroidManifest.xml:**
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
  </application>
</manifest>
```

2. **Enable Google Maps SDK:**
- Go to Google Cloud Console
- Enable "Maps SDK for Android"
- Create API key with Android restrictions

#### 6.2 Google Maps Widgets

**RestaurantMapWidget:**
```dart
// lib/widgets/restaurant_map_widget.dart
class RestaurantMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String restaurantName;

  const RestaurantMapWidget({
    required this.latitude,
    required this.longitude,
    required this.restaurantName,
    super.key,
  });
}
```

**Features:**
- Display restaurant location with marker
- Custom marker with restaurant icon
- Info window with restaurant name
- Tap to open in Google Maps app
- Current location button
- Zoom controls

#### 6.3 Map Page
**AllRestaurantsMapPage:**
- Show all restaurants on map
- Clustered markers for nearby restaurants
- Tap marker to navigate to restaurant detail
- Filter by district/keywords

### Priority 7: Enhanced Restaurant Detail Page
**Impact:** HIGH - Complete restaurant information
**Components:** Hero image, info card, Google Maps, menu, reviews, chat button

**Page Structure:**
1. **Hero Image Section** - Large restaurant photo with carousel
2. **Info Card** - Name, address, district, keywords, rating
3. **Google Maps Section** - Interactive map with marker
4. **Action Buttons** - Directions, Call, Website, Share
5. **Opening Hours Card** - Weekly schedule display
6. **Menu Section** - Categorized menu items with images
7. **Reviews Section** - List with rating distribution
8. **Floating Chat Button** - Start conversation with restaurant

### Priority 8: Restaurant Owner Dashboard
**Impact:** MEDIUM - Business feature
**API Reference:** See `API.md` - Restaurant Routes (`/API/Restaurants/:id/claim`)

#### 8.1 Store Management Service
**API Endpoints (from API.md):**
- `POST /API/Restaurants/:id/claim` - Claim restaurant ownership (requires auth)
- `PUT /API/Restaurants/:id` - Update restaurant details
- `POST /API/Restaurants/:id/image` - Upload restaurant image (multipart, requires auth)
```dart
// lib/services/store_service.dart
class StoreService extends ChangeNotifier {
  // Restaurant claim and management
  Future<void> claimRestaurant(String restaurantId);
  Future<Restaurant?> getOwnedRestaurant();
  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> updates);

  // Menu management (delegates to MenuService)
  Future<List<MenuItem>> getMenuItems();
  Future<void> addMenuItem(MenuItem item);
  Future<void> updateMenuItem(String itemId, MenuItem item);
  Future<void> deleteMenuItem(String itemId);

  // Bookings for owned restaurant
  Future<List<Booking>> getRestaurantBookings();
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
}
```

#### 8.2 Store Pages
- **StoreDashboardPage** - Overview with stats
- **StoreMenuPage** - Manage menu items
- **StoreBookingsPage** - View/manage bookings
- **StoreSettingsPage** - Restaurant settings

### Priority 9: Advanced Search Features
**Impact:** MEDIUM - Search UX improvement
**API Reference:** See `API.md` - Search Routes (Algolia) (`/API/Algolia`)

#### 9.1 Enhanced Restaurant Service
**API Endpoints (from API.md):**
- `GET /API/Algolia/Restaurants?query=X&districts=Y&keywords=Z` - Basic search
- `GET /API/Algolia/Restaurants/facets/:facetName` - Get facet values (District_EN, Keyword_EN, etc.)
- `POST /API/Algolia/Restaurants/advanced` - Advanced search with custom filters

**Query Parameters (from API.md):**
- `query` - Full-text search (searches both EN and TC)
- `districts` - Comma-separated districts
- `keywords` - Comma-separated keywords
- `page` - Page number (default: 0)
- `hitsPerPage` - Results per page (default: 20, max: 100)
```dart
// lib/services/restaurant_service.dart (enhanced)
class RestaurantService extends ChangeNotifier {
  // Existing methods...

  // Advanced search
  Future<SearchResponse> advancedSearch({
    String? query,
    List<String>? districts,
    List<String>? keywords,
    int page = 0,
    int hitsPerPage = 20,
    String? aroundLatLng,
    int? aroundRadius,
  });

  // Faceted search
  Future<List<FacetValue>> getFacetValues(String facetName, {String? query});

  // Geo search
  Future<List<Restaurant>> searchNearby(double lat, double lng, int radiusMeters);
}

class SearchResponse {
  final List<Restaurant> hits;
  final int nbHits;
  final int page;
  final int nbPages;
  final int hitsPerPage;
}

class FacetValue {
  final String value;
  final int count;
}
```

#### 9.2 Search Enhancements
- **FilterSheet** - Bottom sheet with all filters
- **DistrictMultiSelect** - Multi-select district chips
- **KeywordMultiSelect** - Multi-select keyword chips
- **SortOptions** - Sort by distance, rating, name
- **SearchHistory** - Recent searches

### Priority 10: Constants System
**Impact:** LOW - Code organization

#### 10.1 Create Constants Files
```dart
// lib/constants/districts.dart
class HKDistricts {
  static const List<DistrictOption> all = [/* 18 districts */];
  static DistrictOption? findByEn(String en);
  static DistrictOption? findByTc(String tc);
}

// lib/constants/keywords.dart
class RestaurantKeywords {
  static const List<KeywordOption> all = [/* 140+ keywords */];
  static KeywordOption? findByEn(String en);
  static KeywordOption? findByTc(String tc);
}

// lib/constants/payments.dart
class PaymentMethods {
  static const List<PaymentOption> all = [/* 10 payment methods */];
}

// lib/constants/weekdays.dart
class Weekdays {
  static const List<String> enShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> enFull = ['Monday', 'Tuesday', ...];
  static const List<String> tc = ['星期一', '星期二', ...];
}
```

### Priority 11: Swiper/Carousel System (Android Touch Gestures)
**Impact:** MEDIUM - Visual appeal and native Android UX

#### 11.1 Carousel Implementation (Android-optimized)
**Android-Optimized Dependencies:**
- `carousel_slider: ^4.2.1` - Feature-rich carousel with touch gestures
- `smooth_page_indicator: ^1.1.0` - Material Design page indicators
- Native Android swipe gestures and physics

#### 11.2 Carousel Widgets (Android Material Design)
- **HeroCarousel** - Full-width hero images
- **OfferCarousel** - Featured offers
- **RestaurantCarousel** - Restaurant cards
- **MenuCarousel** - Menu item images

### Priority 12: Booking System (Lowest Priority)
**Impact:** LOW - Deferred feature
**API Reference:** See `API.md` - Booking Routes (`/API/Bookings`)

**NOTE:** This feature has been deprioritized. Implement only after all other features are complete.

#### 12.1 Booking Service (When Implementing)
**API Endpoints (from API.md):**
- `GET /API/Bookings?userId=X` - List user's bookings (requires auth, auto-filtered)
- `GET /API/Bookings/:id` - Get single booking (requires auth)
- `POST /API/Bookings` - Create booking (requires auth)
- `PUT /API/Bookings/:id` - Update booking (requires auth)
- `DELETE /API/Bookings/:id` - Delete/cancel booking (requires auth)

**Data Structure (from API.md):**
- `userId` - Automatically set from auth token (cannot be spoofed)
- `restaurantId` - Required
- `restaurantName` - Required (denormalized)
- `dateTime` - ISO 8601 string, required
- `numberOfGuests` - Required
- `status` - pending/confirmed/completed/cancelled
- `paymentStatus` - unpaid/paid/refunded
- `specialRequests` - Optional string

### Priority 13: DocuPipe Integration (Optional, Admin Only)
**Impact:** VERY LOW - Admin feature for menu extraction
**API Reference:** See `API.md` - Document Processing (DocuPipe) (`/API/DocuPipe`)

**API Endpoints (from API.md):**
- `POST /API/DocuPipe/upload` - Upload document for processing
- `GET /API/DocuPipe/job/:jobId` - Check processing status
- `GET /API/DocuPipe/document/:documentId` - Get processed document
- `POST /API/DocuPipe/extract-menu` - Extract menu items from PDF/image
- `GET /API/DocuPipe/standardization/:standardizationId` - Get standardized results

#### 13.1 DocuPipe Service (If Implementing)
```dart
// lib/services/docupipe_service.dart
class DocuPipeService {
  Future<String> uploadDocument(File file, {String dataset = 'unassigned'});
  Future<JobStatus> checkJobStatus(String jobId);
  Future<DocumentResult> getDocument(String documentId);
  Future<List<MenuItem>> extractMenu(File menuFile);
}
```

---

## Implementation Roadmap (Native Android Priority)

### Phase 1: Review & Menu Systems (Week 1-2)
**Goal:** Core discovery features with native Android implementation

#### Week 1: Review System
- [ ] Set up review models (from API.md structure)
- [ ] Implement ReviewService with API integration
- [ ] Create review widgets (ReviewCard, ReviewForm, StarRating)
- [ ] Add review stats widget with Material Design
- [ ] Create ReviewListPage with pull-to-refresh
- [ ] Test review CRUD operations
- [ ] Verify bilingual support (EN/TC)

#### Week 2: Menu System
- [ ] Set up menu models (sub-collection from API.md)
- [ ] Implement MenuService with API integration
- [ ] Create menu widgets (MenuItemCard, MenuList, CategoryHeader)
- [ ] Add menu to restaurant detail page
- [ ] Create menu management page (for restaurant owners)
- [ ] Test menu CRUD operations
- [ ] Add image display with cached_network_image

### Phase 2: Native Android Features (Week 3-4)
**Goal:** Camera, gallery, and Google Maps integration

#### Week 3: Image Upload with Android Camera/Gallery
- [ ] Configure Android permissions (camera, storage)
- [ ] Implement ImageService with multipart upload
- [ ] Add permission_handler integration
- [ ] Create camera/gallery picker with Android native UI
- [ ] Add image compression before upload
- [ ] Create image upload widgets with progress
- [ ] Test upload to Firebase Storage via API
- [ ] Add image deletion functionality

#### Week 4: Google Maps Integration
- [ ] Set up Google Maps SDK for Android
- [ ] Configure API key in AndroidManifest.xml
- [ ] Implement RestaurantMapWidget with markers
- [ ] Add custom marker icons for restaurants
- [ ] Create AllRestaurantsMapPage with clustering
- [ ] Add "Open in Google Maps" functionality
- [ ] Integrate map into restaurant detail page
- [ ] Test location accuracy and marker interactions

### Phase 3: Real-time & AI (Week 5-6)
**Goal:** Socket.IO chat and Gemini AI integration

#### Week 5: Real-time Chat (Socket.IO on Railway)
- [ ] Implement Socket.IO client connection to Railway server
- [ ] Create ChatService with room management (API.md endpoints)
- [ ] Build chat models (ChatRoom, ChatMessage, TypingIndicator)
- [ ] Create ChatRoomPage with Material Design
- [ ] Implement ChatBubble with user/other styling
- [ ] Add ChatInput with send button and typing indicator
- [ ] Add real-time message streaming
- [ ] Test chat functionality with multiple users
- [ ] Add message persistence via REST API

#### Week 6: AI Assistant (Google Gemini)
- [ ] Implement GeminiService (API.md endpoints)
- [ ] Create AI chat interface with conversation history
- [ ] Add floating AI assistant button (FloatingActionButton)
- [ ] Implement restaurant-specific queries
- [ ] Add dining recommendations based on preferences
- [ ] Create suggestion chips for quick questions
- [ ] Test AI responses and error handling
- [ ] Add markdown rendering for AI responses

### Phase 4: Enhanced Features (Week 7-8)
**Goal:** Complete restaurant detail page and owner features

#### Week 7: Enhanced Restaurant Detail Page
- [ ] Create comprehensive RestaurantDetailPage layout
- [ ] Add hero image carousel with PageView
- [ ] Integrate Google Maps section
- [ ] Add contact action buttons (call, website, directions)
- [ ] Display opening hours in weekly schedule
- [ ] Integrate menu section
- [ ] Integrate reviews section with stats
- [ ] Add floating chat button
- [ ] Add share functionality (Android share intent)
- [ ] Test all sections and interactions

#### Week 8: Restaurant Owner Dashboard
- [ ] Implement StoreService with claim endpoint (API.md)
- [ ] Create StoreDashboardPage with stats
- [ ] Add StoreMenuPage for menu management
- [ ] Implement restaurant info editing
- [ ] Add restaurant image upload
- [ ] Create owner verification flow
- [ ] Test owner-only features
- [ ] Add role-based access control

### Phase 5: Advanced Search & Polish (Week 9-10)
**Goal:** Advanced filtering and UI polish

#### Week 9: Advanced Search & Filters
- [ ] Enhance search with faceted filters (API.md endpoints)
- [ ] Create FilterSheet bottom sheet (Material Design)
- [ ] Implement multi-select district chips
- [ ] Implement multi-select keyword chips
- [ ] Add sort options (distance, rating, name)
- [ ] Create search history with SharedPreferences
- [ ] Add "Clear filters" functionality
- [ ] Test advanced search combinations

#### Week 10: UI Polish & Optimization
- [ ] Add carousel/swiper widgets with Android gestures
- [ ] Implement constants system (districts, keywords, payments)
- [ ] Add loading states with Material CircularProgressIndicator
- [ ] Implement pull-to-refresh on all lists
- [ ] Optimize image loading with caching
- [ ] Add error retry mechanisms
- [ ] Perform UI/UX testing
- [ ] Fix bugs and polish animations
- [ ] Test on multiple Android devices
- [ ] Performance profiling and optimization

### Phase 6: Booking System (Optional, Week 11+)
**Goal:** Add booking feature if time permits

**NOTE:** Only implement if all higher priority features are complete.

#### Week 11: Booking System (Deferred)
- [ ] Set up booking models (from API.md)
- [ ] Implement BookingService with API integration
- [ ] Create BookingsPage (past/future tabs)
- [ ] Create CreateBookingPage with date/time picker
- [ ] Add booking detail page
- [ ] Test booking CRUD operations
- [ ] Add booking notifications (Android notifications)

---

## Detailed Implementation Guide

**AI Agent Note:** Always reference `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md` for exact API specifications before implementing.

### 1. Review System Implementation (PRIORITY 1)

#### Step 1.1: Read API Documentation
**Before coding, review:**
- `API.md` - Review Routes section
- Request/response formats
- Authentication requirements
- Error response formats

#### Step 1.2: Create Review Models
**Based on API.md Review data structure:**
```dart
// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  int get starCount => rating.round();
}

class ReviewStats {
  final String restaurantId;
  final int totalReviews;
  final double averageRating;
  final Map<int, int>? ratingDistribution;

  ReviewStats({
    required this.restaurantId,
    required this.totalReviews,
    required this.averageRating,
    this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    Map<int, int>? distribution;
    if (json['ratingDistribution'] != null) {
      final distMap = json['ratingDistribution'] as Map<String, dynamic>;
      distribution = distMap.map((k, v) => MapEntry(int.parse(k), v as int));
    }

    return ReviewStats(
      restaurantId: json['restaurantId'] as String,
      totalReviews: json['totalReviews'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingDistribution: distribution,
    );
  }
}

class CreateReviewRequest {
  final String restaurantId;
  final double rating;
  final String? comment;

  CreateReviewRequest({
    required this.restaurantId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}

class UpdateReviewRequest {
  final double? rating;
  final String? comment;

  UpdateReviewRequest({this.rating, this.comment});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (rating != null) data['rating'] = rating;
    if (comment != null) data['comment'] = comment;
    return data;
  }
}
```

#### Step 1.3: Implement Review Service
**API Integration following API.md:**

```dart
// lib/services/review_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/review.dart';
import 'auth_service.dart';

/// Review Service
///
/// Manages restaurant reviews via API endpoints documented in API.md.
/// All endpoints require x-api-passcode header.
/// Create/Update/Delete operations require Firebase authentication token.
class ReviewService extends ChangeNotifier {
  final AuthService _authService;

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewService(this._authService);

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch reviews
  ///
  /// API Endpoint (from API.md):
  /// GET /API/Reviews?restaurantId=X  - Filter by restaurant
  /// GET /API/Reviews?userId=X        - Filter by user
  /// GET /API/Reviews                 - Get all reviews
  ///
  /// Authentication: Not required for GET
  Future<void> fetchReviews({String? restaurantId, String? userId}) async {
    _setLoading(true);
    _error = null;

    try {
      final queryParams = <String, String>{};
      if (restaurantId != null) queryParams['restaurantId'] = restaurantId;
      if (userId != null) queryParams['userId'] = userId;

      final uri = Uri.parse(AppConfig.getEndpoint('/API/Reviews'))
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> reviewsList = data['data'] ?? [];
        _reviews = reviewsList
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get single review
  ///
  /// API Endpoint (from API.md):
  /// GET /API/Reviews/:id
  ///
  /// Authentication: Not required
  Future<Review?> getReview(String reviewId) async {
    try {
      final url = AppConfig.getEndpoint('/API/Reviews/$reviewId');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        return Review.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting review: $e');
      return null;
    }
  }

  /// Create review
  ///
  /// API Endpoint (from API.md):
  /// POST /API/Reviews
  /// Body: { restaurantId, rating, comment? }
  ///
  /// Authentication: Required (Bearer token)
  /// Note: userId is automatically set from auth token by backend
  Future<String?> createReview(CreateReviewRequest request) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Reviews');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reviewId = data['id'] as String;

        // Refresh reviews list
        await fetchReviews(restaurantId: request.restaurantId);

        return reviewId;
      } else {
        throw Exception('Failed to create review: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error creating review: $e');
      return null;
    }
  }

  /// Update review
  ///
  /// API Endpoint (from API.md):
  /// PUT /API/Reviews/:id
  /// Body: { rating?, comment? }
  ///
  /// Authentication: Required (Bearer token)
  /// Authorization: User can only update own reviews
  Future<bool> updateReview(String reviewId, UpdateReviewRequest request) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Reviews/$reviewId');
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Refresh reviews list
        if (_reviews.isNotEmpty) {
          final restaurantId = _reviews.first.restaurantId;
          await fetchReviews(restaurantId: restaurantId);
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error updating review: $e');
      return false;
    }
  }

  /// Delete review
  ///
  /// API Endpoint (from API.md):
  /// DELETE /API/Reviews/:id
  ///
  /// Authentication: Required (Bearer token)
  /// Authorization: User can only delete own reviews
  Future<bool> deleteReview(String reviewId) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Reviews/$reviewId');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Remove from local list
        _reviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error deleting review: $e');
      return false;
    }
  }

  /// Get review statistics
  ///
  /// API Endpoint (from API.md):
  /// GET /API/Reviews/Restaurant/:restaurantId/stats
  ///
  /// Returns: { restaurantId, totalReviews, averageRating, ratingDistribution? }
  /// Authentication: Not required
  Future<ReviewStats?> getReviewStats(String restaurantId) async {
    try {
      final url = AppConfig.getEndpoint('/API/Reviews/Restaurant/$restaurantId/stats');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
        },
      );

      if (response.statusCode == 200) {
        return ReviewStats.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting review stats: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

### 2. Menu System Implementation (PRIORITY 2)

**AI Agent Note:** Menus are sub-collections in Firestore, NOT array fields. See API.md Menu Sub-collection section.

#### Step 2.1: Create Menu Models
**Based on API.md Menu Item data structure:**

```dart
// lib/models/menu_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? image;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  MenuItem({
    required this.id,
    this.nameEn,
    this.nameTc,
    this.descriptionEn,
    this.descriptionTc,
    this.price,
    this.image,
    this.createdAt,
    this.modifiedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return MenuItem(
      id: json['id'] as String,
      nameEn: json['Name_EN'] as String?,
      nameTc: json['Name_TC'] as String?,
      descriptionEn: json['Description_EN'] as String?,
      descriptionTc: json['Description_TC'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      image: json['image'] as String?,
      createdAt: parseDateTime(json['createdAt']),
      modifiedAt: parseDateTime(json['modifiedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nameEn != null) 'Name_EN': nameEn,
      if (nameTc != null) 'Name_TC': nameTc,
      if (descriptionEn != null) 'Description_EN': descriptionEn,
      if (descriptionTc != null) 'Description_TC': descriptionTc,
      if (price != null) 'price': price,
      if (image != null) 'image': image,
    };
  }

  String getDisplayName(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (nameTc ?? nameEn ?? 'Unknown')
        : (nameEn ?? nameTc ?? 'Unknown');
  }

  String getDisplayDescription(bool isTraditionalChinese) {
    return isTraditionalChinese
        ? (descriptionTc ?? descriptionEn ?? '')
        : (descriptionEn ?? descriptionTc ?? '');
  }
}

class CreateMenuItemRequest {
  final String? nameEn;
  final String? nameTc;
  final String? descriptionEn;
  final String? descriptionTc;
  final double? price;
  final String? image;

  CreateMenuItemRequest({
    this.nameEn,
    this.nameTc,
    this.descriptionEn,
    this.descriptionTc,
    this.price,
    this.image,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (nameEn != null) data['Name_EN'] = nameEn;
    if (nameTc != null) data['Name_TC'] = nameTc;
    if (descriptionEn != null) data['Description_EN'] = descriptionEn;
    if (descriptionTc != null) data['Description_TC'] = descriptionTc;
    if (price != null) data['price'] = price;
    if (image != null) data['image'] = image;
    return data;
  }
}
```

### 3. Google Maps Integration (PRIORITY 6)

**AI Agent Note:** This app uses Google Maps SDK for Android, NOT Leaflet or flutter_map.

#### Step 3.1: Android Configuration

**1. Add dependency to pubspec.yaml:**
```yaml
dependencies:
  google_maps_flutter: ^2.5.3
```

**2. Add Google Maps API Key to AndroidManifest.xml:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application>
    <!-- Add inside <application> tag -->
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
  </application>
</manifest>
```

**3. Enable Maps SDK in Google Cloud Console:**
- Go to https://console.cloud.google.com/
- Enable "Maps SDK for Android"
- Create API key with Android app restrictions

#### Step 3.2: Create Restaurant Map Widget

```dart
// lib/widgets/restaurant_map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String restaurantName;
  final double height;

  const RestaurantMapWidget({
    required this.latitude,
    required this.longitude,
    required this.restaurantName,
    this.height = 250,
    super.key,
  });

  @override
  State<RestaurantMapWidget> createState() => _RestaurantMapWidgetState();
}

class _RestaurantMapWidgetState extends State<RestaurantMapWidget> {
  late GoogleMapController _mapController;
  late Marker _restaurantMarker;

  @override
  void initState() {
    super.initState();
    _restaurantMarker = Marker(
      markerId: const MarkerId('restaurant'),
      position: LatLng(widget.latitude, widget.longitude),
      infoWindow: InfoWindow(
        title: widget.restaurantName,
        snippet: 'Tap to open in Google Maps',
        onTap: _openInGoogleMaps,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: 15,
        ),
        markers: {_restaurantMarker},
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
```

**Required dependency for url_launcher:**
```yaml
dependencies:
  url_launcher: ^6.2.5
```

**Android permissions for location (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 4. Booking System Implementation (LOWEST PRIORITY)

**AI Agent Note:** Implement this LAST, only after all other features are complete.

#### Step 4.1: Create Booking Models (When Implementing)
**Based on API.md Booking data structure:**

```dart
// lib/models/booking.dart (DEFERRED)
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String toJson() => name;

  static BookingStatus fromJson(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }

  String getDisplayName(bool isTraditionalChinese) {
    switch (this) {
      case BookingStatus.pending:
        return isTraditionalChinese ? '待確認' : 'Pending';
      case BookingStatus.confirmed:
        return isTraditionalChinese ? '已確認' : 'Confirmed';
      case BookingStatus.completed:
        return isTraditionalChinese ? '已完成' : 'Completed';
      case BookingStatus.cancelled:
        return isTraditionalChinese ? '已取消' : 'Cancelled';
    }
  }
}

enum PaymentStatus {
  unpaid,
  paid,
  refunded;

  String toJson() => name;

  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  String getDisplayName(bool isTraditionalChinese) {
    switch (this) {
      case PaymentStatus.unpaid:
        return isTraditionalChinese ? '未付款' : 'Unpaid';
      case PaymentStatus.paid:
        return isTraditionalChinese ? '已付款' : 'Paid';
      case PaymentStatus.refunded:
        return isTraditionalChinese ? '已退款' : 'Refunded';
    }
  }
}

class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? specialRequests;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Restaurant? restaurant; // Populated from joined data

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
    this.restaurant,
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
      status: BookingStatus.fromJson(json['status'] as String? ?? 'pending'),
      paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String? ?? 'unpaid'),
      specialRequests: json['specialRequests'] as String?,
      createdAt: json['createdAt'] != null ? parseDateTime(json['createdAt']) : null,
      modifiedAt: json['modifiedAt'] != null ? parseDateTime(json['modifiedAt']) : null,
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
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
      'status': status.toJson(),
      'paymentStatus': paymentStatus.toJson(),
      if (specialRequests != null) 'specialRequests': specialRequests,
    };
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isActive => status != BookingStatus.cancelled && status != BookingStatus.completed;
}

class CreateBookingRequest {
  final String restaurantId;
  final String restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  final String? specialRequests;

  CreateBookingRequest({
    required this.restaurantId,
    required this.restaurantName,
    required this.dateTime,
    required this.numberOfGuests,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'dateTime': dateTime.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      if (specialRequests != null && specialRequests!.isNotEmpty)
        'specialRequests': specialRequests,
    };
  }
}

class UpdateBookingRequest {
  final DateTime? dateTime;
  final int? numberOfGuests;
  final BookingStatus? status;
  final PaymentStatus? paymentStatus;
  final String? specialRequests;

  UpdateBookingRequest({
    this.dateTime,
    this.numberOfGuests,
    this.status,
    this.paymentStatus,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (dateTime != null) data['dateTime'] = dateTime!.toIso8601String();
    if (numberOfGuests != null) data['numberOfGuests'] = numberOfGuests;
    if (status != null) data['status'] = status!.toJson();
    if (paymentStatus != null) data['paymentStatus'] = paymentStatus!.toJson();
    if (specialRequests != null) data['specialRequests'] = specialRequests;
    return data;
  }
}
```

**NOTE:** Booking implementation details removed to save space. Refer to API.md Booking Routes when ready to implement.

---

## Android-Specific Considerations

### Native Android Features to Leverage

1. **Permissions Management**
```dart
// Use permission_handler package
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}
```

2. **Native Intents**
```dart
// Open phone dialer
await launchUrl(Uri.parse('tel:+85212345678'));

// Open Google Maps
await launchUrl(Uri.parse('geo:0,0?q=22.3193,114.1694(Restaurant)'));

// Share content
await Share.share('Check out this restaurant!');
```

3. **Material Design 3**
- Use Material 3 components
- Follow Android design guidelines
- Implement proper elevation and shadows
- Use platform-specific navigation patterns

4. **Android Notifications**
```dart
// Use flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Configure notification channels
// Show booking confirmations
// Alert for chat messages
```

5. **Android Performance**
- Use `const` constructors where possible
- Implement image caching with `cached_network_image`
- Lazy load lists with `ListView.builder`
- Use `AutomaticKeepAliveClientMixin` for tab persistence

---

## API Integration Checklist

### Before Making API Calls

**AI Agent: Always verify these before implementing:**

1. ✅ Check `API.md` for exact endpoint path
2. ✅ Verify HTTP method (GET/POST/PUT/DELETE)
3. ✅ Check if authentication required
4. ✅ Include `x-api-passcode: PourRice` header
5. ✅ Include `Authorization: Bearer <token>` if authenticated
6. ✅ Use `Content-Type: application/json` for POST/PUT
7. ✅ Format DateTime as ISO 8601 strings
8. ✅ Handle error responses (400, 401, 403, 404, 500)
9. ✅ Parse response according to API.md format
10. ✅ Update UI with loading/error states

### API Error Handling Pattern

```dart
try {
  final response = await http.get(uri, headers: headers);

  if (response.statusCode == 200) {
    // Success - parse response
    return parseData(response.body);
  } else if (response.statusCode == 401) {
    throw Exception('Unauthorized - please login');
  } else if (response.statusCode == 403) {
    throw Exception('Forbidden - insufficient permissions');
  } else if (response.statusCode == 404) {
    throw Exception('Not found');
  } else {
    // Parse error message from API
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Unknown error');
  }
} catch (e) {
  _error = e.toString();
  if (kDebugMode) print('API Error: $e');
  notifyListeners();
  rethrow;
}
```

---

## Testing Checklist

### For Each Feature Implementation

**AI Agent: Test these after implementing each feature:**

1. **API Integration**
   - [ ] Endpoint called correctly
   - [ ] Headers included properly
   - [ ] Request body formatted correctly
   - [ ] Response parsed correctly
   - [ ] Errors handled gracefully

2. **Bilingual Support**
   - [ ] EN text displays correctly
   - [ ] TC text displays correctly
   - [ ] Language toggle works
   - [ ] Fallback to other language if missing

3. **Authentication**
   - [ ] Works when logged in
   - [ ] Fails gracefully when not logged in
   - [ ] Token refreshes if needed
   - [ ] Redirects to login if needed

4. **State Management**
   - [ ] Loading state shows
   - [ ] Error state shows
   - [ ] Success state updates UI
   - [ ] Pull-to-refresh works

5. **Android-Specific**
   - [ ] Permissions requested correctly
   - [ ] Works on Android emulator
   - [ ] Works on physical device
   - [ ] No iOS-specific code used

---

## Required Dependencies (Android-Optimized)

```yaml
dependencies:
  # Existing dependencies
  flutter:
    sdk: flutter
  provider: ^6.1.1
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  google_sign_in: ^6.2.1
  shared_preferences: ^2.2.2
  http: ^1.2.0

  # NEW: Review & Menu System
  intl: ^0.19.0                         # Date formatting
  timeago: ^3.6.0                       # Relative time ("2 hours ago")
  flutter_rating_bar: ^4.0.1           # Star rating widget

  # NEW: Image Upload (Android Native)
  image_picker: ^1.0.7                  # Android camera/gallery
  image_cropper: ^5.0.1                 # Image cropping
  flutter_image_compress: ^2.1.0        # Compress before upload
  permission_handler: ^11.3.0           # Android permissions
  cached_network_image: ^3.3.1          # Image caching
  path: ^1.8.3                          # File paths

  # NEW: Google Maps (Android)
  google_maps_flutter: ^2.5.3           # Google Maps SDK
  url_launcher: ^6.2.5                  # Open external apps
  geolocator: ^11.0.0                   # GPS location

  # NEW: Real-time Chat (Socket.IO)
  socket_io_client: ^3.1.3          	# Socket.IO client

  # NEW: UI Components
  carousel_slider: ^4.2.1               # Carousels/swipers
  smooth_page_indicator: ^1.1.0         # Page indicators
  flutter_markdown: ^0.6.19             # Markdown rendering (AI responses)

  # NEW: Notifications (Android)
  flutter_local_notifications: ^16.3.2  # Local notifications

  # NEW: Share (Android)
  share_plus: ^7.2.2                    # Android share intent
```

**Android Permissions to Add (AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## Implementation Priority Summary

**AI Agent: Follow this order strictly:**

1. **PRIORITY 1:** Review System (Week 1)
2. **PRIORITY 2:** Menu System (Week 2)
3. **PRIORITY 3:** Image Upload with Android Camera (Week 3)
4. **PRIORITY 4:** Real-time Chat with Socket.IO (Week 5)
5. **PRIORITY 5:** AI Assistant with Gemini (Week 6)
6. **PRIORITY 6:** Google Maps Integration (Week 4)
7. **PRIORITY 7:** Enhanced Restaurant Detail Page (Week 7)
8. **PRIORITY 8:** Restaurant Owner Dashboard (Week 8)
9. **PRIORITY 9:** Advanced Search & Filters (Week 9)
10. **PRIORITY 10:** Constants System (Week 9)
11. **PRIORITY 11:** Carousels/Swipers (Week 10)
12. **PRIORITY 12:** Booking System (Week 11+ - LOWEST PRIORITY)

---

## Conclusion

This implementation plan is optimized for:
- ✅ Native Android development
- ✅ Google Maps integration (not Leaflet)
- ✅ AI agent readability
- ✅ API.md as primary reference
- ✅ Booking system as lowest priority
- ✅ Android-specific features (camera, permissions, Material Design)

**Estimated Implementation Time:** 10-11 weeks (full-time development)

**Key Success Factors:**
1. Always reference `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md` before coding
2. Test on Android emulator/device frequently
3. Implement features in priority order
4. Focus on native Android UX patterns
5. Verify bilingual support for every feature

---

**Document Version:** 2.0 (Android Native Edition)
**Created:** 2025-12-24
**Updated:** 2025-12-24
**Author:** Claude AI Assistant
**Project:** PourRice Flutter Native Android Application
**API Reference:** `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md`

---

## Quick Start for AI Agents

**To implement a feature:**

1. Open `C:\Users\Test-Plus\Projects\Vercel-Express-API\API.md`
2. Find the relevant API endpoint section
3. Read the request/response format
4. Implement models based on API.md data structure
5. Implement service with proper headers
6. Create UI with Material Design 3
7. Test on Android device/emulator
8. Verify bilingual support (EN/TC)

**API Request Template:**
```dart
final response = await http.method(
  Uri.parse(AppConfig.getEndpoint('/API/Endpoint')),
  headers: {
    'x-api-passcode': AppConfig.apiPasscode,
    if (requiresAuth) 'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(data),
);
```

**Error Handling Template:**
```dart
if (response.statusCode == 200 || response.statusCode == 201) {
  return parseResponse(response.body);
} else {
  final error = jsonDecode(response.body);
  throw Exception(error['error'] ?? 'Request failed');
}
```

This document provides everything needed for systematic implementation. Follow the priority order and always reference API.md for accurate API integration.

---

**End of Implementation Plan**
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/booking.dart';
import 'auth_service.dart';

class BookingService extends ChangeNotifier {
  final AuthService _authService;

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  BookingService(this._authService);

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Booking> get upcomingBookings =>
    _bookings.where((b) => b.isUpcoming && b.isActive).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Booking> get pastBookings =>
    _bookings.where((b) => b.isPast || !b.isActive).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  /// Fetch all bookings for the current user
  Future<void> fetchBookings() async {
    _setLoading(true);
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = AppConfig.getEndpoint('/API/Bookings');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> bookingsList = data['data'] ?? [];
        _bookings = bookingsList
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error fetching bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get a single booking by ID
  Future<Booking?> getBooking(String bookingId) async {
    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Bookings/$bookingId');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Booking.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting booking: $e');
      return null;
    }
  }

  /// Create a new booking
  Future<String?> createBooking(CreateBookingRequest request) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Bookings');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final bookingId = data['id'] as String;

        // Refresh bookings list
        await fetchBookings();

        return bookingId;
      } else {
        throw Exception('Failed to create booking: ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error creating booking: $e');
      return null;
    }
  }

  /// Update an existing booking
  Future<bool> updateBooking(String bookingId, UpdateBookingRequest request) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Bookings/$bookingId');
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Refresh bookings list
        await fetchBookings();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error updating booking: $e');
      return false;
    }
  }

  /// Delete (cancel) a booking
  Future<bool> deleteBooking(String bookingId) async {
    _error = null;

    try {
      final token = await _authService.getIdToken();
      if (token == null) throw Exception('User not authenticated');

      final url = AppConfig.getEndpoint('/API/Bookings/$bookingId');
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'x-api-passcode': AppConfig.apiPasscode,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Remove from local list
        _bookings.removeWhere((b) => b.id == bookingId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error deleting booking: $e');
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

#### Step 1.3: Update Provider Setup
```dart
// lib/main.dart (update MultiProvider)
MultiProvider(
  providers: [
    // ... existing providers

    // BookingService - needs AuthService for tokens
    ChangeNotifierProxyProvider<AuthService, BookingService>(
      create: (context) => BookingService(
        context.read<AuthService>(),
      ),
      update: (context, authService, previous) =>
          previous ?? BookingService(authService),
    ),
  ],
  child: const AppRoot(),
)
```

#### Step 1.4: Create Bookings Page
```dart
// lib/pages/bookings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import 'create_booking_page.dart';
import 'booking_detail_page.dart';

class BookingsPage extends StatefulWidget {
  final bool isTraditionalChinese;

  const BookingsPage({
    required this.isTraditionalChinese,
    super.key,
  });

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch bookings when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingService>().fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = widget.isTraditionalChinese;

    return Scaffold(
      appBar: AppBar(
        title: Text(tc ? '我的預訂' : 'My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tc ? '即將到來' : 'Upcoming'),
            Tab(text: tc ? '過去' : 'Past'),
          ],
        ),
      ),
      body: Consumer<BookingService>(
        builder: (context, bookingService, _) {
          if (bookingService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    tc ? '載入失敗' : 'Failed to load',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(bookingService.error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => bookingService.fetchBookings(),
                    icon: const Icon(Icons.refresh),
                    label: Text(tc ? '重試' : 'Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(
                bookingService.upcomingBookings,
                tc ? '沒有即將到來的預訂' : 'No upcoming bookings',
                tc,
              ),
              _buildBookingList(
                bookingService.pastBookings,
                tc ? '沒有過去的預訂' : 'No past bookings',
                tc,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBookingPage(
                isTraditionalChinese: tc,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(tc ? '新預訂' : 'New Booking'),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyMessage, bool tc) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BookingService>().fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(booking: booking, isTraditionalChinese: tc);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isTraditionalChinese;

  const _BookingCard({
    required this.booking,
    required this.isTraditionalChinese,
  });

  @override
  Widget build(BuildContext context) {
    final tc = isTraditionalChinese;
    final dateStr = _formatDate(booking.dateTime, tc);
    final timeStr = _formatTime(booking.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailPage(
                bookingId: booking.id,
                isTraditionalChinese: tc,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.restaurantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(
                    status: booking.status,
                    isTraditionalChinese: tc,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(dateStr, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(timeStr, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.numberOfGuests} ${tc ? "位" : "guests"}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.specialRequests!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool tc) {
    if (tc) {
      return '${date.year}年${date.month}月${date.day}日';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool isTraditionalChinese;

  const _StatusChip({
    required this.status,
    required this.isTraditionalChinese,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BookingStatus.confirmed:
        color = Colors.green;
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.getDisplayName(isTraditionalChinese),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

### 2. Review System Implementation

*(Similar detailed implementation for Review system would follow the same pattern: Models → Service → Pages → Widgets)*

---

## Architecture & Design Patterns

### State Management Strategy
**Use Provider with ChangeNotifier pattern (existing pattern in your app)**

**Service Layer Pattern:**
```dart
class XxxService extends ChangeNotifier {
  // Private state
  List<T> _items = [];
  bool _isLoading = false;
  String? _error;

  // Public getters
  List<T> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public methods that modify state and call notifyListeners()
  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      // API call
      _items = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### API Integration Pattern
**Consistent HTTP Client Usage:**

```dart
Future<T> apiCall<T>() async {
  final token = await _authService.getIdToken();

  final response = await http.method(
    Uri.parse(AppConfig.getEndpoint('/API/Endpoint')),
    headers: {
      'x-api-passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    return parseResponse<T>(response.body);
  } else {
    throw Exception('API call failed: ${response.body}');
  }
}
```

### Error Handling Pattern
**Three-layer error handling:**

1. **Service Layer:** Catch and store error in state
2. **UI Layer:** Display error to user
3. **Logging:** Debug prints in development

```dart
// Service
try {
  // Operation
} catch (e) {
  _error = e.toString();
  if (kDebugMode) print('Error in XxxService: $e');
  notifyListeners();
}

// UI
if (service.error != null) {
  return ErrorWidget(
    message: service.error!,
    onRetry: () => service.fetchData(),
  );
}
```

### Loading State Pattern
**Show loading indicators during async operations:**

```dart
// Service
void _setLoading(bool value) {
  _isLoading = value;
  notifyListeners();
}

// UI
if (service.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

---

## API Integration Reference

### Authentication Headers
**All API requests require:**
- `x-api-passcode: PourRice` (always)
- `Authorization: Bearer <token>` (for protected endpoints)

### Endpoint Reference
**Base URL:** `https://vercel-express-api-alpha.vercel.app`

#### Authentication (`/API/Auth`)
- `POST /register` - Create account
- `POST /login` - Email/password login
- `POST /google` - Google OAuth
- `POST /verify` - Verify token
- `POST /reset-password` - Password reset
- `POST /logout` - Revoke tokens
- `DELETE /delete-account` - Delete account

#### Restaurants (`/API/Restaurants`)
- `GET /` - List all
- `GET /:id` - Get single
- `POST /` - Create
- `PUT /:id` - Update
- `DELETE /:id` - Delete
- `POST /:id/image` - Upload image
- `POST /:id/claim` - Claim ownership

#### Menu (`/API/Restaurants/:restaurantId/menu`)
- `GET /:restaurantId/menu` - List items
- `GET /:restaurantId/menu/:itemId` - Get item
- `POST /:restaurantId/menu` - Create item
- `PUT /:restaurantId/menu/:itemId` - Update item
- `DELETE /:restaurantId/menu/:itemId` - Delete item

#### Users (`/API/Users`)
- `GET /` - List all
- `GET /:uid` - Get profile
- `POST /` - Create profile (requires auth)
- `PUT /:uid` - Update profile (requires auth)
- `DELETE /:uid` - Delete profile (requires auth)

#### Bookings (`/API/Bookings`)
- `GET /` - List bookings (filtered by user, requires auth)
- `GET /:id` - Get booking (requires auth)
- `POST /` - Create booking (requires auth)
- `PUT /:id` - Update booking (requires auth)
- `DELETE /:id` - Delete booking (requires auth)

#### Reviews (`/API/Reviews`)
- `GET /` - List reviews (`?restaurantId=X` or `?userId=X`)
- `GET /:id` - Get review
- `POST /` - Create review (requires auth)
- `PUT /:id` - Update review (requires auth)
- `DELETE /:id` - Delete review (requires auth)
- `GET /Restaurant/:restaurantId/stats` - Get stats

#### Images (`/API/Images`)
- `POST /upload?folder=X` - Upload image (multipart/form-data)
- `DELETE /delete` - Delete image
- `GET /metadata?filePath=X` - Get metadata

#### Search (`/API/Algolia/Restaurants`)
- `GET /` - Search (`?query=X&districts=Y&keywords=Z`)
- `GET /facets/:facetName` - Get facet values
- `POST /advanced` - Advanced search

#### AI (`/API/Gemini`)
- `POST /generate` - Generate text
- `POST /chat` - Chat with history
- `POST /restaurant-description` - Generate description

#### Chat (`/API/Chat`)
- `GET /Rooms` - List rooms (requires auth)
- `GET /Rooms/:roomId` - Get room (requires auth)
- `POST /Rooms` - Create room (requires auth)
- `GET /Rooms/:roomId/Messages` - List messages (requires auth)
- `POST /Rooms/:roomId/Messages` - Send message (requires auth)
- `PUT /Rooms/:roomId/Messages/:messageId` - Edit message (requires auth)
- `DELETE /Rooms/:roomId/Messages/:messageId` - Delete message (requires auth)
- `GET /Stats` - Get chat stats (requires auth)

#### DocuPipe (`/API/DocuPipe`)
- `POST /upload` - Upload document (multipart/form-data)
- `GET /job/:jobId` - Check job status
- `GET /document/:documentId` - Get document
- `POST /extract-with-schema` - Extract with schema
- `POST /extract-menu` - Extract menu items
- `GET /standardization/:standardizationId` - Get standardization results

---

## Testing Strategy

### Unit Testing
**Test Services:**
- Mock HTTP responses
- Test state changes
- Test error handling

```dart
// Example: booking_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

void main() {
  group('BookingService', () {
    late BookingService bookingService;
    late MockAuthService mockAuthService;
    late MockClient mockClient;

    setUp(() {
      mockAuthService = MockAuthService();
      mockClient = MockClient();
      bookingService = BookingService(mockAuthService);
    });

    test('fetchBookings returns bookings on success', () async {
      // Arrange
      when(mockAuthService.getIdToken()).thenAnswer((_) async => 'test-token');
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('{"data": []}', 200));

      // Act
      await bookingService.fetchBookings();

      // Assert
      expect(bookingService.bookings, isEmpty);
      expect(bookingService.isLoading, false);
      expect(bookingService.error, isNull);
    });
  });
}
```

### Widget Testing
**Test Pages:**
- Test rendering
- Test user interactions
- Test navigation

### Integration Testing
**Test Flows:**
- Complete booking flow
- Complete review flow
- Authentication flow

---

## Performance Optimization

### Image Optimization
**Use cached_network_image for all remote images:**

```dart
CachedNetworkImage(
  imageUrl: restaurant.imageUrl ?? AppConfig.placeholderUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
)
```

### List Optimization
**Use ListView.builder for long lists:**

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index]);
  },
)
```

### State Management Optimization
**Only rebuild what changes using Consumer:**

```dart
Consumer<BookingService>(
  builder: (context, bookingService, child) {
    // Only this widget rebuilds when bookingService changes
    return Text('${bookingService.bookings.length}');
  },
)
```

### Lazy Loading
**Load data on demand:**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<BookingService>().fetchBookings();
  });
}
```

---

## Required Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...

  # New dependencies for missing features
  socket_io_client: ^3.1.3			# Real-time chat
  image_picker: ^1.0.7             # Image selection
  cached_network_image: ^3.3.1     # Image caching
  carousel_slider: ^4.2.1          # Carousels/swipers
  smooth_page_indicator: ^1.1.0    # Page indicators
  flutter_map: ^6.1.0              # Maps (if not using Google Maps)
  latlong2: ^0.9.0                 # Lat/lng for flutter_map
  # OR
  google_maps_flutter: ^2.5.3      # Google Maps (alternative)

  # Optional but recommended
  intl: ^0.19.0                    # Date formatting
  timeago: ^3.6.0                  # Relative time display
  flutter_rating_bar: ^4.0.1       # Star rating widget
  flutter_markdown: ^0.6.19        # Markdown rendering (for AI responses)
```

---

## Next Steps

### Immediate Actions
1. Review this implementation plan
2. Prioritize features based on business needs
3. Set up development timeline
4. Begin Phase 1 implementation (Booking & Review systems)

### Questions to Consider
1. **Maps:** Google Maps (paid) or Flutter Map (free OSM)?
2. **Image Upload:** Maximum file size? Image compression needed?
3. **Chat:** How many users per chat room? Message retention policy?
4. **AI:** Rate limiting on Gemini API? Conversation history storage?
5. **Analytics:** Do you want to add Firebase Analytics?

### Documentation Updates Needed
- Update README.md with new features
- Create API integration guide
- Document state management patterns
- Add widget catalog

---

## Conclusion

This comprehensive implementation plan provides:
- ✅ Complete feature gap analysis
- ✅ Detailed implementation guides with code examples
- ✅ Architecture patterns and best practices
- ✅ API integration reference
- ✅ Testing strategy
- ✅ Performance optimization guidelines

**Estimated Implementation Time:** 8-10 weeks (full-time development)

**Priority Order:**
1. Booking System (2 weeks) - Essential
2. Review System (1 week) - High value
3. Menu System (1 week) - Restaurant feature
4. Image Upload (1 week) - Visual enhancement
5. Real-time Chat (2 weeks) - Modern UX
6. AI Assistant (1 week) - Innovation
7. Restaurant Owner Dashboard (2 weeks) - Business feature
8. Advanced Search & Polish (1-2 weeks) - Final touches

---

**Document Version:** 1.0
**Created:** 2025-12-24
**Author:** Claude AI Assistant
**Project:** PourRice Flutter Application
