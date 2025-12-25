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

### Detailed Features

#### 1. Authentication & User Management

**Multiple Sign-In Methods**:
- **Email/Password Authentication**: Traditional login with Firebase Auth
- **Google OAuth**: One-tap sign-in using Android's native Google Sign-In
- **Guest Mode**: "Skip for now" option to browse without authentication

**User Profile Management** (`pages/account.dart`):
- **Inline Editing Mode**: Click edit button to modify profile fields
- **Editable Fields**:
  - Display Name
  - Email address
  - Phone number
  - Bio/description
  - User type (selection popup)
  - Preferences (structured sub-fields)
- **Profile Statistics**: Display login count, account creation date, last login
- **Photo Display**: User profile photo from Firebase/Google account
- **Dark Mode Support**: Proper text colors for both themes

**Password Management**:
- Password visibility toggle (eye icon)
- Forgot password dialog with email reset
- Password strength validation on registration

#### 2. Restaurant Discovery

**Home Page** (`pages/home.dart`):
- **Featured Restaurants Carousel**:
  - Auto-playing carousel with 10 randomly selected restaurants
  - Smooth transitions between slides
  - Tap to view restaurant details
  - Visual indicator showing current slide position
  - Cached images for performance

- **Nearby Restaurants**:
  - GPS-based location detection
  - Calculates 10 closest restaurants using Haversine formula
  - Distance badges with color coding:
    - Green: < 1km (Very Close)
    - Orange: 1-5km (Close)
    - Red: > 5km (Far)
  - Horizontal scrollable list with restaurant cards
  - Automatic location permission request

- **Pull-to-Refresh**: Swipe down to reload all data from API

**Search Page** (`pages/search.dart`):
- **Full-Text Search**:
  - Powered by Algolia search engine
  - Real-time search as you type
  - Searches across restaurant names, addresses, keywords
  - Bilingual search support (English & Traditional Chinese)

- **Infinite Scroll Pagination**:
  - Loads 12 results per page
  - Automatically fetches next page when scrolling to bottom
  - Loading indicators during data fetch
  - "No more results" message at end

- **Advanced Filtering**:
  - **District Filter**: Multi-select from 18 Hong Kong districts
  - **Keyword Filter**: Multi-select dietary preferences
    - Vegan
    - Vegetarian
    - Plant-Based
    - Organic
    - Raw Food
    - And more...
  - Filters work in combination with search query
  - Active filter chips displayed above results

- **Auto-Hiding Search Bar**:
  - Search bar hides when scrolling down (more screen space)
  - Reappears when scrolling up or at top of page
  - Smooth animation transitions

#### 3. Restaurant Details

**Restaurant Detail Page** (`pages/restaurant_detail.dart`):

- **Information Panels** (Responsive Grid Layout):
  - **Basic Info**: Name, address, district, keywords
  - **Contact Information**: Phone, email, website
  - **Opening Hours**: Day-by-day schedule with special hours
  - **Menu Information**: Menu URL or description
  - **Seating Capacity**: Total available seats

- **Google Maps Integration**:
  - Embedded interactive map showing restaurant location
  - Custom marker for restaurant position
  - Map type toggle (Normal, Satellite, Terrain, Hybrid)
  - Zoom controls
  - Pan and zoom gestures
  - Tap to open in Google Maps app for directions

- **Distance Display**:
  - Shows distance from user's current location
  - Format: "1.2km away" or "Distance unavailable"

- **Action Buttons**:
  - **Call**: Opens phone dialer with pre-filled number
  - **Email**: Opens email client with restaurant email
  - **Website**: Opens browser with restaurant website
  - **Directions**: Opens Google Maps with navigation
  - **Share**: Native Android share sheet

- **Share Functionality**:
  - Shares restaurant name and address
  - Bilingual share text (English/Chinese)
  - Native Android share sheet integration
  - Share via WhatsApp, SMS, Email, etc.

- **Booking System**:
  - Date/time picker for reservation
  - Guest count selector (1-20 people)
  - Special requests text field
  - Creates booking record in backend API
  - Schedules local notification reminder

#### 4. Booking Management

**Booking Features**:
- **Create Reservations**: Select date, time, party size
- **Booking Status Tracking**:
  - Pending: Awaiting restaurant confirmation
  - Confirmed: Restaurant accepted booking
  - Completed: Visit finished
  - Cancelled: Booking cancelled

- **Payment Status**:
  - Unpaid: No payment required/made
  - Paid: Payment processed
  - Refunded: Payment returned

- **Local Notifications**:
  - Scheduled reminder 1 hour before booking
  - Notification shows restaurant name, date/time
  - Notification channel: "Booking Reminders"
  - Tapping notification opens app
  - Persistent across app restarts (RECEIVE_BOOT_COMPLETED)

#### 5. Theme System

**Professional Vegan Green Aesthetic**:

**Light Theme**:
- **Primary Color**: Forest Green (#2E7D32)
- **Secondary Color**: Light Green (#66BB6A)
- **Surface Color**: Very Light Green Tint (#F1F8E9)
- **Background**: Pure White
- **Philosophy**: Fresh, bright greens evoking nature and health
- **Accessibility**: All colors pass WCAG contrast standards

**Dark Theme**:
- **Primary Color**: Light Green (#66BB6A)
- **Secondary Color**: Lighter Green (#81C784)
- **Surface Color**: Dark Forest Green (#1B5E20)
- **Background**: Very Dark Green-Black (#0D1F0E)
- **Philosophy**: Deep, rich greens maintaining brand identity
- **Accessibility**: WCAG compliant contrast ratios

**Theme Components**:
- **Material Design 3**: Latest design system with modern aesthetics
- **AppBar**: Themed background and foreground colors
- **Cards**: Rounded corners (12px), elevation 2, themed colors
- **Buttons**: Rounded corners (8px), themed backgrounds
- **Bottom Navigation**: Themed with selection highlighting
- **Persistent**: Theme preference saved to SharedPreferences
- **Toggle**: Switch in navigation drawer

**Dynamic Theming**:
- App logo changes based on theme (App-Light.png / App-Dark.png)
- All UI components respond to theme changes
- Text colors automatically adjust for readability
- Icons and illustrations adapt to theme

#### 6. Internationalization (i18n)

**Bilingual Support**:
- **English**: Default language
- **Traditional Chinese**: Full Hong Kong localization

**Translated Elements**:
- All UI labels and buttons
- Navigation menu items
- Error messages and alerts
- Form placeholders and validation
- Restaurant data (names, addresses, keywords)
- Search results and filters
- Booking confirmations
- Share messages

**Language Switching**:
- Toggle in navigation drawer
- Instant UI update (no restart required)
- Preference saved to SharedPreferences
- Icon indicator: 🇬🇧|🇭🇰 or 英|繁

**Implementation Pattern**:
```dart
final title = isTraditionalChinese ? '主頁' : 'Home';
```

#### 7. Navigation & UI/UX

**Bottom Navigation Bar**:
- **3 Main Sections**:
  - Home (主頁): Featured and nearby restaurants
  - Search (搜尋): Full search and filters
  - Account (帳戶): User profile management
- **Icons**: Material Design icons
- **Themed**: Responds to light/dark mode
- **Badge Support**: Could show notification count

**Navigation Drawer**:
- **Header**: App logo that changes with theme
- **Menu Items**:
  - Home
  - All Restaurants (goes to Search)
  - My Account
  - Login/Register (if not logged in)
  - Logout (if logged in)
- **Settings**:
  - Dark Mode toggle switch
  - Language toggle switch
- **Persistent State**: Drawer state maintained across navigation

**Responsive Design**:
- **Max Width Constraint**: 600px for large screens
- **Grid Layouts**: Adapt to screen size
- **Scrollable Content**: Prevents overflow on small screens
- **Card-Based Design**: Consistent spacing and elevation

**Loading States**:
- **Circular Progress Indicators**: During async operations
- **Skeleton Screens**: Could be added with shimmer package
- **Pull-to-Refresh**: Material Design refresh indicator
- **Infinite Scroll**: Loading indicator at bottom of lists

**Error Handling**:
- **SnackBar Messages**: Bottom sheet for errors/success
- **Retry Mechanisms**: Failed API calls can be retried
- **Offline Support**: Cached images work offline
- **Empty States**: Helpful messages when no data

#### 8. Performance Optimizations

**Image Caching**:
- **CachedNetworkImage**: Automatic image caching
- **Placeholder Images**: Show while loading
- **Error Placeholders**: Fallback for failed loads
- **Memory Efficient**: Automatic cache cleanup

**Data Caching**:
- **Home Page**: Featured/nearby lists cached until refresh
- **Search Results**: Paginated results cached
- **SharedPreferences**: Local storage for settings

**Lazy Loading**:
- **Infinite Scroll**: Load results on demand
- **Pagination**: 12 results per page
- **Efficient Queries**: Only fetch needed data

**Animations**:
- **Smooth Transitions**: 300ms fade animations
- **Carousel Auto-Play**: Smooth slide transitions
- **Search Bar Toggle**: Animated show/hide
- **Page Transitions**: Material Design navigation animations

#### 9. Native Android Integration

**Permissions**:
- **Location**: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- **Internet**: INTERNET
- **Notifications**: POST_NOTIFICATIONS (Android 13+)
- **Alarms**: SCHEDULE_EXACT_ALARM
- **Boot**: RECEIVE_BOOT_COMPLETED

**Native Features**:
- **Google Maps**: Embedded maps with full interaction
- **GPS Location**: Real-time location tracking
- **Phone Dialer**: tel: URI scheme
- **Email Client**: mailto: URI scheme
- **Web Browser**: https: URI scheme
- **Share Sheet**: Native Android sharing
- **Local Notifications**: Background notification scheduling

**Android-Specific Optimizations**:
- **MultiDex**: Support for large app size
- **Desugaring**: Java 8+ APIs on older Android versions
- **Firebase Analytics**: User behavior tracking
- **Google Services**: Integrated via Gradle plugin

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

## Implementation Progress (by Claude)

### ✅ Completed Features (2025-12-24)

#### Priority 1: Review System

Complete implementation of restaurant review functionality with full CRUD operations.

**Models Created:**
- `Review` - Full review data model with rating (1-5 stars), comment, image, user info, timestamps
- `ReviewStats` - Aggregate statistics (total reviews, average rating)
- `CreateReviewRequest` - Request model for creating reviews
- `UpdateReviewRequest` - Request model for updating reviews

**Service Implemented:**
- `lib/services/review_service.dart` (362 lines)
  - `getReviews(restaurantId, userId)` - Fetch reviews with filtering
  - `getReview(reviewId)` - Fetch single review
  - `createReview(request)` - Create new review (auth required)
  - `updateReview(reviewId, request)` - Update own review (auth required)
  - `deleteReview(reviewId)` - Delete own review (auth required)
  - `getReviewStats(restaurantId)` - Fetch aggregate statistics
  - Full error handling and loading states
  - Authentication integration with Firebase tokens

**Widgets Created:**
- `lib/widgets/reviews/star_rating.dart`
  - `StarRating` - Display-only star rating widget (full/half/empty stars)
  - `StarRatingSelector` - Interactive star rating selector with value display
- `lib/widgets/reviews/review_card.dart`
  - Displays user avatar, name, rating, comment, optional image
  - Edit/delete menu for own reviews
  - "Edited" indicator for modified reviews
  - Time ago formatting (e.g., "2 hours ago")
- `lib/widgets/reviews/review_form.dart`
  - Create/edit review form in bottom sheet
  - Star rating selector (1-5 stars)
  - Optional comment field (max 500 chars)
  - Form validation and loading states
- `lib/widgets/reviews/review_stats.dart`
  - `ReviewStatsWidget` - Full statistics display with average rating and count
  - `ReviewStatsBadge` - Compact badge for restaurant cards
- `lib/widgets/reviews/review_list.dart`
  - Pull-to-refresh support
  - Empty state with helpful message
  - Edit/delete handlers for user's own reviews
  - Loading and error states with retry

**Integration:**
- Updated `lib/pages/restaurant_detail.dart`:
  - Added Reviews section with stats widget
  - Created `_ReviewsPage` for full reviews view
  - "Write Review" floating action button
  - Login prompt for unauthenticated users
  - Bilingual support (EN/TC) throughout
- Registered `ReviewService` as provider in `lib/main.dart`
- Added `timeago: ^3.7.0` dependency to `pubspec.yaml`

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- All endpoints require `x-api-passcode: PourRice` header
- Auth endpoints require `Authorization: Bearer <token>` header
- Follows API.md specification exactly

**Features:**
- Star rating system (1-5 stars, half stars for display)
- Optional comment (up to 500 characters)
- User can only edit/delete own reviews
- Real-time updates after create/edit/delete
- Automatic stats refresh
- Time ago formatting for review dates
- Bilingual UI (English/Traditional Chinese)
- Material Design 3 components
- Smooth animations and transitions

**Files Modified:**
- `lib/models.dart` - Updated Review models (replaced old simple model)
- `lib/main.dart` - Added ReviewService provider
- `lib/pages/restaurant_detail.dart` - Integrated reviews section
- `pubspec.yaml` - Added timeago dependency

**Files Created:**
- `lib/services/review_service.dart`
- `lib/widgets/reviews/star_rating.dart`
- `lib/widgets/reviews/review_card.dart`
- `lib/widgets/reviews/review_form.dart`
- `lib/widgets/reviews/review_stats.dart`
- `lib/widgets/reviews/review_list.dart`

**Total Lines Added:** ~850 lines of production code

---

#### Priority 2: Menu System

Complete implementation of restaurant menu management with full CRUD operations.

**Models Created:**
- `MenuItem` - Full menu item data model with bilingual names, descriptions, price, category, availability, image, timestamps
- `Booking` - Booking model for table reservations (supporting future booking system)
- `CreateMenuItemRequest` - Request model for creating menu items
- `UpdateMenuItemRequest` - Request model for updating menu items

**Service Implemented:**
- `lib/services/menu_service.dart` (320 lines)
  - `getMenuItems(restaurantId)` - Fetch all menu items for a restaurant
  - `getMenuItem(restaurantId, menuItemId)` - Fetch single menu item
  - `createMenuItem(restaurantId, request)` - Create new menu item (auth required)
  - `updateMenuItem(restaurantId, menuItemId, request)` - Update menu item (auth required)
  - `deleteMenuItem(restaurantId, menuItemId)` - Delete menu item (auth required)
  - `getMenuItemsByCategory()` - Group menu items by category
  - Full error handling and loading states
  - Authentication integration with Firebase tokens

**Widgets Created:**
- `lib/widgets/menu/menu_item_card.dart`
  - Displays menu item image, name, description, price, availability
  - Shows "Sold Out" badge for unavailable items
  - Edit/delete buttons for restaurant owners
  - Responsive card layout with image thumbnail
- `lib/widgets/menu/menu_list.dart`
  - Groups menu items by category with headers
  - Pull-to-refresh support
  - Empty state with helpful message
  - Loading and error states with retry
  - Optional edit/delete actions for owners
- `lib/widgets/menu/menu_item_form.dart`
  - Create/edit menu item form in bottom sheet
  - Bilingual input fields (English/Traditional Chinese)
  - Price input with validation
  - Category autocomplete with common categories
  - Availability toggle
  - Form validation and loading states

**Integration:**
- Updated `lib/pages/restaurant_detail.dart`:
  - Added Menu section with preview (first 3 items)
  - Created `_MenuPage` for full menu view
  - "View All" button to navigate to full menu
  - Owner-only "Add Item" floating action button
  - Edit/delete confirmation dialogs
  - Bilingual support (EN/TC) throughout
- Registered `MenuService` as provider in `lib/main.dart`

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- Endpoints: `/API/Restaurants/:restaurantId/menu`
- All endpoints require `x-api-passcode: PourRice` header
- Auth endpoints require `Authorization: Bearer <token>` header
- Menu items stored as sub-collections in Firestore
- Follows API.md specification exactly

**Features:**
- Bilingual menu item names and descriptions (EN/TC)
- Price display with HK$ currency format
- Category organization with autocomplete
- Availability toggle (available/sold out)
- Menu items grouped by category
- Real-time updates after create/edit/delete
- Owner-only edit/delete permissions (TODO: implement user type check)
- Responsive card layout with images
- Material Design 3 components
- Smooth animations and transitions

**Files Modified:**
- `lib/models.dart` - Added MenuItem, Booking, CreateMenuItemRequest, UpdateMenuItemRequest models
- `lib/main.dart` - Added MenuService provider
- `lib/pages/restaurant_detail.dart` - Integrated menu section and _MenuPage

**Files Created:**
- `lib/services/menu_service.dart`
- `lib/widgets/menu/menu_item_card.dart`
- `lib/widgets/menu/menu_list.dart`
- `lib/widgets/menu/menu_item_form.dart`

**Total Lines Added:** ~900 lines of production code

---

#### Priority 3: Image Upload System

Complete implementation of image upload functionality with Android camera/gallery integration and Firebase Storage.

**Models Created:**
- `ImageMetadata` - Full image metadata model with size, content type, timestamps, download URL

**Service Implemented:**
- `lib/services/image_service.dart` (400+ lines)
  - `pickImage(source)` - Pick image from camera or gallery with permission handling
  - `cropImage(imageFile)` - Crop images with Android UI
  - `compressImage(imageFile, quality)` - Compress images before upload
  - `uploadImage(imageFile, folder)` - Upload to Firebase Storage via API
  - `deleteImage(filePath)` - Delete images from Firebase Storage
  - `getImageMetadata(filePath)` - Fetch image metadata
  - `showImageSourceDialog(context)` - Bottom sheet for camera/gallery selection
  - Full error handling and loading states
  - Authentication integration with Firebase tokens
  - Permission handling for camera and storage (Android 13+ support)

**Widgets Created:**
- `lib/widgets/images/image_picker_button.dart`
  - `ImagePickerButton` - Full button with camera/gallery selection
  - `ImagePickerIconButton` - Compact icon button version
  - Bottom sheet UI for source selection
  - Optional crop after selection
  - Bilingual support (EN/TC)
- `lib/widgets/images/image_preview.dart`
  - `ImagePreview` - Generic image preview (File or URL)
  - `SquareImagePreview` - Square preview for profiles/thumbnails
  - `CircularImagePreview` - Circular preview for avatars
  - `WideImagePreview` - Wide preview for banners (16:9 aspect ratio)
  - `ImageGridPreview` - Grid layout for multiple images
  - Remove button support
  - Loading and error placeholders
- `lib/widgets/images/upload_progress_indicator.dart`
  - `UploadProgressIndicator` - Linear progress with percentage
  - `CircularUploadProgress` - Circular progress indicator
  - `InlineUploadProgress` - Compact inline progress
  - `UploadOverlay` - Full-screen overlay during upload
  - `UploadProgressWithError` - Progress with error display

**Integration:**
- Updated `lib/widgets/reviews/review_form.dart`:
  - Added image upload capability to review form
  - Image picker button with crop option
  - Image preview with remove button
  - Upload progress indicator
  - Updated `CreateReviewRequest` to include `imageUrl`
  - Bilingual support throughout
- Updated `lib/widgets/menu/menu_item_form.dart`:
  - Added image upload capability to menu item form
  - Wide image preview for menu items (16:9 aspect ratio)
  - Upload to `Menu/{restaurantId}` folder
  - Updated `CreateMenuItemRequest` and `UpdateMenuItemRequest` to include `image`
  - Bilingual support throughout
- Updated `lib/pages/restaurant_detail.dart`:
  - Modified review submission to handle image URL
  - Pass language preference to review form
- Updated `lib/widgets/reviews/review_list.dart`:
  - Modified review edit to handle image URL
  - Pass language preference to review form
- Registered `ImageService` as provider in `lib/main.dart`
- Updated `pubspec.yaml` with image upload dependencies
- Updated `android/app/src/main/AndroidManifest.xml` with camera and storage permissions

**Dependencies Added:**
- `image_picker: ^1.0.7` - Camera/gallery access
- `image_cropper: ^5.0.1` - Image cropping with Android UI
- `flutter_image_compress: ^2.1.0` - Image compression
- `path: ^1.9.0` - File path manipulation
- `http_parser: ^4.0.2` - Multipart response parsing
- `mime: ^1.0.5` - MIME type detection

**Android Permissions Added:**
- `CAMERA` - Camera access for taking photos
- `READ_EXTERNAL_STORAGE` - Read images from storage (Android 12 and below)
- `WRITE_EXTERNAL_STORAGE` - Write images to storage (Android 12 and below)
- `READ_MEDIA_IMAGES` - Read images on Android 13+

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- Endpoints:
  - `POST /API/Images/upload?folder=X` - Upload image (multipart/form-data)
  - `DELETE /API/Images/delete` - Delete image by filePath
  - `GET /API/Images/metadata?filePath=X` - Get image metadata
- All endpoints require `x-api-passcode: PourRice` header
- Auth endpoints require `Authorization: Bearer <token>` header
- Follows API.md specification exactly

**Folder Organization:**
- `Menu/{restaurantId}` - Menu item images
- `Restaurants/{restaurantId}` - Restaurant images
- `Profiles` - User profile pictures
- `Reviews` - Review images
- `Chat` - Chat attachments
- `Banners` - Promotional content
- `General` - Default folder

**Features:**
- Camera and gallery access with runtime permission requests
- Image cropping with Android native UI
- Automatic image compression before upload
- Upload progress tracking with percentage
- Multiple image preview styles (square, circular, wide, grid)
- Remove image functionality
- Error handling with user-friendly messages
- Loading states for all async operations
- Bilingual support (EN/TC) throughout
- Material Design 3 components
- Android 13+ permission support

**Files Modified:**
- `pubspec.yaml` - Added image upload dependencies
- `lib/models.dart` - Added ImageMetadata model
- `lib/main.dart` - Added ImageService provider
- `lib/widgets/reviews/review_form.dart` - Integrated image upload
- `lib/widgets/menu/menu_item_form.dart` - Integrated image upload
- `lib/pages/restaurant_detail.dart` - Updated review submission
- `lib/widgets/reviews/review_list.dart` - Updated review edit
- `android/app/src/main/AndroidManifest.xml` - Added permissions

**Files Created:**
- `lib/services/image_service.dart`
- `lib/widgets/images/image_picker_button.dart`
- `lib/widgets/images/image_preview.dart`
- `lib/widgets/images/upload_progress_indicator.dart`

**Total Lines Added:** ~1,200 lines of production code

---

#### Priority 4: Real-time Chat System

Complete implementation of real-time chat functionality with Socket.IO integration and REST API message persistence.

**Models Created:**
- `ChatRoom` - Full chat room model with participants, room name, type (direct/group), last message, timestamps
- `ChatMessage` - Message model with sender info, content, timestamp, edited/deleted flags, optional image
- `TypingIndicator` - Typing indicator model for real-time typing status

**Service Implemented:**
- `lib/services/chat_service.dart` (~600 lines)
  - **Socket.IO Integration**:
    - `connect(userId)` - Connect to Socket.IO server on Railway
    - `disconnect()` - Disconnect from server
    - Real-time event listeners (message_received, typing, user_online/offline)
  - **Room Operations**:
    - `getChatRooms()` - Fetch all chat rooms for current user
    - `getChatRoom(roomId)` - Fetch single room details
    - `createChatRoom(participants, roomName, type)` - Create new room
    - `joinRoom(roomId)` - Join room via Socket.IO
    - `leaveRoom(roomId)` - Leave room via Socket.IO
  - **Message Operations**:
    - `getMessages(roomId, limit)` - Fetch message history
    - `sendMessage(roomId, message, imageUrl)` - Send via Socket.IO + save to API
    - `editMessage(roomId, messageId, newMessage)` - Edit own messages
    - `deleteMessage(roomId, messageId)` - Delete own messages
    - `sendTypingIndicator(roomId, isTyping)` - Real-time typing status
  - **Real-time Streams**:
    - `messageStream` - Stream for incoming messages
    - `typingStream` - Stream for typing indicators
    - `connectionStatusStream` - Stream for connection status
  - Full error handling and loading states
  - Message caching for performance
  - Authentication integration with Firebase tokens

**Widgets Created:**
- `lib/widgets/chat/chat_bubble.dart`
  - Displays single message with user avatar, content, timestamp
  - Shows image attachments with cached loading
  - Edit/delete menu for own messages (long press)
  - Edited indicator for modified messages
  - Deleted message placeholder
  - Time ago formatting with timeago package
  - Bilingual support (EN/TC)

- `lib/widgets/chat/chat_input.dart`
  - Message text input with multi-line support
  - Send button with loading state
  - Optional image attachment picker
  - Typing indicator emission
  - Image preview with remove button
  - Image upload before send
  - Character limit support (optional)

- `lib/widgets/chat/typing_indicator.dart`
  - Animated typing dots
  - User avatar and name
  - Smooth fade animation
  - Bilingual "typing..." text

- `lib/widgets/chat/chat_room_list.dart`
  - List of chat rooms with pull-to-refresh
  - Room avatar (user initial or group icon)
  - Room name and participant count
  - Last message preview
  - Time ago formatting
  - Empty state with helpful message
  - Loading and error states

**Pages Created:**
- `lib/pages/chat_page.dart`
  - Full chat interface with message list
  - Real-time message updates via Socket.IO
  - Auto-scroll to bottom on new messages
  - Typing indicators from other users
  - Edit/delete message dialogs
  - Join/leave room on mount/unmount
  - Image attachment support
  - Connection status in app bar
  - Empty state for no messages

- `lib/pages/chat_rooms_page.dart`
  - List of all chat rooms for current user
  - Connection status indicator
  - Auto-connect to Socket.IO on mount
  - Navigation to individual chats
  - Login prompt for unauthenticated users
  - Pull-to-refresh support

**Integration:**
- Updated `lib/pages/restaurant_detail.dart`:
  - Added chat button in AppBar
  - Implemented `_startChatWithRestaurant()` method
  - Creates/opens direct chat with restaurant
  - Checks authentication before opening chat
  - Auto-connects to Socket.IO if needed
  - Navigates to ChatPage on success
  - Bilingual support throughout

- Updated `lib/config.dart`:
  - Added `socketIOUrl` constant for Railway server
  - Value: `https://railway-socket-production.up.railway.app`

- Registered `ChatService` as provider in `lib/main.dart`:
  - Added as `ChangeNotifierProxyProvider<AuthService, ChatService>`
  - Depends on AuthService for authentication

- Added `socket_io_client: ^3.1.3` dependency to `pubspec.yaml`

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- Socket.IO URL: `https://railway-socket-production.up.railway.app`
- **REST Endpoints**:
  - `GET /API/Chat/Rooms` - List chat rooms (requires auth)
  - `GET /API/Chat/Rooms/:roomId` - Get room details (requires auth)
  - `POST /API/Chat/Rooms` - Create chat room (requires auth)
  - `GET /API/Chat/Rooms/:roomId/Messages?limit=50` - Get messages (requires auth)
  - `POST /API/Chat/Rooms/:roomId/Messages` - Save message (requires auth)
  - `PUT /API/Chat/Rooms/:roomId/Messages/:messageId` - Edit message (requires auth)
  - `DELETE /API/Chat/Rooms/:roomId/Messages/:messageId` - Delete message (requires auth)
- **Socket.IO Events**:
  - `connection` - Connect to server
  - `join_room` - Join a chat room
  - `send_message` - Send message in real-time
  - `message_received` - Receive message in real-time
  - `typing` - Typing indicator
  - `user_online` / `user_offline` - Online status
- All endpoints require `x-api-passcode: PourRice` header
- Auth endpoints require `Authorization: Bearer <token>` header
- Follows API.md specification exactly

**Features:**
- Real-time messaging with Socket.IO WebSocket connection
- Message persistence via REST API
- Direct and group chat support
- Typing indicators with auto-timeout
- Online/offline status tracking
- Message editing with edited indicator
- Message deletion with confirmation
- Image attachments in messages
- Message caching for performance
- Auto-scroll to bottom on new messages
- Time ago formatting for messages and rooms
- Connection status indicator
- Pull-to-refresh for room list
- Login/authentication integration
- Error handling with user-friendly messages
- Loading states for all async operations
- Empty states with helpful messages
- Bilingual support (EN/TC) throughout
- Material Design 3 components
- Smooth animations and transitions

**Files Modified:**
- `pubspec.yaml` - Added socket_io_client dependency
- `lib/models.dart` - Added ChatRoom, ChatMessage, TypingIndicator models
- `lib/config.dart` - Added socketIOUrl constant
- `lib/main.dart` - Added ChatService provider
- `lib/pages/restaurant_detail.dart` - Integrated chat button and functionality

**Files Created:**
- `lib/services/chat_service.dart`
- `lib/widgets/chat/chat_bubble.dart`
- `lib/widgets/chat/chat_input.dart`
- `lib/widgets/chat/typing_indicator.dart`
- `lib/widgets/chat/chat_room_list.dart`
- `lib/pages/chat_page.dart`
- `lib/pages/chat_rooms_page.dart`

**Total Lines Added:** ~1,500 lines of production code

---

#### Priority 5: AI Assistant (Google Gemini)

Complete implementation of AI-powered assistant using Google Gemini 2.5 for restaurant recommendations, Q&A, and dining suggestions.

**Models Created:**
- `GeminiChatHistory` - Chat history item for conversation tracking (role, content)
- `GeminiGenerateRequest` - Request model for text generation with configurable parameters (prompt, model, temperature, maxTokens, topP, topK)
- `GeminiGenerateResponse` - Response model with result and token usage statistics
- `GeminiChatRequest` - Request model for conversational chat with history
- `GeminiChatResponse` - Response model with result and updated conversation history
- `GeminiRestaurantDescriptionRequest` - Request model for AI-generated restaurant descriptions
- `GeminiRestaurantDescriptionResponse` - Response model with generated description and restaurant data

**Service Implemented:**
- `lib/services/gemini_service.dart` (~300 lines)
  - **Core Methods**:
    - `generate(prompt, {model, temperature, maxTokens, topP, topK})` - Generate text from prompt
    - `chat(message, {history, model, useInternalHistory})` - Conversational chat with maintained history
    - `generateRestaurantDescription({name, cuisine, district, keywords, language})` - AI-generated restaurant marketing copy
  - **Helper Methods**:
    - `askAboutRestaurant(question, restaurantName, {cuisine, district})` - Context-aware restaurant Q&A
    - `getDiningRecommendation(preferences)` - Personalized dining suggestions
    - `suggestRestaurants({district, cuisine, dietaryPreference, priceRange})` - Restaurant recommendations
  - **State Management**:
    - `conversationHistory` - Maintained conversation state
    - `clearHistory()` - Reset conversation
    - `addToHistory(role, content)` - Manual history management
  - Full error handling and loading states
  - No authentication required (public endpoints)

**Widgets Created:**
- `lib/widgets/ai/gemini_chat_button.dart`
  - `GeminiChatButton` - Animated floating action button with gradient icon
  - `GeminiChatIconButton` - Compact icon button for toolbars
  - Pulsing scale animation for attention
  - Restaurant context support
  - Bilingual labels (EN/TC)

- `lib/widgets/ai/suggestion_chips.dart`
  - `SuggestionChips` - Horizontal scrollable list of suggested questions
  - `CompactSuggestionChips` - Compact version with send action
  - Context-aware suggestions (restaurant-specific or general)
  - Different suggestion sets for different contexts
  - Bilingual question templates

**Pages Created:**
- `lib/pages/gemini_chat_page.dart` (~400 lines)
  - Full-screen conversational AI interface
  - Message list with user/AI distinction
  - Bubble-style chat UI with gradient AI avatar
  - Suggestion chips for quick interaction
  - Real-time message input with send button
  - Loading states during AI processing
  - Clear conversation functionality
  - Restaurant context awareness
  - Welcome message on page load
  - Auto-scroll to bottom on new messages
  - Bilingual support throughout

**Integration:**
- Updated `lib/pages/restaurant_detail.dart`:
  - Added `GeminiChatIconButton` to AppBar actions
  - Passes restaurant context (name, cuisine, district)
  - Positioned before chat and share buttons
  - Bilingual support

- Registered `GeminiService` as provider in `lib/main.dart`:
  - Added as `ChangeNotifierProvider` (no auth dependency)
  - Independent service for AI features

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- **Endpoints**:
  - `POST /API/Gemini/generate` - Generate text content
  - `POST /API/Gemini/chat` - Conversational chat with history
  - `POST /API/Gemini/restaurant-description` - Generate restaurant descriptions
- All endpoints require `x-api-passcode: PourRice` header
- No authentication required (public AI features)
- Default model: `gemini-2.5-flash-lite-preview-09-2025`
- Follows API.md specification exactly

**Features:**
- AI-powered text generation with configurable parameters
- Conversational chat with maintained context/history
- Restaurant-specific Q&A with context awareness
- General vegetarian/vegan dining recommendations
- Suggested questions for quick interaction
- Restaurant description generation
- Dining suggestion based on preferences
- Multi-turn conversations with history
- Gradient UI design for AI branding
- Animated floating button for engagement
- Context-aware responses (general or restaurant-specific)
- Token usage tracking
- Error handling with user-friendly messages
- Loading states for all async operations
- Empty states with helpful prompts
- Bilingual support (EN/TC) throughout
- Material Design 3 components
- Smooth animations and transitions

**Use Cases:**
1. **Restaurant Discovery**: "Recommend vegan restaurants in Central"
2. **Menu Inquiries**: "What are the signature dishes at this restaurant?"
3. **Dietary Advice**: "What plant-based protein options are available?"
4. **Operating Info**: "What are the opening hours?"
5. **Price Guidance**: "What is the price range here?"
6. **Occasion Planning**: "Is this suitable for a business lunch?"
7. **General Recommendations**: Ask about any aspect of vegetarian/vegan dining

**Files Modified:**
- `lib/models.dart` - Added Gemini AI models (GeminiChatHistory, requests, responses)
- `lib/main.dart` - Added GeminiService provider
- `lib/pages/restaurant_detail.dart` - Integrated AI chat button

**Files Created:**
- `lib/services/gemini_service.dart`
- `lib/widgets/ai/gemini_chat_button.dart`
- `lib/widgets/ai/suggestion_chips.dart`
- `lib/pages/gemini_chat_page.dart`

**Total Lines Added:** ~1,000 lines of production code

---

#### Priority 7: Enhanced Restaurant Detail Page

Complete enhancement of the restaurant detail page with improved visual hierarchy, modular widget structure, and better user experience.

**New Widgets Created:**
- `lib/widgets/restaurant_detail/hero_image_section.dart`
  - Large hero image (300px height) with gradient overlay
  - Distance badge overlay with white background and shadow
  - Smooth loading with placeholder
  - Error handling with fallback icon
  - Gradient overlay for better text contrast

- `lib/widgets/restaurant_detail/restaurant_info_card.dart`
  - Elegant card layout with restaurant name and rating
  - Tap-to-navigate address with underline decoration
  - District and seating capacity display
  - Keyword chips with themed colors
  - Integration with review stats badge
  - 16px border radius for modern look

- `lib/widgets/restaurant_detail/contact_actions.dart`
  - Icon-based action buttons (Phone, Email, Website)
  - Color-coded buttons (Green for phone, Blue for email, Orange for website)
  - Responsive row layout with equal width buttons
  - Only shows available contact methods
  - Bilingual labels

- `lib/widgets/restaurant_detail/opening_hours_card.dart`
  - Weekly schedule display with current day highlighting
  - "Open Now" / "Closed" status indicator with color coding
  - Time parsing for various formats (12h/24h, AM/PM)
  - Current day highlighted with primary container color
  - Day-by-day hours with proper formatting
  - Bilingual day names and labels

**Page Refactoring:**
- Updated `lib/pages/restaurant_detail.dart`:
  - Reduced file complexity by extracting widgets to separate files
  - Improved visual hierarchy with proper spacing
  - Hero image section at top (300px height with overlay)
  - Restaurant info card with rating integration
  - Contact action buttons in horizontal row
  - Opening hours card with current status
  - Google Maps section with improved padding
  - Menu section with preview (first 3 items)
  - Reviews section with stats and "View All" button
  - Removed unused imports and cleaned up code
  - Fixed bracket indentation issues
  - All sections properly padded (16px horizontal)

**Features:**
- Enhanced visual design with card-based layout
- Better information hierarchy
- Improved spacing and padding consistency
- Real-time "Open Now" status calculation
- Distance badge on hero image
- Review stats integrated into info card
- Modular widget architecture for easier maintenance
- Responsive design with max-width constraints
- Smooth loading states and error handling
- Bilingual support throughout (EN/TC)
- Material Design 3 components
- Proper theme awareness (light/dark modes)

**Files Modified:**
- `lib/pages/restaurant_detail.dart` - Refactored with new widgets

**Files Created:**
- `lib/widgets/restaurant_detail/hero_image_section.dart`
- `lib/widgets/restaurant_detail/restaurant_info_card.dart`
- `lib/widgets/restaurant_detail/contact_actions.dart`
- `lib/widgets/restaurant_detail/opening_hours_card.dart`

**Total Lines Added:** ~600 lines of production code

---

#### Priority 8: Restaurant Owner Dashboard

Complete implementation of restaurant owner management system with claim functionality and store dashboard.

**Models:** (No new models - uses existing Restaurant, MenuItem, Booking)

**Service Implemented:**
- `lib/services/store_service.dart` (~280 lines)
  - **Restaurant Ownership**:
    - `claimRestaurant(restaurantId)` - Claim ownership of a restaurant
    - `getOwnedRestaurant()` - Fetch restaurant owned by current user
    - `clearOwnedRestaurant()` - Clear cached data
  - **Restaurant Management**:
    - `updateRestaurant(restaurantId, updates)` - Update restaurant details
    - `uploadRestaurantImage(restaurantId, imagePath)` - Upload restaurant image
  - **State Properties**:
    - `ownedRestaurant` - Currently owned restaurant
    - `isLoading` - Loading state
    - `error` - Error messages
    - `hasOwnedRestaurant` - Convenience getter
  - Full error handling and loading states
  - Authentication integration with Firebase tokens
  - Multipart image upload support

**Page Created:**
- `lib/pages/store_dashboard_page.dart` (~400 lines)
  - **Dashboard Overview**:
    - Restaurant header card with name, address, and seating
    - Quick actions grid (2x2 layout)
    - Statistics cards showing menu item count and bookings
    - Pull-to-refresh functionality
  - **Quick Actions**:
    - Manage Menu - Navigate to menu management (placeholder)
    - Bookings - View and manage reservations (placeholder)
    - Reviews - View customer reviews (placeholder)
    - Settings - Update restaurant info (placeholder)
  - **Statistics Section**:
    - Menu items count (live data from MenuService)
    - Today's bookings count (placeholder for future implementation)
    - Color-coded stat cards (Orange for menu, Blue for bookings)
  - **Auth States**:
    - Not logged in - Shows login prompt
    - No owned restaurant - Shows claim prompt
    - Loading - Shows circular progress indicator
    - Has restaurant - Shows full dashboard
  - Bilingual support (EN/TC) throughout

**Integration:**
- Registered `StoreService` as provider in `lib/main.dart`:
  - Added as `ChangeNotifierProxyProvider<AuthService, StoreService>`
  - Depends on AuthService for authentication
  - Available to all widgets in the app
- Added import for `store_service.dart` in main.dart

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- **Endpoints**:
  - `POST /API/Restaurants/:id/claim` - Claim restaurant ownership (requires auth)
  - `GET /API/Users/:uid` - Get user profile with restaurantId field
  - `GET /API/Restaurants/:id` - Get restaurant details
  - `PUT /API/Restaurants/:id` - Update restaurant (requires auth + ownership)
  - `POST /API/Restaurants/:id/image` - Upload restaurant image (multipart, requires auth)
- All endpoints require `x-api-passcode: PourRice` header
- Auth endpoints require `Authorization: Bearer <token>` header
- Follows API.md specification exactly

**Features:**
- Restaurant ownership claim system
- Store dashboard with overview and stats
- Quick action grid for common tasks
- Real-time statistics from MenuService
- Pull-to-refresh support
- Auth state handling (not logged in, no restaurant, has restaurant)
- Image upload for restaurant photos
- Restaurant information updates
- Error handling with user-friendly messages
- Loading states for all async operations
- Bilingual support (EN/TC) throughout
- Material Design 3 components
- Responsive card-based layout
- Smooth animations and transitions

**Future Enhancements:**
- Full menu management page
- Bookings management page with status updates
- Reviews management with owner responses
- Restaurant settings page with all editable fields
- Analytics and insights dashboard
- Multi-restaurant support for chains
- Staff management for larger establishments

**Files Modified:**
- `lib/main.dart` - Added StoreService provider

**Files Created:**
- `lib/services/store_service.dart`
- `lib/pages/store_dashboard_page.dart`

**Total Lines Added:** ~680 lines of production code

---

### ✅ Completed Features (2025-12-25)

#### Priority 9: Advanced Search Features

Complete implementation of enhanced search functionality with advanced filtering, faceted search, and geo-location search.

**Models Created:**
- `SearchResponse` - Enhanced search response with pagination metadata (hits, nbHits, page, nbPages, hitsPerPage, processingTimeMS)
- `FacetValue` - Facet value with count for filtering (value, count)
- `AdvancedSearchRequest` - Advanced search request with all filter options (query, districts, keywords, page, hitsPerPage, aroundLatLng, aroundRadius, custom filters)

**Service Enhanced:**
- Updated `lib/services/restaurant_service.dart` (~400 lines total, +140 lines added)
  - `advancedSearch(request)` - Advanced search with full SearchResponse metadata
  - `getFacetValues(facetName, query)` - Get facet values for filtering (District_EN, District_TC, Keyword_EN, Keyword_TC)
  - `searchNearby(latitude, longitude, radiusMeters, ...)` - Geo-location search with radius
  - `getNearbyRestaurants(latitude, longitude, radiusMeters, limit)` - Quick nearby search
  - Full support for combining query, district, keyword, and geo filters
  - Processing time tracking for performance monitoring

**API Integration:**
- Base URL: `https://vercel-express-api-alpha.vercel.app`
- **Endpoints**:
  - `GET /API/Algolia/Restaurants` - Basic search with query parameters
  - `GET /API/Algolia/Restaurants/facets/:facetName` - Get facet values
  - `POST /API/Algolia/Restaurants/advanced` - Advanced search with custom filters (future)
- **Query Parameters**:
  - `query` - Full-text search (searches both EN and TC)
  - `districts` - Comma-separated districts
  - `keywords` - Comma-separated keywords
  - `page` - Page number (default: 0)
  - `hitsPerPage` - Results per page (default: 20, max: 100)
  - `aroundLatLng` - Geo coordinates in "lat,lng" format
  - `aroundRadius` - Radius in meters
- All endpoints require `x-api-passcode: PourRice` header
- Follows API.md specification exactly

**Features:**
- Advanced search with multiple filter combinations
- Faceted search for discovering filter options
- Geo-location search within radius
- Pagination with metadata (hasNextPage, hasPreviousPage, isEmpty)
- Processing time tracking
- Combined text + filter + geo search
- Real-time state updates with ChangeNotifier
- Error handling with user-friendly messages
- Loading states for all async operations
- Bilingual support (EN/TC) throughout

**Files Modified:**
- `lib/models.dart` - Added SearchResponse, FacetValue, AdvancedSearchRequest models
- `lib/services/restaurant_service.dart` - Added advanced search methods

**Total Lines Added:** ~350 lines of production code

---

#### Priority 10: Constants System

Complete implementation of constants system for standardized data across the application.

**Constants Created:**
- `lib/constants/districts.dart` (~95 lines)
  - `DistrictOption` - Bilingual district data model
  - `HKDistricts` - All 18 Hong Kong districts with EN/TC names
  - `findByEn(name)` - Find district by English name (case-insensitive)
  - `findByTc(name)` - Find district by Traditional Chinese name
  - `getAllEnglish()` - Get all district names in English
  - `getAllChinese()` - Get all district names in Traditional Chinese
  - `getAllNames(isTC)` - Get district names based on language preference

- `lib/constants/keywords.dart` (~185 lines)
  - `KeywordOption` - Bilingual keyword data model with category
  - `KeywordCategory` - Enum for dietary, cuisine, feature categories
  - `RestaurantKeywords` - 50+ keywords organized by category
    - Dietary: Vegan, Vegetarian, Plant-Based, Gluten-Free, Halal, Kosher, etc.
    - Cuisine: Chinese, Japanese, Korean, Thai, Italian, Mexican, etc.
    - Feature: Organic, Sustainable, Farm-to-Table, Pet-Friendly, etc.
  - `findByEn(name)` - Find keyword by English name (case-insensitive)
  - `findByTc(name)` - Find keyword by Traditional Chinese name
  - `getByCategory(category)` - Get keywords filtered by category
  - `getAllEnglish()`, `getAllChinese()`, `getAllNames(isTC)` - Get all keyword names
  - `getDietaryNames(isTC)`, `getCuisineNames(isTC)`, `getFeatureNames(isTC)` - Get category-specific names

- `lib/constants/payments.dart` (~105 lines)
  - `PaymentOption` - Bilingual payment method data model with icon
  - `PaymentMethods` - 10 payment methods (Cash, Credit Card, Octopus, AlipayHK, WeChat Pay, PayMe, FPS, Apple Pay, Google Pay)
  - `findByEn(name)` - Find payment method by English name
  - `findByTc(name)` - Find payment method by Traditional Chinese name
  - `getAllEnglish()`, `getAllChinese()`, `getAllNames(isTC)` - Get all payment method names

- `lib/constants/weekdays.dart` (~140 lines)
  - `Weekdays` - Weekday names in multiple formats
    - `enShort` - Short English names (Mon, Tue, Wed, ...)
    - `enFull` - Full English names (Monday, Tuesday, ...)
    - `tc` - Traditional Chinese names (星期一, 星期二, ...)
    - `tcShort` - Short Traditional Chinese names (週一, 週二, ...)
  - `getName(index, isTC, useShortForm)` - Get weekday name by index (0 = Monday, 6 = Sunday)
  - `getAll(isTC, useShortForm)` - Get all weekday names
  - `dateTimeToIndex(dateTimeWeekday)` - Convert DateTime.weekday to index
  - `indexToDateTime(index)` - Convert index to DateTime.weekday
  - `today(isTC, useShortForm)` - Get current weekday name
  - `isWeekend(index)` - Check if index is weekend
  - `indexFromEnglish(name)`, `indexFromChinese(name)` - Get index from name

**Features:**
- Centralized constants for consistent data
- Bilingual support (EN/TC) for all constants
- Helper methods for finding, filtering, and converting
- Category-based organization for keywords
- Icon support for payment methods
- Weekday utilities for calendar operations
- Case-insensitive search for English names
- Null-safe operations with proper error handling

**Files Created:**
- `lib/constants/districts.dart`
- `lib/constants/keywords.dart`
- `lib/constants/payments.dart`
- `lib/constants/weekdays.dart`

**Total Lines Added:** ~525 lines of production code

---

#### Priority 11: Swiper/Carousel System

Complete implementation of carousel system with Android-optimized touch gestures and Material Design components.

**Dependency Added:**
- `smooth_page_indicator: ^1.1.0` - Material Design page indicators

**Widgets Created:**
- `lib/widgets/carousel/hero_carousel.dart` (~210 lines)
  - `HeroCarouselItem` - Data model for hero carousel items (imageUrl, title, subtitle, onTap)
  - `HeroCarousel` - Full-width hero image carousel
    - Auto-play with configurable interval
    - Smooth page indicators with worm effect
    - Gradient overlay for better text readability
    - Customizable height and padding
    - Touch gesture support with carousel_slider
    - Loading and error placeholders
    - Title and subtitle with shadow for visibility

- `lib/widgets/carousel/restaurant_carousel.dart` (~190 lines)
  - `RestaurantCarousel` - Horizontal scrolling restaurant cards
    - Enlarge center page effect
    - Section title header
    - Restaurant name, district, keywords display
    - Gradient overlay on images
    - Tap to view restaurant details
    - Bilingual support (EN/TC)
    - Cached network images
    - Responsive card sizing (85% viewport)

- `lib/widgets/carousel/offer_carousel.dart` (~250 lines)
  - `OfferItem` - Data model for promotional offers (imageUrl, title, subtitle, description, backgroundColor, onTap)
  - `OfferCarousel` - Promotional offers carousel
    - Auto-play with smooth transitions
    - Page indicators with worm effect
    - Gradient overlay for text readability
    - "View" badge for tappable items
    - Custom background colors
    - Card elevation and rounded corners
    - Title, subtitle, and description support

- `lib/widgets/carousel/menu_carousel.dart` (~200 lines)
  - `MenuCarousel` - Menu item images carousel
    - Enlarge center page effect (20% enlargement)
    - Price display with HK$ format
    - Availability badges (Sold Out)
    - Category tags
    - Bilingual support (EN/TC)
    - Swipe navigation with page indicators
    - Gradient overlay on images
    - Tap to view menu item details

**Features:**
- Android-optimized touch gestures (swipe, tap, drag)
- Material Design 3 components and theming
- Smooth animations with carousel_slider
- Auto-play support with configurable intervals
- Page indicators with worm effect animation
- Gradient overlays for better text contrast
- Cached network images for performance
- Loading and error states
- Bilingual support (EN/TC) throughout
- Customizable heights, padding, and margins
- Enlarge center page effect for focus
- Responsive viewport sizing
- Card-based design with elevation and shadows
- Theme-aware colors and typography

**Use Cases:**
1. **HeroCarousel**: Featured content, banners, promotional images
2. **RestaurantCarousel**: Restaurant discovery, featured restaurants, nearby restaurants
3. **OfferCarousel**: Special offers, deals, announcements
4. **MenuCarousel**: Menu item showcase, dish galleries, food photography

**Files Modified:**
- `pubspec.yaml` - Added smooth_page_indicator dependency

**Files Created:**
- `lib/widgets/carousel/hero_carousel.dart`
- `lib/widgets/carousel/restaurant_carousel.dart`
- `lib/widgets/carousel/offer_carousel.dart`
- `lib/widgets/carousel/menu_carousel.dart`

**Total Lines Added:** ~850 lines of production code

---

**Last Updated**: 2025-12-25
**Maintained By**: Development Team & Claude AI Assistant
**For**: AI Assistants (Claude, GPT, etc.)
