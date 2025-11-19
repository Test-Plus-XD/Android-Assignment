// This file contains your Firebase configuration settings.
// These settings tell your Flutter app how to connect to your Firebase project.
// Think of it like an address book - it tells your app where to find Firebase services.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  // This method returns the correct configuration based on the platform your app runs on.
  // Android devices get Android config, web gets web config, etc.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for windows');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Web configuration - same as your Angular project
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCsVCZW7tF7ScW4e2SBdYtSQrl_GrK4zBk',
    authDomain: 'cross-platform-assignmen-b97cc.firebaseapp.com',
    projectId: 'cross-platform-assignmen-b97cc',
    storageBucket: 'cross-platform-assignmen-b97cc.firebasestorage.app',
    messagingSenderId: '937491674619',
    appId: '1:937491674619:web:81eb1b44453eacdf3a475e',
    measurementId: 'G-FQEV6WSNPC',
  );

  // Android configuration
  // You'll get these values when you register your Android app in Firebase Console
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsVCZW7tF7ScW4e2SBdYtSQrl_GrK4zBk',
    appId: '1:937491674619:android:YOUR_ANDROID_APP_ID', // Replace with your actual Android app ID
    messagingSenderId: '937491674619',
    projectId: 'cross-platform-assignmen-b97cc',
    storageBucket: 'cross-platform-assignmen-b97cc.firebasestorage.app',
  );

  // iOS configuration (for future reference if you expand to iOS)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCsVCZW7tF7ScW4e2SBdYtSQrl_GrK4zBk',
    appId: '1:937491674619:ios:YOUR_IOS_APP_ID', // Replace with your actual iOS app ID
    messagingSenderId: '937491674619',
    projectId: 'cross-platform-assignmen-b97cc',
    storageBucket: 'cross-platform-assignmen-b97cc.firebasestorage.app',
    iosBundleId: 'com.example.androidAssignment',
  );

  // macOS configuration (for future reference)
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCsVCZW7tF7ScW4e2SBdYtSQrl_GrK4zBk',
    appId: '1:937491674619:macos:YOUR_MACOS_APP_ID', // Replace with your actual macOS app ID
    messagingSenderId: '937491674619',
    projectId: 'cross-platform-assignmen-b97cc',
    storageBucket: 'cross-platform-assignmen-b97cc.firebasestorage.app',
    iosBundleId: 'com.example.androidAssignment',
  );
}
