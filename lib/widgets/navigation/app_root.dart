import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_state.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../pages/login_page.dart';
import 'main_shell.dart';

/// App Root Widget
///
/// This widget manages theme, language, and authentication flow.
/// It's the root of the application UI hierarchy, determining whether
/// to show the login page or the main app based on authentication state.
///
/// Flow:
/// 1. App starts, loads user preferences (theme, language)
/// 2. Shows loading indicator while preferences load
/// 3. Checks authentication state
/// 4. If logged in or guest mode -> show MainShell
/// 5. If not logged in -> show LoginPage
/// 6. When auth state changes, automatically rebuilds and shows appropriate screen
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isSkipped = false;

  /// Handle Skip Login
  ///
  /// Allows users to browse the app without authentication (guest mode).
  /// Sets the skip flag and triggers a rebuild to show the main app.
  void _skipLogin() {
    setState(() {
      _isSkipped = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Wait for preferences to load before showing anything
    if (!appState.isLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    /// Build MaterialApp with Theme Configuration
    ///
    /// Uses the theme builder from AppTheme to create consistent
    /// light and dark themes with the vegan green aesthetic.
    return MaterialApp(
      title: 'PourRice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      darkTheme: AppTheme.buildDarkTheme(),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      /// Authentication Flow
      ///
      /// Consumer listens to AuthService and rebuilds when auth state changes.
      /// This creates a reactive authentication flow:
      /// - User logs in -> AuthService notifies listeners -> UI rebuilds -> MainShell shown
      /// - User logs out -> AuthService notifies listeners -> UI rebuilds -> LoginPage shown
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          // Show loading while checking authentication state
          if (authService.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is logged in or in guest mode -> show main app
          if (authService.isLoggedIn || _isSkipped) {
            return MainShell(
              isDarkMode: appState.isDarkMode,
              isTraditionalChinese: appState.isTraditionalChinese,
              onThemeChanged: appState.toggleTheme,
              onLanguageChanged: appState.toggleLanguage,
            );
          }

          // User not logged in -> show login page
          return LoginPage(
            isTraditionalChinese: appState.isTraditionalChinese,
            isDarkMode: appState.isDarkMode,
            onThemeChanged: () => appState.toggleTheme(!appState.isDarkMode),
            onLanguageChanged: () =>
                appState.toggleLanguage(!appState.isTraditionalChinese),
            onSkip: _skipLogin,
          );
        },
      ),
    );
  }
}