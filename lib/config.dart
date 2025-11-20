import 'package:flutter/foundation.dart';

/// Application Configuration
/// 
/// This class manages environment-specific configuration like API URLs.
/// Similar to environment.ts in your Angular app, but Flutter doesn't have
/// a built-in environment system, so we create our own.
/// 
/// How it works:
/// - In development (debug mode), uses localhost/emulator addresses
/// - In production (release mode), uses your deployed API
/// - You can override with custom URLs for testing
class AppConfig {
  /// API Base URL
  /// 
  /// This determines where your app sends HTTP requests.
  /// 
  /// Development options:
  /// - Android Emulator: Use 10.0.2.2 (points to host machine)
  /// - iOS Simulator: Use localhost (works differently than Android)
  /// - Real Device: Use your computer's local IP (e.g., 192.168.1.100)
  /// 
  /// To find your local IP:
  /// - Windows: Open Command Prompt, type 'ipconfig'
  /// - Mac/Linux: Open Terminal, type 'ifconfig' or 'ip addr'
  /// - Look for the IPv4 address (usually starts with 192.168 or 10.0)
  static String get apiBaseUrl {
    // If in debug mode (development), use development URL
    if (kDebugMode) {
      // Change this based on your setup:
      
      // Option 1: For Android Emulator
      return 'http://10.0.2.2:3000';
      
      // Option 2: For iOS Simulator
      // return 'http://localhost:3000';
      
      // Option 3: For real device on same WiFi
      // Replace with your computer's actual IP address
      // return 'http://192.168.1.100:3000';
      
      // Option 4: For testing with deployed API
      // return 'https://yourapi.com';
    }
    
    // Production URL (used when app is built in release mode)
    // TODO: Replace with your actual production API URL
    return 'https://yourapi.com';
  }
  
  /// Algolia Configuration
  /// 
  /// These settings come from your Algolia dashboard.
  /// They're the same across all environments because Algolia is already a hosted service.
  static const String algoliaAppId = 'V9HMGL1VIZ';
  static const String algoliaSearchKey = '563754aa2e02b4838af055fbf37f09b5';
  static const String algoliaIndexName = 'Restaurants';
  
  /// Get full API endpoint URL
  /// 
  /// Helper method to construct full endpoint URLs.
  /// For example: getEndpoint('/API/Users') returns 'http://10.0.2.2:3000/API/Users'
  static String getEndpoint(String path) {
    // Remove leading slash if present to avoid double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$apiBaseUrl/$cleanPath';
  }
  
  /// Check if running in development mode
  static bool get isDevelopment => kDebugMode;
  
  /// Check if running in production mode
  static bool get isProduction => !kDebugMode;
  
  /// Print current configuration (useful for debugging)
  static void printConfig() {
    if (kDebugMode) {
      print('=== App Configuration ===');
      print('Mode: ${isDevelopment ? "Development" : "Production"}');
      print('API Base URL: $apiBaseUrl');
      print('Algolia App ID: $algoliaAppId');
      print('Algolia Index: $algoliaIndexName');
      print('========================');
    }
  }
}

/// How to use this configuration:
/// 
/// 1. In your services, import this file:
///    import '../config/app_config.dart';
/// 
/// 2. Use AppConfig.apiBaseUrl or AppConfig.getEndpoint():
///    final url = AppConfig.getEndpoint('/API/Users');
/// 
/// 3. For testing, you can temporarily change the apiBaseUrl method
///    to return a specific URL, then change it back when done.
/// 
/// 4. When building for production, Flutter automatically sets kDebugMode = false,
///    so your app will use the production URL without any code changes.
