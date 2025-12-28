# CLAUDE.md

**AI Assistant Documentation for PourRice Flutter App**

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Project Overview](#project-overview)
3. [Architecture](#architecture)
4. [Key Technologies](#key-technologies)
5. [Code Patterns](#code-patterns)
6. [API Integration](#api-integration)
7. [Development Guidelines](#development-guidelines)
8. [Common Tasks](#common-tasks)

---

## Quick Start

### Application: PourRice
A Flutter mobile app for discovering vegetarian/vegan restaurants in Hong Kong with bilingual support (EN/TC).

### Core Features
- Restaurant search with Algolia (full-text + filters)
- GPS-based nearby restaurants
- Real-time chat with Socket.IO
- AI assistant (Google Gemini)
- Table bookings with notifications
- Reviews & ratings system
- Restaurant owner dashboard
- QR code menu scanner (scan to view restaurant menus)
- QR code generator for restaurant owners
- Bilingual UI (English/Traditional Chinese)
- Dark/Light theme toggle

### Tech Stack
- **Framework**: Flutter 3.9.2+, Dart 3.9.2+
- **State**: Provider (ChangeNotifier pattern)
- **Backend**: Vercel Express API, Firebase Auth/Firestore
- **Search**: Algolia
- **Chat**: Socket.IO (Railway server)
- **AI**: Google Gemini 2.5
- **Maps**: Google Maps Flutter
- **Notifications**: flutter_local_notifications
- **QR Codes**: qr_flutter 4.1.0 (generation), mobile_scanner 7.1.4 (scanning)

### Environment
- **API Base**: `https://vercel-express-api-alpha.vercel.app`
- **Socket.IO**: `https://railway-socket-production.up.railway.app`
- **API Passcode**: `PourRice` (required header: `x-api-passcode`)
- **Auth**: Firebase ID tokens (`Authorization: Bearer <token>`)

---

## Project Overview

### Repository Structure

```
lib/
├── main.dart                              # App entry point + Provider setup
├── config.dart                            # API endpoints & constants (AppConfig)
├── firebase_options.dart                  # Firebase configuration (auto-generated)
├── models.dart                            # Barrel export file for all models
│
├── config/
│   ├── app_state.dart                     # Theme/language state management
│   └── theme.dart                         # Material Design 3 theming
│
├── constants/
│   ├── districts.dart                     # Hong Kong districts data
│   ├── keywords.dart                      # Restaurant keywords/tags
│   ├── payments.dart                      # Payment methods
│   └── weekdays.dart                      # Day of week constants
│
├── models/
│   ├── booking.dart                       # Booking model
│   ├── chat.dart                          # ChatRoom, ChatMessage, TypingIndicator
│   ├── docupipe.dart                      # Document pipeline model
│   ├── gemini.dart                        # GeminiMessage model
│   ├── image.dart                         # Image upload model
│   ├── menu.dart                          # MenuItem, CreateMenuItemRequest
│   ├── restaurant.dart                    # Restaurant model
│   ├── review.dart                        # Review, ReviewStats models
│   ├── search.dart                        # SearchFilters model
│   └── user.dart                          # User model
│
├── services/
│   ├── auth_service.dart                  # Firebase Auth (login/logout/register)
│   ├── booking_service.dart               # Table reservations CRUD
│   ├── chat_service.dart                  # Socket.IO + REST chat
│   ├── docupipe_service.dart              # Document processing service
│   ├── gemini_service.dart                # Google Gemini AI assistant
│   ├── image_service.dart                 # Firebase Storage image upload
│   ├── location_service.dart              # GPS + distance calculations
│   ├── menu_service.dart                  # Restaurant menu items CRUD
│   ├── notification_service.dart          # Local notifications
│   ├── restaurant_service.dart            # Algolia search + REST API
│   ├── restaurant_service_native.dart     # Native restaurant operations
│   ├── review_service.dart                # Reviews CRUD
│   ├── store_service.dart                 # Restaurant owner dashboard
│   └── user_service.dart                  # User profile management
│
├── pages/
│   ├── account_page.dart                  # User account & settings
│   ├── bookings_page.dart                 # User's bookings list
│   ├── chat_page.dart                     # Chat rooms list
│   ├── chat_room_page.dart                # Individual chat room
│   ├── gemini_page.dart                   # AI assistant chat interface
│   ├── home_page.dart                     # Featured + nearby restaurants
│   ├── login_page.dart                    # Login/register screen
│   ├── qr_scanner_page.dart               # QR code scanner for menu links
│   ├── restaurant_detail_page.dart        # Restaurant details view
│   ├── restaurant_menu_page.dart          # Full menu view
│   ├── restaurant_reviews_page.dart       # Restaurant reviews list
│   ├── search_page.dart                   # Algolia search with filters
│   ├── store_page.dart                    # Restaurant owner dashboard
│   ├── store_bookings_page.dart           # Restaurant bookings management
│   ├── store_info_edit_page.dart          # Restaurant info editing
│   └── store_menu_manage_page.dart        # Restaurant menu management
│
├── widgets/
│   ├── drawer.dart                        # Navigation drawer
│   │
│   ├── ai/
│   │   ├── gemini_chat_button.dart        # Gemini floating action button
│   │   └── suggestion_chips.dart          # AI suggestion chips
│   │
│   ├── booking/
│   │   ├── booking_card.dart              # Individual booking display
│   │   ├── booking_dialog.dart            # Booking creation dialog
│   │   ├── booking_form.dart              # Booking creation form
│   │   └── booking_list.dart              # List of bookings
│   │
│   ├── carousel/
│   │   ├── hero_carousel.dart             # Hero image carousel
│   │   ├── menu_carousel.dart             # Menu items carousel
│   │   ├── offer_carousel.dart            # Offers/promotions carousel
│   │   └── restaurant_carousel.dart       # Restaurant cards carousel
│   │
│   ├── chat/
│   │   ├── chat_bubble.dart               # Message bubble with image support
│   │   ├── chat_input.dart                # Message input with image attach
│   │   ├── chat_room_list.dart            # Chat rooms list item
│   │   └── typing_indicator.dart          # "User is typing..." indicator
│   │
│   ├── images/
│   │   ├── image_picker_button.dart       # Image selection button
│   │   ├── image_preview.dart             # Image preview widget
│   │   └── upload_progress_indicator.dart # Upload progress display
│   │
│   ├── menu/
│   │   ├── bulk_import_review_dialog.dart # DocuPipe bulk import review dialog
│   │   ├── menu_item_card.dart            # Menu item display card
│   │   ├── menu_item_dialog.dart          # Menu item create/edit dialog
│   │   ├── menu_item_form.dart            # Menu item create/edit form
│   │   └── menu_list.dart                 # Grouped menu items list
│   │
│   ├── account/
│   │   └── account_type_selector.dart     # New user account type selection dialog
│   │
│   ├── navigation/
│   │   ├── app_root.dart                  # Root widget with MaterialApp
│   │   └── main_shell.dart                # Main navigation shell
│   │
│   ├── qr/
│   │   └── menu_qr_generator.dart         # QR code generator for restaurant menus
│   │
│   ├── restaurant/
│   │   ├── action_buttons_row.dart        # Action buttons (Call, Chat, AI, Directions, Website)
│   │   ├── claim_restaurant_button.dart   # Claim restaurant button (Restaurant users)
│   │   ├── contact_info_card.dart         # Contact information card
│   │   ├── interactive_map_preview.dart   # Interactive Google Maps preview
│   │   ├── menu_preview_section.dart      # Menu items preview carousel
│   │   ├── opening_hours_list.dart        # Weekly opening hours list
│   │   ├── restaurant_header.dart         # Restaurant name, rating, and distance
│   │   └── reviews_carousel.dart          # Reviews preview carousel
│   │
│   ├── reviews/
│   │   ├── review_card.dart               # Individual review display
│   │   ├── review_form.dart               # Review creation form
│   │   ├── review_list.dart               # Reviews list
│   │   ├── review_stats.dart              # Rating statistics widget
│   │   └── star_rating.dart               # Star rating input/display
│   │
│   └── search/
│       ├── filter_button.dart             # Filter toggle button
│       ├── filter_dialog.dart             # Search filters dialog
│       ├── restaurant_card.dart           # Restaurant card for search results
│       ├── restaurant_search_card.dart    # Search result card (legacy)
│       └── search_filter_section.dart     # Filter section with chips

android/
├── app/
│   ├── build.gradle.kts                   # Android build config
│   ├── google-services.json               # Firebase Android config
│   └── src/main/
│       ├── AndroidManifest.xml            # Permissions & metadata
│       └── kotlin/.../MainActivity.kt     # Main activity
```

**Total: 100 Dart files**
- Root level: 4 files
- config/: 2 files
- constants/: 4 files
- models/: 10 files
- services/: 14 files
- pages/: 16 files
- widgets/: 50 files (across 12 subdirectories)

### Navigation System

**Role-Based Bottom Navigation**:
- **Guest**: Search (middle-left) - Home (centre, FAB) - Account (middle-right) (3 items)
- **Diner**: Chat - Search - Home (centre, FAB) - Account - Bookings (5 items)
- **Restaurant**: Chat - Search - Home (centre, FAB) - Account - Store Dashboard (5 items)

**Gemini AI FAB**: Bottom-left floating button for AI assistant access (logged in users only).

---

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│  UI Layer (Pages/Widgets)           │  ← Stateful/Stateless widgets
└─────────────┬───────────────────────┘
              │ Consumer/Provider (reactive)
┌─────────────▼───────────────────────┐
│  State Management (Provider)        │  ← ChangeNotifier services
└─────────────┬───────────────────────┘
              │ Service methods
┌─────────────▼───────────────────────┐
│  Services Layer (Business Logic)    │  ← HTTP/Firebase/Algolia/Socket.IO
└─────────────┬───────────────────────┘
              │ API calls
┌─────────────▼───────────────────────┐
│  Data Sources (APIs/Firebase/GPS)   │  ← External data sources
└─────────────────────────────────────┘
```

### Provider Pattern

**Dependency Injection** (`main.dart`):
```dart
MultiProvider(
  providers: [
    // Independent services
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => RestaurantService()),
    ChangeNotifierProvider(create: (_) => GeminiService()),

    // Dependent services (require AuthService)
    ChangeNotifierProxyProvider<AuthService, UserService>(
      create: (ctx) => UserService(ctx.read<AuthService>()),
      update: (_, auth, prev) => prev ?? UserService(auth),
    ),
    ChangeNotifierProxyProvider<AuthService, ChatService>(
      create: (ctx) => ChatService(ctx.read<AuthService>()),
      update: (_, auth, prev) => prev ?? ChatService(auth),
    ),
  ],
  child: const AppRoot(),
)
```

**Usage in Widgets**:
```dart
// Read once (no rebuild)
final service = context.read<MyService>();

// Watch (rebuilds on changes)
final data = context.watch<MyService>().data;

// Consumer (granular control)
Consumer<MyService>(
  builder: (context, service, child) => Text(service.value),
)
```

### ChangeNotifier Pattern

**Service Structure**:
```dart
class MyService extends ChangeNotifier {
  bool _isLoading = false;
  List<Data> _data = [];

  bool get isLoading => _isLoading;
  List<Data> get data => _data;

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();  // UI shows loading

    try {
      _data = await api.getData();
    } finally {
      _isLoading = false;
      notifyListeners();  // UI shows data
    }
  }
}
```

---

## Key Technologies

### State Management: Provider

- **AppState**: Theme/language preferences (persisted to SharedPreferences)
- **AuthService**: Firebase Auth (login/logout/session)
- **RestaurantService**: Algolia search + REST API
- **ChatService**: Socket.IO real-time + REST persistence
- **GeminiService**: AI assistant interactions
- **BookingService**: Table reservations CRUD
- **MenuService**: Restaurant menu items CRUD with per-restaurant caching (prevents state clashes when multiple pages load different restaurant menus)
- **UserService**: Profile management

### Backend APIs

**REST API** (`https://vercel-express-api-alpha.vercel.app`):
- `/API/Users` - User profiles
- `/API/Restaurants` - Restaurant CRUD
- `/API/Restaurants/:id/menu` - Menu items
- `/API/Bookings` - Reservations
- `/API/Chat/Records/:uid` - Chat room list
- `/API/Chat/Rooms/:roomId/Messages` - Chat history
- `/API/Gemini/chat` - AI conversations
- `/API/Images/upload` - Image uploads (multipart)

**Algolia Search**:
- App ID: `V9HMGL1VIZ`
- Index: `Restaurants`
- Features: Full-text search, faceted filters, geo-search

**Socket.IO** (`https://railway-socket-production.up.railway.app`):
- Events: `register`, `join-room`, `send-message`, `new-message`, `user-typing`
- Requires: `userId`, `displayName`, `authToken` on connection

### Authentication

**Firebase Auth**:
- Email/password
- Google OAuth (Android native)
- Guest mode (skip login)

**Headers for API**:
```dart
headers: {
  'x-api-passcode': 'PourRice',
  'Authorization': 'Bearer $firebaseIdToken',  // If authenticated
}
```

---

## Code Patterns

### Bilingual Support

**Pattern**: Use ternary with `isTraditionalChinese` boolean:
```dart
final text = isTraditionalChinese ? '中文文字' : 'English Text';
```

**Language State**: Managed in `AppState`, passed as props to pages:
```dart
// AppState toggles language
await appState.toggleLanguage(true);  // Switch to TC

// Pages receive as prop
class MyPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const MyPage({required this.isTraditionalChinese});
}
```

### Theme Awareness

**Always use theme colors**:
```dart
// GOOD ✅
color: Theme.of(context).colorScheme.primary

// BAD ❌
color: Colors.green
```

### Async/Await

**Always handle errors**:
```dart
try {
  await riskyOperation();
} catch (e) {
  if (kDebugMode) print('Error: $e');
  _showErrorSnackBar(context, 'Operation failed');
} finally {
  if (mounted) setState(() => _isLoading = false);
}
```

**Always check `mounted` before `setState`**:
```dart
Future<void> _loadData() async {
  final data = await fetchData();
  if (mounted) {
    setState(() => _data = data);
  }
}
```

### FutureBuilder with Services

**Problem**: Calling service methods in `future:` parameter causes setState during build.

**Solution**: Initialize Future in `initState`:
```dart
class _MyWidgetState extends State<MyWidget> {
  Future<Data>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = context.read<MyService>().getData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Data>(
      future: _dataFuture,  // ✅ Stable reference
      builder: (context, snapshot) { ... },
    );
  }
}
```

### Page Caching in Navigation

**Pattern**: Cache pages but invalidate on state changes:
```dart
List<Widget>? _cachedPages;
String? _lastUserType;
bool? _lastLoginState;
bool? _lastLanguage;

if (_cachedPages == null ||
    _lastLoginState != isLoggedIn ||
    _lastUserType != userType ||
    _lastLanguage != widget.isTraditionalChinese) {
  _cachedPages = _buildPages();
  _lastLoginState = isLoggedIn;
  _lastUserType = userType;
  _lastLanguage = widget.isTraditionalChinese;
}
```

---

## API Integration

### REST API Calls

**Standard Pattern**:
```dart
final token = await _authService.getIdToken();
final response = await http.get(
  Uri.parse('${AppConfig.apiBaseUrl}/API/Endpoint'),
  headers: {
    'x-api-passcode': AppConfig.apiPasscode,
    if (token != null) 'Authorization': 'Bearer $token',
  },
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  return Data.fromJson(data);
} else {
  throw Exception('API Error: ${response.statusCode}');
}
```

### Socket.IO Integration

**Connection**:
```dart
_socket = io(AppConfig.socketIOUrl, OptionBuilder()
  .setTransports(['websocket'])
  .disableAutoConnect()
  .build());

_socket!.connect();

_socket!.onConnect((_) {
  _socket!.emit('register', {
    'userId': userId,
    'displayName': displayName,
    'authToken': authToken,
  });
});

_socket!.on('new-message', (data) {
  final message = ChatMessage.fromJson(data);
  _handleIncomingMessage(message);
});
```

**Events**:
- `register` (emit on connect)
- `join-room` (join chat room)
- `send-message` (send message)
- `new-message` (receive message)
- `typing` (send typing status)
- `user-typing` (receive typing status)

### Algolia Search

**Basic Search**:
```dart
final response = await http.get(
  Uri.parse('${AppConfig.apiBaseUrl}/API/Algolia/Restaurants')
    .replace(queryParameters: {
      'query': searchQuery,
      'districts': districts.join(','),
      'keywords': keywords.join(','),
      'page': page.toString(),
      'hitsPerPage': '20',
    }),
  headers: {'x-api-passcode': AppConfig.apiPasscode},
);

final data = json.decode(response.body);
final restaurants = (data['hits'] as List)
  .map((json) => Restaurant.fromJson(json))
  .toList();
```

---

## Development Guidelines

### Critical Rules for AI Assistants

#### 1. Bilingual Support (MANDATORY)
**ALWAYS** provide both English and Traditional Chinese:
```dart
final title = isTC ? '中文標題' : 'English Title';
```

#### 2. Theme Awareness (MANDATORY)
**ALWAYS** use theme colors, never hardcode:
```dart
Theme.of(context).colorScheme.primary  // ✅
Colors.green                           // ❌
```

#### 3. Error Handling (MANDATORY)
**ALWAYS** wrap async operations in try-catch:
```dart
try {
  await operation();
} catch (e) {
  _handleError(e);
}
```

#### 4. Mounted Check (MANDATORY)
**ALWAYS** check `mounted` before `setState`:
```dart
if (mounted) setState(() { ... });
```

#### 5. Provider Pattern (MANDATORY)
- **ALWAYS** extend `ChangeNotifier` for services
- **ALWAYS** call `notifyListeners()` after state changes
- **ALWAYS** use `context.read<>()` for one-time reads
- **ALWAYS** use `context.watch<>()` for reactive rebuilds

#### 6. API Integration (MANDATORY)
- **ALWAYS** include `x-api-passcode: PourRice` header
- **ALWAYS** use `AppConfig.apiBaseUrl` (never hardcode URLs)
- **ALWAYS** handle 401/403 errors (token refresh)

#### 7. Socket.IO (MANDATORY)
- **ALWAYS** emit `register` event after connection
- **ALWAYS** use hyphenated event names (`join-room`, not `join_room`)
- **ALWAYS** include `userId` and `displayName` in events

#### 8. Model Updates
- **ALWAYS** update both `fromJson` and `toJson` methods
- **ALWAYS** handle nullable fields properly

### Code Quality

**Linting**:
```bash
flutter analyze        # Check for issues
dart fix --apply       # Auto-fix issues
```

**Testing**:
```bash
flutter test           # Run unit tests
flutter test --coverage  # Generate coverage
```

**Build**:
```bash
flutter build apk --release        # Android APK
flutter build appbundle --release  # Play Store bundle
```

---

## Common Tasks

### Adding a New Page

1. Create file: `lib/pages/my_page.dart`
2. Implement StatefulWidget with language prop:
```dart
class MyPage extends StatefulWidget {
  final bool isTraditionalChinese;
  const MyPage({required this.isTraditionalChinese});

  @override
  State<MyPage> createState() => _MyPageState();
}
```
3. Add to navigation in `main_shell.dart` `_buildPages()` method
4. Add navigation item in `_buildNavItems()` method
5. Add title in `_buildPageTitles()` method

### Adding a New Service

1. Create file: `lib/services/my_service.dart`
2. Extend ChangeNotifier:
```dart
class MyService extends ChangeNotifier {
  final AuthService? _authService;
  MyService([this._authService]);

  Future<void> doSomething() async {
    notifyListeners();
  }
}
```
3. Register in `main.dart`:
```dart
ChangeNotifierProvider(create: (_) => MyService()),
// Or if depends on AuthService:
ChangeNotifierProxyProvider<AuthService, MyService>(
  create: (ctx) => MyService(ctx.read<AuthService>()),
  update: (_, auth, prev) => prev ?? MyService(auth),
),
```
4. Use in widgets: `context.watch<MyService>()`

### Adding a New Model

1. Create file: `lib/models/my_model.dart`
2. Implement model with fromJson/toJson:
```dart
class MyModel {
  final String id;
  final String? name;

  MyModel({required this.id, this.name});

  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
    };
  }
}
```
3. Export in `lib/models.dart`: `export 'models/my_model.dart';`

### Adding API Endpoint Integration

1. Add method to relevant service:
```dart
Future<Data> fetchData() async {
  final token = await _authService?.getIdToken();
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/API/MyEndpoint'),
    headers: {
      'x-api-passcode': AppConfig.apiPasscode,
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return Data.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to fetch data');
  }
}
```
2. Call method in UI:
```dart
final service = context.read<MyService>();
await service.fetchData();
```

### Adding Socket.IO Event

1. Add event listener in `chat_service.dart`:
```dart
_socket!.on('my-event', (data) {
  // Handle event
  notifyListeners();
});
```
2. Emit event:
```dart
_socket!.emit('my-event', {
  'userId': userId,
  'data': myData,
});
```

### Using Store Management Features

**Restaurant Owner Dashboard** (`store_page.dart`):
- Overview of restaurant information
- Quick action cards for menu, bookings, reviews, and settings
- Statistics display (menu items count, today's bookings)
- QR code generator for menu sharing

**Restaurant Information Editing** (`store_info_edit_page.dart`):
- Edit restaurant name (EN/TC), address (EN/TC)
- Select district from Hong Kong districts list
- Choose multiple keywords/tags for restaurant categorization
- Set number of seats
- Update contact information (phone, email, website)
- Select payment methods (multiple selection)
- Configure opening hours for each day of the week
- Set location coordinates (latitude/longitude)

**Menu Management** (`store_menu_manage_page.dart`):
- View all menu items in a list
- Add new menu items with inline dialog
- Edit existing menu items
- Delete menu items with confirmation
- **Bulk Import via DocuPipe**: Upload menu documents (PDF, images, text) for AI-powered extraction
  - Supports PDF, JPG, JPEG, PNG, WEBP, TXT, JSON files
  - Automatically extracts menu items with bilingual support (EN/TC)
  - Review extracted items before saving
  - Batch save all extracted items to database
- Each item includes: Name (EN/TC), Description (EN/TC), Price, Image URL
- Refresh functionality to reload menu items

**Bookings Management** (`store_bookings_page.dart`):
- View all restaurant bookings
- Filter by status: all, pending, confirmed, completed, cancelled
- Statistics cards showing today's bookings, pending count, and total bookings
- Action buttons for pending bookings: Confirm or Reject
- Mark confirmed bookings as completed
- Display booking details: customer name, date/time, party size, special requests
- Pull-to-refresh support

### Using QR Code Features

**For Restaurant Owners (Generate QR Code)**:
1. Navigate to Store Dashboard page (available to users with 'Restaurant' account type)
2. Scroll to the "Menu QR Code" section
3. The QR code is automatically generated with format: `pourrice://menu/{restaurantId}`
4. Use the "Expand" button to show full-screen QR for easy scanning
5. Use the "Share" button to export QR code as PNG image for printing or social media

**For Diners (Scan QR Code)**:
1. Open the navigation drawer (hamburger menu)
2. Tap "Scan QR Code" option
3. Point camera at restaurant's QR code
4. App automatically detects and validates the QR code format
5. App fetches restaurant details and navigates to the menu page

**QR Code Format**:
- Deep link URL: `pourrice://menu/{restaurantId}`
- The scanner validates this format and extracts the restaurant ID
- It then calls `RestaurantService.getRestaurantById()` to verify the restaurant exists
- Finally navigates to `RestaurantMenuPage` with the restaurant details

**Technical Notes**:
- QR codes use error correction level H (30% redundancy)
- Scanner requires camera permission (already configured in AndroidManifest.xml)
- Scanner supports torch (flashlight) for low-light environments
- QR generator uses `RepaintBoundary` to capture widget as PNG for sharing

### Troubleshooting

**Build Errors**:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk
```

**setState During Build**:
- Use `WidgetsBinding.instance.addPostFrameCallback()`
- Initialize Future in `initState()`, not in `build()`

**Provider Not Found**:
- Ensure service is registered in `main.dart`
- Use `Consumer` widget or `context.watch<>()`

**API 401 Errors**:
- Check Firebase ID token is included
- Force refresh token: `getIdToken(forceRefresh: true)`

**Socket.IO Not Connecting**:
- Ensure `register` event is emitted after connection
- Check `authToken` is valid Firebase ID token
- Verify event names use hyphens, not underscores

---

## Project Statistics

- **Total Dart Files**: 100
- **Lines of Code**: 21,031 (non-empty, non-comment lines, excluding generated files)
  - Main files: 227 lines
  - Config: 145 lines
  - Constants: 409 lines
  - Models: 1,270 lines
  - Services: 3,300 lines
  - Pages: 7,000 lines (refactored for maintainability)
  - Widgets: 7,950 lines (50 components across 12 subdirectories)
- **Pages**: 16 UI screens
- **Services**: 14 business logic services
- **Widgets**: 50 reusable components (across 12 subdirectories)
- **Models**: 10 domain models
- **Constants**: 4 static data files
- **Languages**: English + Traditional Chinese (full bilingual)
- **Platforms**: Android (primary), Web/iOS (configured)

### Recent Refactoring (2025-12-27)
#### Phase 1 (Earlier)
- Extracted 5 new widget files from large page files for better code organization
- Reduced `search_page.dart` from 1000 → 623 lines
- Reduced `store_menu_manage_page.dart` from 822 → 547 lines

#### Phase 2 (Refactoring)
- **Refactored `restaurant_detail_page.dart`**: Reduced from 875 → 635 lines (240 lines removed)
- **Created 4 new reusable widgets**:
  - `booking_dialog.dart` (166 lines) - Extracted booking dialog logic
  - `action_buttons_row.dart` (93 lines) - Reusable action buttons
  - `restaurant_header.dart` (79 lines) - Restaurant name/rating header
  - `opening_hours_list.dart` (51 lines) - Weekly hours display
- **Removed 5 unused widgets** in `lib/widgets/restaurant/`:
  - `contact_actions.dart`, `hero_image_section.dart`, `opening_hours_card.dart`
  - `restaurant_info_card.dart`, `review_summary_card.dart`

#### Phase 3 (Bug Fixes & Feature Restoration)
- **Fixed setState during build error**: Moved data loading to `addPostFrameCallback`
- **Restored claim restaurant button** (`claim_restaurant_button.dart`, 153 lines):
  - Allows Restaurant-type users to claim unclaimed restaurants
  - Validates user type and ownership status
  - Integrated with StoreService for claiming logic
- All page files now under 950 lines for improved maintainability

#### Phase 4 (2025-12-28) - Bug Fixes & UX Improvements
- **Fixed image upload API response parsing**: Changed `downloadURL` to `imageUrl` to match API
- **Fixed image upload MIME type handling**: Explicitly set MIME type for uploads, handles common typos like `.jepg` → `image/jpeg`
- **Fixed bulk menu import field names**: API expects `Name_EN`, `Name_TC`, `Description_EN`, `Description_TC` (not camelCase)
- **Fixed menu item deletion**: API returns 204 (No Content) on success, now properly handled
- **Fixed displayName for new users**: Added delay to wait for Firebase to propagate displayName during registration
- **Menu management now fetches fresh items**: Always uses `forceRefresh: true` when loading menu items
- **Added new user onboarding flow**:
  - Created `account_type_selector.dart` - full-screen dialog for account type selection
  - New users must select Diner or Restaurant account type before using app
  - UserService now exposes `needsAccountTypeSelection` getter
- **Improved chat service behaviour**:
  - Chat rooms are now refreshed each time user enters the chat page
  - Socket.IO connection uses lazy initialization (only when needed)
  - Chat cache is properly cleared on user logout
- **UI cleanup**:
  - Removed "My Bookings" title from bookings page AppBar
  - Removed "Store Dashboard" title from store page AppBar

---

**Last Updated**: 2025-12-28
**Version**: 1.0.0+1
**Maintained By**: Development Team & Claude AI Assistant