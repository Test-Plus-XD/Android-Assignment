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
├── main.dart                    # App entry + Provider setup
├── config/
│   ├── app_state.dart          # Theme/language state management
│   ├── theme.dart              # Material Design 3 theming
│   └── config.dart             # API endpoints & constants
├── models/                      # Domain models (Restaurant, User, Booking, etc.)
├── services/                    # Business logic (ChangeNotifier services)
│   ├── auth_service.dart       # Firebase Auth
│   ├── restaurant_service.dart # Algolia + REST API
│   ├── chat_service.dart       # Socket.IO + REST
│   ├── gemini_service.dart     # AI assistant
│   ├── booking_service.dart    # Bookings CRUD
│   └── ...
├── pages/                       # UI screens
│   ├── home_page.dart          # Featured + nearby restaurants
│   ├── search_page.dart        # Algolia search with filters
│   ├── restaurant_detail_page.dart
│   ├── chat_page.dart          # Real-time chat
│   ├── gemini_page.dart        # AI assistant chat
│   └── ...
├── widgets/                     # Reusable components
│   ├── navigation/             # App structure (MainShell, AppRoot)
│   ├── reviews/                # Review cards, forms, ratings
│   ├── menu/                   # Menu item widgets
│   ├── booking/                # Booking forms & cards
│   ├── chat/                   # Chat bubbles, input, typing
│   ├── carousel/               # Various carousel types
│   └── ...
└── constants/                   # Static data (districts, keywords, etc.)

android/
├── app/
│   ├── build.gradle.kts        # Android build config
│   ├── google-services.json    # Firebase Android config
│   └── src/main/AndroidManifest.xml  # Permissions & metadata
```

### Navigation System

**Role-Based Bottom Navigation**:
- **Guest**: Search - Home - Account (3 items)
- **Diner**: Chat - Search - Home - Account - Bookings (5 items)
- **Restaurant**: Chat - Search - Home - Account - Store Dashboard (5 items)

**Gemini AI FAB**: Bottom-left floating button for AI assistant access.

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

- **Lines of Code**: ~15,000+ (excluding generated files)
- **Pages**: 15+ UI screens
- **Services**: 10+ business logic services
- **Widgets**: 50+ reusable components
- **Models**: 20+ domain models
- **Languages**: English + Traditional Chinese (full bilingual)
- **Platforms**: Android (primary), Web/iOS (configured)

---

**Last Updated**: 2025-12-26
**Version**: 1.0.0+1
**Maintained By**: Development Team & Claude AI Assistant
