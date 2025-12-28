# PourRice - Vegetarian Restaurant Discovery App

A comprehensive Flutter mobile application for discovering vegetarian and vegan restaurants in Hong Kong with bilingual support (English/Traditional Chinese).

## 📱 Project Overview

**PourRice** is an academic Flutter project that demonstrates modern mobile app development practices through a real-world restaurant discovery platform. The app combines multiple advanced technologies including real-time chat, AI assistance, location services, and restaurant management features.

### Key Features

- 🔍 **Advanced Restaurant Search** - Algolia-powered full-text search with filters
- 📍 **Location-Based Discovery** - GPS integration to find nearby restaurants
- 💬 **Real-Time Chat** - Socket.IO messaging between users and restaurants
- 🤖 **AI Assistant** - Google Gemini integration for restaurant recommendations
- 📅 **Table Bookings** - Complete reservation system with notifications
- ⭐ **Reviews & Ratings** - Community-driven restaurant reviews
- 🏪 **Restaurant Dashboard** - Management interface for restaurant owners
- 📱 **QR Code Integration** - Generate and scan QR codes for restaurant menus
- 🌐 **Bilingual Support** - Full English and Traditional Chinese localization
- 🎨 **Dynamic Theming** - Light/dark mode with Material Design 3

## 🏗️ Architecture

### Technology Stack

- **Framework**: Flutter 3.9.2+ with Dart 3.9.2+
- **State Management**: Provider (ChangeNotifier pattern)
- **Backend**: Vercel Express API + Firebase Auth/Firestore
- **Search**: Algolia Search API
- **Real-time**: Socket.IO (Railway deployment)
- **AI**: Google Gemini 2.5
- **Maps**: Google Maps Flutter
- **Notifications**: Flutter Local Notifications

### Project Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # App configuration
├── constants/                   # Static data (districts, keywords)
├── models/                      # Data models (10 models)
├── services/                    # Business logic (14 services)
├── pages/                       # UI screens (16 pages)
└── widgets/                     # Reusable components (49 widgets)
```

### Core Services

1. **AuthService** - Firebase authentication with Google OAuth
2. **RestaurantService** - Algolia search and restaurant data
3. **BookingService** - Table reservation management
4. **ChatService** - Real-time messaging with Socket.IO
5. **GeminiService** - AI assistant integration
6. **LocationService** - GPS and distance calculations
7. **ReviewService** - Restaurant reviews and ratings
8. **MenuService** - Restaurant menu management
9. **ImageService** - Firebase Storage image uploads
10. **NotificationService** - Local notification scheduling

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2+
- Dart SDK 3.9.2+
- Android Studio / VS Code
- Firebase project setup
- Google Maps API key
- Algolia account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd android_assignment
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your Firebase configuration

4. **Configure API endpoints**
   - Update `lib/config.dart` with your API URLs:
     ```dart
     // For development (adjust based on your setup)
     return 'http://10.0.2.2:3000';  // Android Emulator
     // return 'http://localhost:3000';  // iOS Simulator
     // return 'http://192.168.1.100:3000';  // Real device
     ```

5. **Add Google Maps API key**
   - Android: Add to `android/app/src/main/AndroidManifest.xml`
   - iOS: Add to `ios/Runner/AppDelegate.swift`

6. **Run the application**
   ```bash
   flutter run
   ```

### Environment Configuration

The app uses different configurations for development and production:

- **Development**: Uses localhost/emulator addresses for API calls
- **Production**: Uses deployed API endpoints
- **API Passcode**: `PourRice` (required for all API calls)

## 📋 Features Deep Dive

### User Roles & Navigation

The app supports three user types with dynamic navigation:

**Guest Users (Not Logged In)**
- Search restaurants
- View restaurant details
- Limited access to features

**Diners (Logged In)**
- Full restaurant search and discovery
- Make table bookings
- Write reviews and ratings
- Real-time chat with restaurants
- AI assistant for recommendations

**Restaurant Owners**
- Manage restaurant information
- Handle table bookings
- Manage menu items with bulk import
- Generate QR codes for menus
- Chat with customers

### Advanced Search & Discovery

- **Algolia Integration**: Fast, indexed search across restaurant names, addresses, and keywords
- **Filtering Options**: Filter by Hong Kong district, cuisine type, and distance
- **Location Services**: Find restaurants near your current location
- **Bilingual Search**: Search in both English and Traditional Chinese

### Real-Time Communication

- **Socket.IO Integration**: Real-time messaging between users and restaurants
- **Chat Features**: Typing indicators, image sharing, persistent message history
- **Room Management**: Organized conversations by restaurant

### AI Assistant (Gemini)

- **Context-Aware**: Can be launched from restaurant pages with pre-filled context
- **Restaurant Recommendations**: Get personalized suggestions based on preferences
- **Menu Inquiries**: Ask questions about specific restaurants and their offerings
- **Dietary Support**: Understands vegetarian and vegan requirements

### QR Code Features

- **Menu QR Generation**: Restaurant owners can generate QR codes for their menus
- **QR Scanning**: Diners can scan QR codes to quickly access restaurant menus
- **Deep Linking**: Format `pourrice://menu/{restaurantId}` for seamless navigation

## 🗃️ Data Models

The app uses 10 core data models:

1. **User** - User profiles with role-based access
2. **Restaurant** - Restaurant information with bilingual support
3. **MenuItem** - Menu items with descriptions and pricing
4. **Booking** - Table reservations with status tracking
5. **Review** - Restaurant reviews with ratings
6. **ReviewStats** - Aggregated rating statistics
7. **ChatRoom** - Chat room management
8. **ChatMessage** - Individual chat messages
9. **GeminiMessage** - AI conversation history
10. **Image** - Image upload metadata

## 🌐 API Integration

### REST API Endpoints

- **Base URL**: `https://vercel-express-api-alpha.vercel.app`
- **Authentication**: Firebase ID tokens + API passcode
- **Key Endpoints**:
  - `/API/Users` - User profile management
  - `/API/Restaurants` - Restaurant CRUD operations
  - `/API/Bookings` - Table reservation system
  - `/API/Chat/` - Chat history and room management
  - `/API/Gemini/chat` - AI conversation endpoint

### Socket.IO Events

- **Server**: `https://railway-socket-production.up.railway.app`
- **Events**: `register`, `join-room`, `send-message`, `new-message`, `user-typing`

## 🎨 UI/UX Features

### Bilingual Support

- Complete English and Traditional Chinese localization
- Dynamic language switching
- Persistent language preferences

### Theming

- Material Design 3 implementation
- Light and dark theme support
- Dynamic theme switching
- Consistent color schemes across all components

### Navigation

- Role-based bottom navigation
- Dynamic navigation based on user authentication
- Smooth page transitions
- Floating action button for AI assistant

## 📊 Project Statistics

- **Total Files**: 99 Dart files
- **Lines of Code**: ~20,000+ (excluding comments and empty lines)
- **UI Screens**: 16 pages
- **Reusable Widgets**: 49 components
- **Business Services**: 14 services
- **Data Models**: 10 models

## 🧪 Testing & Development

### Code Quality

```bash
# Run linting
flutter analyze

# Auto-fix issues
dart fix --apply

# Run tests
flutter test

# Build release APK
flutter build apk --release
```

### Development Guidelines

1. **Bilingual Support**: Always provide both English and Traditional Chinese text
2. **Theme Awareness**: Use theme colors, never hardcode colors
3. **Error Handling**: Wrap all async operations in try-catch blocks
4. **State Management**: Use Provider pattern with ChangeNotifier
5. **API Integration**: Include required headers (x-api-passcode, Authorization)

## 📱 Sample Data

The project includes sample data for development and testing:

- **Restaurants**: 3 sample vegetarian restaurants in Hong Kong
- **Users**: Test user accounts
- **Reviews**: Sample reviews in both languages
- **Menu Items**: Example menu data

## 🔧 Configuration Files

- `pubspec.yaml` - Dependencies and asset configuration
- `lib/config.dart` - API endpoints and environment settings
- `firebase_options.dart` - Firebase configuration
- `analysis_options.yaml` - Linting rules

## 📄 License

This project is an academic assignment and is not intended for commercial use.

## 🤝 Contributing

This is an academic project. For educational purposes, you can:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request with detailed description

## 📞 Support

For questions about this academic project, please refer to the course materials or contact the instructor.

---

**Note**: This is an academic Flutter project demonstrating modern mobile app development practices. It showcases integration with multiple services including Firebase, Algolia, Socket.IO, and Google Gemini AI, making it an excellent learning resource for Flutter development.