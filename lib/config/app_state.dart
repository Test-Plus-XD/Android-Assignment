import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for persisted preferences
const String prefKeyIsDark = 'pourrice_is_dark';
const String prefKeyIsTc = 'pourrice_is_tc';

/// Application State
///
/// Manages global UI preferences like theme and language.
/// Uses SharedPreferences for persistence across app restarts.
///
/// This class follows the Provider pattern (ChangeNotifier) to notify
/// widgets when preferences change, triggering automatic UI rebuilds.
class AppState with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isTraditionalChinese = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isTraditionalChinese => _isTraditionalChinese;
  bool get isLoaded => _isLoaded;

  /// Constructor
  ///
  /// Automatically loads saved preferences when created.
  AppState() {
    _loadPreferences();
  }

  /// Load Preferences from SharedPreferences
  ///
  /// Called once during initialisation to restore user's saved preferences.
  /// Defaults to light mode and English if no preferences exist.
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(prefKeyIsDark) ?? false;
    _isTraditionalChinese = prefs.getBool(prefKeyIsTc) ?? false;
    _isLoaded = true;
    notifyListeners(); // Trigger UI rebuild
  }

  /// Toggle Theme Mode
  ///
  /// Switches between light and dark mode and persists the choice.
  /// Notifies all listening widgets to rebuild with new theme.
  ///
  /// @param value - true for dark mode, false for light mode
  Future<void> toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsDark, value);
    _isDarkMode = value;
    notifyListeners(); // Trigger UI rebuild
  }

  /// Toggle Language
  ///
  /// Switches between English and Traditional Chinese and persists the choice.
  /// Notifies all listening widgets to rebuild with new language.
  ///
  /// @param value - true for Traditional Chinese, false for English
  Future<void> toggleLanguage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsTc, value);
    _isTraditionalChinese = value;
    notifyListeners(); // Trigger UI rebuild
  }
}