# CLAUDE.md

**Comprehensive Documentation for AI Assistants**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Technology Stack](#technology-stack)
4. [Architecture & Design Patterns](#architecture--design-patterns)
5. [Development Workflows](#development-workflows)
6. [Scripts & Build Configuration](#scripts--build-configuration)
7. [Code Conventions](#code-conventions)
8. [Key Components](#key-components)
9. [Data Layer & APIs](#data-layer--apis)
10. [Native Android Features](#native-android-features)
11. [Testing Strategy](#testing-strategy)
12. [Common Development Tasks](#common-development-tasks)
13. [Important Constraints](#important-constraints)
14. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Application Name
**PourRice** - A Flutter-based mobile application for discovering vegetarian and vegan restaurants in Hong Kong.

### Purpose
This application provides users with a comprehensive platform to:
- Discover vegetarian and vegan restaurants across 18 Hong Kong districts
- Search restaurants using full-text search with Algolia
- Filter by district and dietary keywords (Vegan, Vegetarian, Plant-Based, etc.)
- View restaurant details with embedded Google Maps
- Calculate distances from current GPS location
- Make table reservations with booking management
- Receive local notifications for booking reminders
- Toggle between English and Traditional Chinese languages
- Switch between light and dark themes

### Version
- **Current Version**: 1.0.0+1
- **Flutter SDK**: ^3.9.2
- **Dart SDK**: ^3.9.2

### Target Platform
Primarily Android (with web and iOS configurations present but not fully implemented)

### Codebase Statistics
- **Total Lines of Code**: ~6,710 lines (excluding comments)
- **Main Application Code**: `/lib` directory
- **Pages**: 5 UI pages
- **Services**: 7 business logic services
- **Reusable Widgets**: 1 navigation drawer
- **Data Models**: 5 primary models

---

## Repository Structure

### Directory Hierarchy

```
/home/user/Android-Assignment/
├── lib/                              # Main Dart source code
│   ├── main.dart                     # Application entry point & Provider setup
│   ├── config.dart                   # Environment configuration
│   ├── models.dart                   # Data models (Restaurant, User, Booking, etc.)
│   ├── firebase_options.dart         # Firebase multi-platform configuration
│   │
│   ├── pages/                        # UI Pages (Stateful/Stateless Widgets)
│   │   ├── login.dart                # Authentication page (login/register/Google OAuth)
│   │   ├── home.dart                 # Home page (featured + nearby restaurants)
│   │   ├── search.dart               # Search page (Algolia search + filters)
│   │   ├── account.dart              # User account management page
│   │   └── restaurant_detail.dart    # Restaurant detail page (maps, booking, share)
│   │
│   ├── services/                     # Business Logic Layer (ChangeNotifier services)
│   │   ├── auth_service.dart         # Firebase Authentication
│   │   ├── user_service.dart         # User profile CRUD (REST API)
│   │   ├── restaurant_service.dart   # Restaurant data (Algolia + REST API)
│   │   ├── restaurant_service_native.dart  # Direct Algolia SDK implementation
│   │   ├── booking_service.dart      # Booking CRUD (REST API)
│   │   ├── notification_service.dart # Local notifications scheduling
│   │   └── location_service.dart     # GPS location & distance calculations
│   │
│   └── widgets/                      # Reusable UI Components
│       └── drawer.dart               # Navigation drawer with theme/language toggles
│
├── assets/                           # Static Resources
│   ├── images/                       # Application icons & images
│   │   ├── App-Light.png             # Light mode logo
│   │   ├── App-Dark.png              # Dark mode logo
│   │   ├── Google.png                # Google sign-in button icon
│   │   ├── Placeholder.png           # Restaurant image placeholder
│   │   └── Eclipse.gif               # Loading animation
│   │
│   └── *.json                        # Sample data files
│       ├── vegetarian_restaurants_hk.json
│       ├── sample_users.json
│       ├── sample_restaurants.json
│       └── sample_reviews.json
│
├── android/                          # Android Platform Configuration
│   ├── app/
│   │   ├── build.gradle              # Android build configuration
│   │   ├── google-services.json      # Firebase Android configuration
│   │   └── src/main/
│   │       └── AndroidManifest.xml   # Permissions, metadata, Google Maps API key
│   └── gradle/                       # Gradle wrapper files
│
├── test/                             # Unit & Widget Tests
│   ├── widget_test.dart              # Basic widget smoke test
│   └── algolia_test.dart             # Algolia search integration test
│
├── .github/                          # CI/CD Workflows
│   └── workflows/
│       └── dart.yml                  # GitHub Actions workflow (lint + test)
│
├── pubspec.yaml                      # Flutter dependencies & asset manifest
├── analysis_options.yaml             # Dart linter configuration
├── devtools_options.yaml             # Flutter DevTools settings
└── README.md                         # Project documentation (minimal)
```

---

## Technology Stack

### Core Framework
- **Flutter**: ^3.9.2 - Google's UI toolkit for building natively compiled applications
- **Dart**: ^3.9.2 - Programming language optimised for UI development
- **Material Design 3**: Google's latest design system with modern aesthetics

### State Management
- **Provider**: ^6.1.2 - Official Flutter state management solution
  - Services extend `ChangeNotifier` (similar to RxJS `BehaviorSubject` in Angular)
  - `MultiProvider` for dependency injection at app root
  - `Consumer` widgets for reactive UI updates
  - `ChangeNotifierProxyProvider` for dependent services

### Backend Services

#### Firebase (Authentication & Database)
- **firebase_core**: ^3.8.1 - Firebase SDK initialisation
- **firebase_auth**: ^5.3.3 - Email/password + Google OAuth authentication
- **cloud_firestore**: ^5.5.2 - NoSQL database (accessed via REST API middleware)
- **google_sign_in**: ^6.2.2 - Native Google sign-in for Android

#### REST API
- **http**: ^1.2.2 - HTTP client for Vercel Express API
- **Base URL**: `https://vercel-express-api-alpha.vercel.app`
- **Authentication**: Bearer tokens from Firebase Auth
- **API Passcode**: `PourRice` (sent as `X-API-Passcode` header)

#### Search
- **algoliasearch**: ^1.41.1 - Full-text search SDK
- **algolia_helper_flutter**: ^1.5.0 - UI helpers for search interfaces
- **infinite_scroll_pagination**: ^5.1.1 - Lazy loading with pagination

### Native Android Features

#### Location Services
- **geolocator**: ^13.0.2 - GPS location access with accuracy options
- **google_maps_flutter**: ^2.13.1 - Embedded Google Maps with markers
- **permission_handler**: ^11.3.1 - Runtime permission requests (Android 6.0+)

#### Notifications
- **flutter_local_notifications**: ^18.0.1 - Scheduled local notifications
- **timezone**: ^0.9.4 - Timezone data for notification scheduling

#### User Actions
- **url_launcher**: ^6.3.1 - Launch URLs, phone dialler, email, maps
- **share_plus**: ^10.1.2 - Native Android share sheet integration

#### Performance
- **cached_network_image**: ^3.4.1 - Image caching with placeholder support

### UI/UX Libraries
- **carousel_slider**: ^5.1.1 - Auto-playing featured restaurant carousel
- **intl**: ^0.20.2 - Internationalisation (date/time formatting, localisation)
- **shared_preferences**: ^2.5.3 - Persistent key-value storage (theme, language)
- **cupertino_icons**: ^1.0.8 - iOS-style icons

---

## Architecture & Design Patterns

### Overall Architecture: Layered Service-Oriented Architecture

The application follows a **three-tier architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Pages/Widgets)                  │
│  - Stateful/Stateless Widgets                                │
│  - Material Design 3 components                              │
│  - Pages: Login, Home, Search, Account, RestaurantDetail     │
└───────────────────────────┬─────────────────────────────────┘
                            │ Consumer/Provider
                            │ (Reactive State Management)
┌───────────────────────────▼─────────────────────────────────┐
│              State Management Layer (Provider)               │
│  - ChangeNotifier pattern (extends Observable)               │
│  - Services notify listeners on state changes                │
│  - Automatic widget rebuilding                               │
└───────────────────────────┬─────────────────────────────────┘
                            │ Service Methods
┌───────────────────────────▼─────────────────────────────────┐
│                  Services Layer (Business Logic)             │
│  - AuthService (Firebase Auth, session management)           │
│  - UserService (Profile CRUD via REST API)                   │
│  - RestaurantService (Algolia search + REST API)             │
│  - BookingService (Booking CRUD via REST API)                │
│  - LocationService (GPS, distance calculations)              │
│  - NotificationService (Local notification scheduling)       │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP/Firebase/Algolia Calls
┌───────────────────────────▼─────────────────────────────────┐
│                      Data Sources Layer                      │
│  - Firebase Auth (Google OAuth, email/password)              │
│  - Firebase Firestore (via Vercel Express API)               │
│  - Algolia Search (full-text restaurant search)              │
│  - Device GPS (location coordinates)                         │
│  - SharedPreferences (theme, language persistence)           │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns

#### 1. Provider Pattern (Dependency Injection)
**Location**: `/lib/main.dart` lines 126-166

**Implementation**:
```dart
MultiProvider(
  providers: [
    // Pre-initialised service
    ChangeNotifierProvider.value(value: notificationService),

    // Independent services
    ChangeNotifierProvider(create: (_) => LocationService()),
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => RestaurantService()),

    // Dependent services (require AuthService)
    ChangeNotifierProxyProvider<AuthService, UserService>(
      create: (context) => UserService(context.read<AuthService>()),
      update: (context, authService, previous) =>
          previous ?? UserService(authService),
    ),
  ],
  child: const AppRoot(),
)
```

**Usage in Widgets**:
```dart
// Read once (doesn't rebuild on changes)
final authService = context.read<AuthService>();

// Watch (rebuilds when notifyListeners is called)
final restaurants = context.watch<RestaurantService>().restaurants;

// Consumer widget (more granular control)
Consumer<AuthService>(
  builder: (context, authService, child) {
    return Text(authService.user?.email ?? 'Not logged in');
  },
)
```

#### 2. Observer Pattern (ChangeNotifier)
Services notify UI of state changes, triggering automatic rebuilds.

```dart
class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();  // UI shows loading indicator

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      _user = credential.user;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();  // UI updates with user data
    }
  }
}
```

#### 3. Repository Pattern
Services abstract data sources, providing a clean API for UI components.

#### 4. Facade Pattern
Services simplify complex operations behind simple methods.

---

## Development Workflows

### Initial Setup

1. **Prerequisites**:
   ```bash
   flutter --version  # Should be >= 3.9.2
   dart --version     # Should be >= 3.9.2
   flutter doctor     # Verify installation
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Application**:
   ```bash
   flutter devices    # List available devices
   flutter run        # Run on connected device
   ```

### Development Cycle

1. **Code Modification**:
   - Edit files in `/lib` directory
   - Hot reload: Press `r` in terminal
   - Hot restart: Press `R` in terminal

2. **Linting**:
   ```bash
   flutter analyze
   dart fix --apply  # Auto-fix issues
   ```

3. **Testing**:
   ```bash
   flutter test
   flutter test --coverage
   ```

### Build & Deployment

```bash
# Android APK (Debug)
flutter build apk --debug

# Android APK (Release)
flutter build apk --release

# Android App Bundle (For Google Play)
flutter build appbundle --release
```

---

## Scripts & Build Configuration

This section provides detailed information about all build scripts, automation workflows, and configuration files used in the project.

### CI/CD Pipeline

#### GitHub Actions Workflow (`.github/workflows/dart.yml`)

**Purpose**: Automated continuous integration for linting and testing on every push/pull request to the main branch.

**Workflow Configuration**:
```yaml
name: Dart
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
```

**Workflow Steps**:
1. **Checkout Code**: Uses `actions/checkout@v4`
2. **Setup Dart SDK**: Uses `dart-lang/setup-dart@9a04e6d73cca37bd455e0608d7e5092f881fd603`
3. **Install Dependencies**: Runs `dart pub get`
4. **Static Analysis**: Runs `dart analyze` to check for errors and warnings
5. **Run Tests**: Executes `dart test` for unit and widget tests

**Usage Notes**:
- Runs on `ubuntu-latest` runner
- Does not perform formatting checks (commented out)
- Consider using `flutter analyze` and `flutter test` for Flutter-specific projects

**Triggering the Workflow**:
```bash
# Automatically triggers on:
git push origin main
# Or when creating/updating a pull request to main
```

---

### Android Build Configuration

#### Gradle Build System

The project uses **Gradle 8.12** with **Kotlin DSL** for build scripts.

#### Root Build Configuration (`android/build.gradle.kts`)

**Key Components**:

1. **Google Services Plugin**:
   ```kotlin
   id("com.google.gms.google-services") version "4.4.4" apply false
   ```
   Required for Firebase integration.

2. **Repository Configuration**:
   ```kotlin
   allprojects {
       repositories {
           google()
           mavenCentral()
       }
   }
   ```

3. **Custom Build Directory**:
   - Redirects build output to `../../build` (Flutter project structure)
   - Ensures Flutter and Gradle builds coexist properly

4. **Clean Task**:
   ```bash
   ./gradlew clean  # Deletes all build artifacts
   ```

#### Settings Configuration (`android/settings.gradle.kts`)

**Key Components**:

1. **Flutter SDK Integration**:
   - Reads `flutter.sdk` from `local.properties`
   - Includes Flutter Gradle plugin from Flutter SDK

2. **Plugin Management**:
   ```kotlin
   plugins {
       id("dev.flutter.flutter-plugin-loader") version "1.0.0"
       id("com.android.application") version "8.9.1" apply false
       id("org.jetbrains.kotlin.android") version "2.2.21" apply false
   }
   ```

3. **Gradle Plugin Repositories**:
   - Google Maven Repository
   - Maven Central
   - Gradle Plugin Portal

#### App Build Configuration (`android/app/build.gradle.kts`)

**Applied Plugins**:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

**Key Dependencies**:

1. **Core Library Desugaring** (for Java 8+ APIs on older Android versions):
   ```kotlin
   coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
   ```

2. **Firebase BOM** (Bill of Materials):
   ```kotlin
   implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
   implementation("com.google.firebase:firebase-analytics")
   ```
   - Ensures compatible Firebase library versions
   - No version numbers needed for individual Firebase libraries

**Android Configuration**:

1. **Application Namespace**:
   ```kotlin
   namespace = "com.example.android_assignment"
   ```

2. **SDK Versions**:
   - `compileSdk`: Dynamically set by Flutter
   - `minSdk`: Dynamically set by Flutter
   - `targetSdk`: Dynamically set by Flutter

3. **Java/Kotlin Compatibility**:
   ```kotlin
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
       isCoreLibraryDesugaringEnabled = true
   }
   kotlinOptions {
       jvmTarget = JavaVersion.VERSION_17.toString()
   }
   ```

4. **Default Configuration**:
   ```kotlin
   defaultConfig {
       applicationId = "com.example.android_assignment"
       multiDexEnabled = true  // Required for 64K+ method count
   }
   ```

5. **Build Types**:
   - **Debug**: Uses default debug signing config
   - **Release**: Currently uses debug keys (TODO: Add production signing config)

**Important Notes**:
- MultiDex is enabled to support large dependency count
- Release builds currently use debug signing (NOT production-ready)
- Core library desugaring allows modern Java APIs on Android 5.0+

#### Gradle Properties (`android/gradle.properties`)

**JVM Configuration**:
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
```

**Memory Allocation**:
- **Heap Size**: 8GB (`-Xmx8G`) - Handles large builds
- **Metaspace**: 4GB - For class metadata
- **Code Cache**: 512MB - For JIT compiled code
- **Heap Dump**: Enabled on OOM for debugging

**Jetifier**: Converts legacy support libraries to AndroidX

#### Gradle Wrapper (`android/gradle/wrapper/gradle-wrapper.properties`)

**Gradle Version**:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
```

**Running Gradle Commands**:
```bash
cd android
./gradlew tasks           # List all available tasks
./gradlew assembleDebug   # Build debug APK
./gradlew assembleRelease # Build release APK
./gradlew clean           # Clean build artifacts
./gradlew dependencies    # Show dependency tree
```

---

### Flutter/Dart Configuration

#### Dependency Management (`pubspec.yaml`)

**Project Metadata**:
```yaml
name: android_assignment
version: 1.0.0+1
publish_to: 'none'  # Private package
```

**SDK Requirements**:
```yaml
environment:
  sdk: ^3.9.2
```

**Key Dependency Categories**:

1. **State Management**:
   - `provider: ^6.1.2`

2. **Firebase Services**:
   - `firebase_core: ^3.8.1`
   - `firebase_auth: ^5.3.3`
   - `cloud_firestore: ^5.5.2`
   - `google_sign_in: ^6.2.2`

3. **Search Integration**:
   - `algoliasearch: ^1.41.1`
   - `algolia_helper_flutter: ^1.5.0`

4. **Native Android Features**:
   - `flutter_local_notifications: ^18.0.1`
   - `geolocator: ^13.0.2`
   - `google_maps_flutter: ^2.13.1`
   - `permission_handler: ^11.3.1`
   - `share_plus: ^10.1.2`
   - `url_launcher: ^6.3.1`

5. **UI/UX Enhancements**:
   - `carousel_slider: ^5.1.1`
   - `cached_network_image: ^3.4.1`
   - `shared_preferences: ^2.5.3`

6. **Utilities**:
   - `http: ^1.2.2`
   - `intl: ^0.20.2`
   - `timezone: ^0.9.4`
   - `auto_updater: ^1.0.0`

**Asset Configuration**:
```yaml
flutter:
  assets:
    - assets/vegetarian_restaurants_hk.json
    - assets/sample_users.json
    - assets/sample_restaurants.json
    - assets/sample_reviews.json
    - assets/images/Placeholder.png
    - assets/images/Google.png
    - assets/images/App-Light.png
    - assets/images/App-Dark.png
    - assets/images/Eclipse.gif
  uses-material-design: true
```

**Managing Dependencies**:
```bash
# Install dependencies
flutter pub get

# Upgrade to latest compatible versions
flutter pub upgrade

# Check for outdated packages
flutter pub outdated

# Add a new dependency
flutter pub add package_name

# Remove a dependency
flutter pub remove package_name
```

#### Linter Configuration (`analysis_options.yaml`)

**Lint Rules**:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Custom rules can be added here
    # avoid_print: false
    # prefer_single_quotes: true
```

**Running Static Analysis**:
```bash
# Analyze entire project
flutter analyze

# Auto-fix issues where possible
dart fix --apply

# Show available fixes without applying
dart fix --dry-run
```

---

### Android Platform Configuration

#### Android Manifest (`android/app/src/main/AndroidManifest.xml`)

**Required Permissions**:
```xml
<!-- Location Services -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Network -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

**Application Configuration**:
```xml
<application
    android:label="android_assignment"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

**Main Activity Configuration**:
- `launchMode="singleTop"` - Prevents multiple instances
- `android:exported="true"` - Can be launched by other apps
- `android:showWhenLocked="true"` - Show on lock screen (for notifications)
- `android:turnScreenOn="true"` - Wake screen for notifications
- `android:configChanges` - Handles configuration changes without restart

**Google Maps API Key**:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAun6GtoyZqdkzO55Cbc5DHIO-xL2oYlRI" />
```

**Important Security Note**:
- API keys should be stored in environment variables or secure vaults in production
- Current key is exposed in version control (acceptable for development only)

---

### Web Platform Configuration

#### PWA Manifest (`web/manifest.json`)

**Application Metadata**:
```json
{
    "name": "android_assignment",
    "short_name": "android_assignment",
    "start_url": ".",
    "display": "standalone",
    "background_color": "#0175C2",
    "theme_color": "#0175C2",
    "orientation": "portrait-primary",
    "prefer_related_applications": false
}
```

**Icon Configuration**:
- Regular icons: 192x192, 512x512
- Maskable icons: 192x192, 512x512 (for Android adaptive icons)

#### Web Entry Point (`web/index.html`)

**Key Features**:
- Base href placeholder: `$FLUTTER_BASE_HREF` (replaced during build)
- iOS web app meta tags for mobile browser compatibility
- Async Flutter bootstrap loading
- Favicon and manifest linking

**Building for Web**:
```bash
# Debug build
flutter build web

# Release build (optimized)
flutter build web --release

# With base href
flutter build web --release --base-href /app/
```

---

### Common Build Commands

#### Flutter Commands
```bash
# Development
flutter run                          # Run on connected device
flutter run --release                # Run in release mode
flutter run -d chrome                # Run in Chrome browser
flutter run -d <device_id>           # Run on specific device

# Building
flutter build apk                    # Debug APK
flutter build apk --release          # Release APK
flutter build appbundle --release    # Android App Bundle (for Play Store)
flutter build web --release          # Web build

# Cleaning
flutter clean                        # Remove build artifacts
flutter pub cache repair             # Repair package cache

# Analysis & Testing
flutter analyze                      # Static analysis
flutter test                         # Run all tests
flutter test --coverage              # Generate coverage report
flutter doctor                       # Check environment setup
```

#### Gradle Commands (from `android/` directory)
```bash
# Building
./gradlew assembleDebug              # Build debug APK
./gradlew assembleRelease            # Build release APK
./gradlew bundleRelease              # Build app bundle

# Cleaning
./gradlew clean                      # Clean build

# Information
./gradlew tasks                      # List all tasks
./gradlew dependencies               # Show dependency tree
./gradlew app:dependencies           # App module dependencies

# Signing
./gradlew signingReport              # Show signing configs
```

---

### Build Troubleshooting

#### Gradle Issues

**OutOfMemoryError**:
```bash
# Increase heap size in gradle.properties
org.gradle.jvmargs=-Xmx8G
```

**Dependency Conflicts**:
```bash
# View dependency tree
./gradlew app:dependencies

# Force dependency resolution
./gradlew app:dependencies --configuration releaseRuntimeClasspath
```

**Plugin Version Conflicts**:
```bash
# Clean and rebuild
flutter clean
cd android && ./gradlew clean
cd ..
flutter pub get
flutter build apk
```

#### Flutter Issues

**Plugin Registration Errors**:
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter run
```

**Cached Build Issues**:
```bash
# Nuclear option - clean everything
flutter clean
rm -rf build/
rm -rf android/build/
rm -rf android/app/build/
rm pubspec.lock
flutter pub get
```

**Gradle Daemon Issues**:
```bash
cd android
./gradlew --stop  # Stop all Gradle daemons
```

---

## Code Conventions

### Dart Style Guide
This project follows the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style) with Flutter lints enabled.

### File Organisation

1. **Imports Order** (enforced by linter):
   ```dart
   // 1. Dart core libraries
   import 'dart:async';

   // 2. Flutter framework
   import 'package:flutter/material.dart';

   // 3. Third-party packages (alphabetical)
   import 'package:firebase_auth/firebase_auth.dart';
   import 'package:provider/provider.dart';

   // 4. Relative imports (from own package)
   import '../services/auth_service.dart';
   import '../models.dart';
   ```

2. **File Naming**: Use `snake_case` for file names

### Naming Conventions

1. **Classes**: `UpperCamelCase`
   ```dart
   class AuthService extends ChangeNotifier {}
   ```

2. **Variables/Methods**: `lowerCamelCase`
   ```dart
   String userName;
   Future<void> fetchRestaurants() async {}
   ```

3. **Constants**: `lowerCamelCase` (Dart convention)
   ```dart
   const String apiPasscode = 'PourRice';
   const Color lightPrimary = Color(0xFF2E7D32);
   ```

4. **Private Members**: Prefix with `_`
   ```dart
   User? _user;
   bool _isLoading = false;
   ```

5. **Boolean Variables**: Use positive naming with `is`, `has`, `can`
   ```dart
   bool isLoggedIn;
   bool hasPermission;
   bool canEdit;
   ```

### Error Handling

Always handle async errors:
```dart
try {
  await riskyOperation();
} catch (e) {
  if (kDebugMode) print('Error: $e');
  _showErrorSnackBar(context, 'Operation failed');
}
```

### Async/Await Best Practices

```dart
// Preferred: async/await
Future<void> loadData() async {
  final data = await fetchData();
  processData(data);
}

// Avoid: .then() chains
Future<void> loadData() {
  return fetchData().then((data) => processData(data));
}
```

### UI/UX Conventions

1. **Responsive Design**:
   ```dart
   ConstrainedBox(
     constraints: const BoxConstraints(maxWidth: 600),
     child: content,
   )
   ```

2. **Loading States**: Always show loading indicators
   ```dart
   if (isLoading) {
     return const Center(child: CircularProgressIndicator());
   }
   ```

3. **Theme Awareness**: Use theme colours
   ```dart
   // GOOD
   color: Theme.of(context).colorScheme.primary

   // BAD
   color: Colors.green
   ```

### Internationalisation (i18n)

Use ternary for bilingual support:
```dart
final title = isTraditionalChinese ? '主頁' : 'Home';
```

---

## Key Components

### Services Layer

#### 1. AuthService (`/lib/services/auth_service.dart`)

**Purpose**: Manages user authentication and session state.

**Key Methods**:
- `Future<void> login(String email, String password)` - Email/password sign-in
- `Future<void> register(String email, String password, String displayName)` - Create account
- `Future<void> loginWithGoogle()` - Google OAuth sign-in
- `Future<void> logout()` - Sign out current user
- `Future<void> sendPasswordResetEmail(String email)` - Password recovery
- `Future<String?> getIdToken({bool forceRefresh = false})` - Get Firebase ID token

**State Properties**:
- `User? user` - Current Firebase user object
- `bool isLoggedIn` - Convenience getter
- `bool isLoading` - Loading state

#### 2. UserService (`/lib/services/user_service.dart`)

**Purpose**: Manages user profile data via REST API.

**Key Methods**:
- `Future<User?> getUserProfile(String uid)` - Fetch user profile
- `Future<void> createUserProfile(User user)` - Create new profile
- `Future<void> updateUserProfile(String uid, Map<String, dynamic> updates)` - Update profile

**Dependencies**: `AuthService` (for Firebase ID tokens)

#### 3. RestaurantService (`/lib/services/restaurant_service.dart`)

**Purpose**: Manages restaurant data from Algolia and REST API.

**Key Methods**:
- `Future<void> searchRestaurants(String query, {...filters})` - Full-text search
- `Future<Restaurant?> getRestaurantById(String id)` - Fetch single restaurant
- `Future<List<Restaurant>> getAllRestaurants()` - Fetch all restaurants

#### 4. BookingService (`/lib/services/booking_service.dart`)

**Purpose**: Manages restaurant table bookings via REST API.

**Key Methods**:
- `Future<void> createBooking(Booking booking)` - Create new booking
- `Future<List<Booking>> getUserBookings(String userId)` - Fetch user's bookings
- `Future<void> updateBooking(String id, Map<String, dynamic> updates)` - Update booking

**Dependencies**: `AuthService`

#### 5. LocationService (`/lib/services/location_service.dart`)

**Purpose**: Manages GPS location and distance calculations.

**Key Methods**:
- `Future<Position?> getCurrentLocation()` - Get GPS coordinates
- `Future<bool> requestPermission()` - Request location permission
- `double calculateDistance(lat1, lon1, lat2, lon2)` - Haversine formula

#### 6. NotificationService (`/lib/services/notification_service.dart`)

**Purpose**: Schedules local notifications for booking reminders.

**Key Methods**:
- `Future<void> initialise()` - Set up notification channels (call in main())
- `Future<void> scheduleBookingReminder(Booking booking)` - Schedule notification
- `Future<void> cancelNotification(int id)` - Cancel notification

---

### Pages (UI Layer)

#### 1. LoginPage (`/lib/pages/login.dart`)
- Email/password login and registration
- Google OAuth sign-in
- Password visibility toggle
- Forgot password dialog
- "Skip for now" guest access

#### 2. FrontPage/HomePage (`/lib/pages/home.dart`)
- Auto-playing carousel of featured restaurants
- Nearby restaurants sorted by GPS distance
- Distance badges with colour coding
- Pull-to-refresh functionality

#### 3. SearchPage (`/lib/pages/search.dart`)
- Full-text search with Algolia
- Infinite scroll pagination
- Multi-select district and keyword filters
- Auto-hiding search bar on scroll

#### 4. AccountPage (`/lib/pages/account.dart`)
- Profile information display
- Inline editing mode
- Profile photo display
- Account statistics

#### 5. RestaurantDetailPage (`/lib/pages/restaurant_detail.dart`)
- Restaurant information panels
- Embedded Google Maps
- Contact action buttons
- Booking dialog
- Share functionality

---

## Data Layer & APIs

### Data Models (`/lib/models.dart`)

#### 1. Restaurant Model

```dart
class Restaurant {
  final String id;
  final String? nameEn, nameTc;
  final String? addressEn, addressTc;
  final String? districtEn, districtTc;
  final double? latitude, longitude;
  final List<String>? keywordEn, keywordTc;
  final String? imageUrl;
  final Map<String, dynamic>? menu, openingHours, contacts;
  final int? seats;

  factory Restaurant.fromJson(Map<String, dynamic> json) { /* ... */ }
  Map<String, dynamic> toJson() { /* ... */ }
  String getName(bool isTC) => isTC ? (nameTc ?? nameEn ?? '') : (nameEn ?? '');
}
```

#### 2. User Model

```dart
class User {
  final String uid;
  final String? email, displayName, photoURL, phoneNumber, type, bio;
  final bool emailVerified;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt, modifiedAt, lastLoginAt;
  final int? loginCount;
}
```

#### 3. Booking Model

```dart
class Booking {
  final String id, userId, restaurantId, restaurantName;
  final DateTime dateTime;
  final int numberOfGuests;
  final String status;         // pending/confirmed/completed/cancelled
  final String paymentStatus;  // unpaid/paid/refunded
  final String? specialRequests;
}
```

### REST API Endpoints

**Base URL**: `https://vercel-express-api-alpha.vercel.app`

**Authentication Headers**:
```http
Authorization: Bearer <FIREBASE_ID_TOKEN>
X-API-Passcode: PourRice
```

#### User Endpoints
- `POST /API/Users` - Create user profile
- `GET /API/Users/:uid` - Get user profile
- `PUT /API/Users/:uid` - Update user profile
- `DELETE /API/Users/:uid` - Delete profile

#### Booking Endpoints
- `POST /API/Bookings` - Create booking
- `GET /API/Bookings?userId=X` - Get user bookings
- `PUT /API/Bookings/:id` - Update booking
- `DELETE /API/Bookings/:id` - Cancel booking

#### Restaurant Endpoints
- `GET /API/Restaurants` - Get all restaurants
- `GET /API/Restaurants/:id` - Get single restaurant
- `GET /API/Algolia/Restaurants` - Search restaurants

### Algolia Search Integration

**Configuration** (`/lib/config.dart`):
```dart
static const String algoliaAppId = 'V9HMGL1VIZ';
static const String algoliaSearchKey = '563754aa2e02b4838af055fbf37f09b5';
static const String algoliaIndexName = 'Restaurants';
```

**Usage**:
```dart
final _searcherRestaurants = HitsSearcher(
  applicationID: AppConfig.algoliaAppId,
  apiKey: AppConfig.algoliaSearchKey,
  indexName: AppConfig.algoliaIndexName,
);
```

### Firebase Configuration

**Project ID**: `cross-platform-assignmen-b97cc`

**Enabled Sign-In Methods**:
1. Email/Password
2. Google OAuth

**Collections** (accessed via REST API):
- `Users` - User profiles
- `Bookings` - Restaurant bookings
- `Restaurants` - Restaurant data

---

## Native Android Features

### Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### Google Maps API

**Configuration**:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAun6GtoyZqdkzO55Cbc5DHIO-xL2oYlRI" />
```

### Location Services

```dart
// Request permission
await Geolocator.requestPermission();

// Get location
Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

// Calculate distance
double distanceInMeters = Geolocator.distanceBetween(
  userLat, userLon, restaurantLat, restaurantLon,
);
```

### Local Notifications

```dart
// Schedule booking reminder
await notificationService.scheduleBookingReminder(booking);
```

### URL Launching

```dart
// Phone call
await launchUrl(Uri.parse('tel:${phoneNumber}'));

// Email
await launchUrl(Uri.parse('mailto:${email}'));

// Directions
await launchUrl(Uri.parse(
  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon'
));
```

### Share Sheet

```dart
await Share.share(
  'Check out ${restaurant.name} at PourRice!',
  subject: restaurant.name,
);
```

---

## Testing Strategy

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

### Test Types

1. **Unit Tests**: Test individual functions
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test complete user flows

---

## Common Development Tasks

### Adding a New Page

1. Create file: `lib/pages/my_new_page.dart`
2. Implement StatefulWidget
3. Add navigation in `main.dart` or drawer

### Adding a New Service

1. Create file: `lib/services/my_service.dart`
2. Extend `ChangeNotifier`
3. Register in `MultiProvider` in `main.dart`
4. Use in widgets with `context.watch<MyService>()`

### Adding a New Model

Add to `lib/models.dart` with `fromJson` and `toJson` methods

### Updating Dependencies

```bash
flutter pub outdated
flutter pub upgrade
```

---

## Important Constraints

### For AI Assistants: Critical Guidelines

#### 1. Architecture Patterns to Maintain

- **ALWAYS** use Provider pattern for services
- **ALWAYS** extend `ChangeNotifier` for new services
- **ALWAYS** call `notifyListeners()` after state changes

#### 2. Bilingual Support

**ALWAYS** provide both English and Traditional Chinese:
```dart
final title = isTraditionalChinese ? '中文標題' : 'English Title';
```

#### 3. Theme Awareness

**ALWAYS** use theme colours:
```dart
color: Theme.of(context).colorScheme.primary
```

#### 4. Async/Await

**ALWAYS** handle errors in async operations:
```dart
try {
  await riskyOperation();
} catch (e) {
  if (kDebugMode) print('Error: $e');
  _showErrorMessage(context);
}
```

#### 5. API Integration

**ALWAYS** include authentication headers:
```dart
headers: {
  'Authorization': 'Bearer $token',
  'X-API-Passcode': AppConfig.apiPasscode,
}
```

**ALWAYS** use `AppConfig.apiBaseUrl` (never hardcode URLs)

#### 6. User Feedback

- **ALWAYS** show loading indicators during async operations
- **ALWAYS** show error messages to users
- **ALWAYS** handle empty states with helpful messages

#### 7. Permissions

- **ALWAYS** request permissions before using native features
- **ALWAYS** handle permission denial gracefully

#### 8. Code Quality

- **ALWAYS** run `flutter analyze` before committing
- **ALWAYS** fix linter warnings
- **NEVER** commit commented-out code without explanation

---

## Troubleshooting

### Build Failures

```bash
# Clean build
flutter clean
flutter pub get
flutter build apk
```

### Runtime Errors

**Provider not found**:
```dart
// Use Consumer widget
Consumer<MyService>(
  builder: (context, myService, _) {
    // Use myService here
  },
)
```

**setState() after dispose**:
```dart
if (mounted) {
  setState(() { /* ... */ });
}
```

### API Issues

**401 Unauthorized**:
```dart
// Ensure fresh token
final token = await authService.getIdToken(forceRefresh: true);
```

### UI Issues

**Text overflow**:
```dart
Expanded(
  child: Text(longText, overflow: TextOverflow.ellipsis),
)
```

**Keyboard overflow**:
```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SingleChildScrollView(child: yourForm),
)
```

---

## Conclusion

This document provides comprehensive guidance for understanding and working with the PourRice Flutter application. When modifying the codebase:

1. ✅ **Maintain existing patterns** (Provider, ChangeNotifier, bilingual support)
2. ✅ **Follow code conventions** (naming, structure, async/await)
3. ✅ **Test thoroughly** (both themes, both languages, multiple devices)
4. ✅ **Handle errors gracefully** (user feedback, permission requests)
5. ✅ **Document changes** (inline comments for complex logic)

---

**Last Updated**: 2025-12-13
**Maintained By**: Development Team
**For**: AI Assistants (Claude, GPT, etc.)
