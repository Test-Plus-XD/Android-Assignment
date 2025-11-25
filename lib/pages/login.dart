import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart' show User;
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Login Page - Firebase Implementation
/// 
/// This page handles user authentication through Firebase.
/// It replaces your mock login with real authentication.
/// 
/// User Flow:
/// 1. User enters email/password OR clicks Google sign-in
/// 2. AuthService validates credentials with Firebase
/// 3. On success, Firebase auth state changes
/// 4. Main app detects auth change and shows MainShell
/// 5. UserService automatically loads/creates user profile
/// 
/// This is similar to your Angular login component but simpler because
/// Flutter's Provider pattern handles navigation automatically.
class LoginPage extends StatefulWidget {
  final bool isTraditionalChinese;
  final bool isDarkMode;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;
  final VoidCallback onSkip;

  const LoginPage({
    required this.isTraditionalChinese,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onSkip,
    super.key,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form controllers for text inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  // Toggle between login and register modes
  bool _isRegisterMode = false;
  // Password visibility toggle
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Handle Email/Password Login
  /// 
  /// Validates form and calls AuthService.loginWithEmail().
  /// Shows error messages if authentication fails.
  Future<void> _handleEmailLogin(AuthService authService, UserService userService) async {
    // Validate form inputs
    if (!_formKey.currentState!.validate()) return;
    // Clear keyboard
    FocusScope.of(context).unfocus();
    
    // Attempt login
    final success = await authService.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    if (success && mounted) {
      // Login successful! AuthService will trigger navigation automatically.
      // Update login metadata in background
      if (authService.uid != null) {
        // Load or create user profile via Vercel API
        await _ensureUserProfile(authService, userService);
      }
    } else if (mounted) {
      // Login failed, show error
      _showErrorSnackBar(authService.errorMessage ?? 'Login failed');
    }
  }

  /// Handle Email/Password Registration
  /// 
  /// Creates new user account and optionally creates user profile.
  /// After registration, user needs to verify their email.
  Future<void> _handleEmailRegister(AuthService authService, UserService userService) async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    // Clear keyboard
    FocusScope.of(context).unfocus();
    
    // Attempt registration
    final success = await authService.registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
    );
    
    if (success && mounted) {
      // Show verification email message
      _showSuccessDialog(
        widget.isTraditionalChinese 
            ? '註冊成功！請檢查您的電子郵件以驗證您的帳戶。'
            : 'Registration successful! Please check your email to verify your account.',
      );
      
      // Create user profile in Firestore via Vercel API
      if (authService.currentUser != null) await _createUserProfile(authService, userService);
      /*if (authService.currentUser != null) {
        await userService.createUserProfile(
          UserProfile(
            uid: authService.currentUser!.uid,
            email: authService.currentUser!.email,
            displayName: authService.currentUser!.displayName,
            photoURL: authService.currentUser!.photoURL,
            emailVerified: authService.currentUser!.emailVerified,
            preferences: {
              'language': widget.isTraditionalChinese ? 'TC' : 'EN',
              'theme': widget.isDarkMode ? 'dark' : 'light',
            },
          ),
        );
      }*/
    } else if (mounted) {
      // Registration failed
      _showErrorSnackBar(authService.errorMessage ?? 'Registration failed');
    }
  }

  /// Handle Google Sign-In
  /// 
  /// Opens Google account picker and authenticates user.
  /// Automatically creates user profile if it doesn't exist.
  Future<void> _handleGoogleSignIn(AuthService authService, UserService userService) async {
    final success = await authService.signInWithGoogle();

    if (success && mounted && authService.currentUser != null) {
      // Ensure user profile exists via Vercel API
      await _ensureUserProfile(authService, userService);
    } else if (mounted && authService.errorMessage != null) {
      _showErrorSnackBar(authService.errorMessage!);
    }

    /* Check if user profile exists, create if not for native Google sign-in
    if (success && mounted) {
      if (authService.currentUser != null) {
        final profileExists = await userService.profileExists(authService.currentUser!.uid);
        if (!profileExists) {
          // Create new profile for Google user
          await userService.createUserProfile(
            UserProfile(
              uid: authService.currentUser!.uid,
              email: authService.currentUser!.email,
              displayName: authService.currentUser!.displayName,
              photoURL: authService.currentUser!.photoURL,
              emailVerified: authService.currentUser!.emailVerified,
              preferences: {
                'language': widget.isTraditionalChinese ? 'TC' : 'EN',
                'theme': widget.isDarkMode ? 'dark' : 'light',
              },
            ),
          );
        }
        // Update login metadata
        userService.updateLoginMetadata(authService.currentUser!.uid);
      }
    } else if (mounted && authService.errorMessage != null) {
      // Google sign-in failed
      _showErrorSnackBar(authService.errorMessage!);
    }*/
  }

  /// Create user profile via Vercel API
  Future<void> _createUserProfile(AuthService authService, UserService userService) async {
    try {
      final user = authService.currentUser;
      if (user == null) return;

      final profile = User(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        preferences: {
          'language': widget.isTraditionalChinese ? 'TC' : 'EN',
          'theme': widget.isDarkMode ? 'dark' : 'light',
        },
      );
      await userService.createUserProfile(profile);
    } catch (error) {
      // Profile creation failed but auth succeeded, user can continue
      debugPrint('Failed to create user profile: $error');
    }
  }

  /// Ensure user profile exists, create if missing
  Future<void> _ensureUserProfile(AuthService authService, UserService userService) async {
    try {
      final user = authService.currentUser;
      if (user == null) return;
      // Try to load existing profile
      final profile = await userService.getUserProfile(user.uid);
      if (profile == null) {
        // Profile doesn't exist, create it
        await _createUserProfile(authService, userService);
      } else {
        // Update login metadata
        await userService.updateLoginMetadata(user.uid);
      }
    } catch (error) {
      debugPrint('Failed to ensure user profile: $error');
    }
  }

  /// Show Error Message
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show Success Dialog
  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '成功' : 'Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isTraditionalChinese ? '確定' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get localised strings
    final loginTitle = widget.isTraditionalChinese ? '登入' : 'Login';
    final registerTitle = widget.isTraditionalChinese ? '註冊' : 'Register';
    final emailLabel = widget.isTraditionalChinese ? '電郵' : 'Email';
    final passwordLabel = widget.isTraditionalChinese ? '密碼' : 'Password';
    final nameLabel = widget.isTraditionalChinese ? '姓名' : 'Name';
    final loginButton = widget.isTraditionalChinese ? '登入' : 'Login';
    final registerButton = widget.isTraditionalChinese ? '註冊' : 'Register';
    final googleSignIn = widget.isTraditionalChinese ? '使用 Google 登入' : 'Sign in with Google';
    final switchToRegister = widget.isTraditionalChinese ? '建立新帳戶' : 'Create an account';
    final switchToLogin = widget.isTraditionalChinese ? '已經有帳戶？ 登入' : 'Have an account? Sign in';
    final forgotPassword = widget.isTraditionalChinese ? '忘記密碼？' : 'Forgot password?';
    final skipForNow = widget.isTraditionalChinese ? '暫時略過' : 'Skip for now';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? registerTitle : loginTitle),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<AuthService, UserService>(
        builder: (context, authService, userService, _) {
          return Stack(
            children: [
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      
                      // App logo
                      Image.asset(
                        widget.isDarkMode
                            ? 'assets/images/App-Dark.png'
                            : 'assets/images/App-Light.png',
                        height: 100,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isTraditionalChinese 
                            ? '發現香港最好的素食餐廳'
                            : 'Discover Hong Kong\'s best vegan restaurants',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // Name field (register only)
                      if (_isRegisterMode) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: nameLabel,
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            // Name is optional
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: emailLabel,
                          prefixIcon: const Icon(Icons.email),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return widget.isTraditionalChinese 
                                ? '請輸入電郵地址'
                                : 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return widget.isTraditionalChinese
                                ? '請輸入有效的電郵地址'
                                : 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: passwordLabel,
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                  ? Icons.visibility_off 
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return widget.isTraditionalChinese
                                ? '請輸入密碼'
                                : 'Please enter your password';
                          }
                          if (_isRegisterMode && value.length < 6) {
                            return widget.isTraditionalChinese
                                ? '密碼至少需要6個字符'
                                : 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          if (_isRegisterMode) {
                            _handleEmailRegister(authService, userService);
                          } else {
                            _handleEmailLogin(authService, userService);
                          }
                        },
                      ),
                      
                      // Forgot password (login only)
                      if (!_isRegisterMode) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Show forgot password dialog
                              _showForgotPasswordDialog(authService);
                            },
                            child: Text(forgotPassword),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                      ],
                      
                      // Login/Register button
                      ElevatedButton(
                        onPressed: () {
                          if (_isRegisterMode) {
                            _handleEmailRegister(authService, userService);
                          } else {
                            _handleEmailLogin(authService, userService);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isRegisterMode ? registerButton : loginButton,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Divider with "OR"
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.isTraditionalChinese ? '或' : 'OR',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Google Sign-In button
                      OutlinedButton.icon(
                        onPressed: () => _handleGoogleSignIn(authService, userService),
                        icon: Image.asset(
                          'assets/images/Google.png',
                          height: 24,
                        ),
                        label: Text(googleSignIn),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Switch mode button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = !_isRegisterMode;
                            // Clear form when switching
                            _formKey.currentState?.reset();
                          });
                        },
                        child: Text(
                          _isRegisterMode ? switchToLogin : switchToRegister,
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Skip for now button
                      TextButton(
                        onPressed: widget.onSkip,
                        child: Text(skipForNow),
                      ),

                      const SizedBox(height: 24),
                      
                      // Theme and language toggles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            ),
                            tooltip: widget.isTraditionalChinese 
                                ? '切換主題' 
                                : 'Toggle theme',
                            onPressed: widget.onThemeChanged,
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.language),
                            tooltip: widget.isTraditionalChinese 
                                ? 'Toggle Language' 
                                : '切換語言',
                            onPressed: widget.onLanguageChanged,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Loading overlay
              if (authService.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Show Forgot Password Dialog
  void _showForgotPasswordDialog(AuthService authService) {
    if (!mounted) return;
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '重設密碼' : 'Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isTraditionalChinese
                  ? '輸入您的電郵地址，我們將向您發送重設密碼的連結。'
                  : 'Enter your email address and we will send you a password reset link.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: widget.isTraditionalChinese ? '電郵' : 'Email',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              
              Navigator.pop(context);
              
              final success = await authService.sendPasswordResetEmail(email);
              if (success && mounted) {
                _showSuccessDialog(
                  widget.isTraditionalChinese
                      ? '已發送密碼重設連結到您的電郵。'
                      : 'Password reset link sent to your email.',
                );
              } else if (mounted) {
                _showErrorSnackBar(
                  authService.errorMessage ?? 
                  (widget.isTraditionalChinese ? '發送失敗' : 'Failed to send reset link'),
                );
              }
            },
            child: Text(widget.isTraditionalChinese ? '發送' : 'Send'),
          ),
        ],
      ),
    );
  }
}
