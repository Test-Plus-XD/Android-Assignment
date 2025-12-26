import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models.dart';
import 'login_page.dart';

/// Account Page with Edit Functionality
//
/// Features:
/// - Displays comprehensive user profile information
/// - Inline editing with field-by-field controls
/// - Dark mode support with proper text colours
/// - Type selection popup
/// - Preferences editing with structured sub-fields
class AccountPage extends StatefulWidget {
  final bool isDarkMode;
  final bool isTraditionalChinese;
  final VoidCallback onThemeChanged;
  final VoidCallback onLanguageChanged;
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStateChanged;

  const AccountPage({
    required this.isDarkMode,
    required this.isTraditionalChinese,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.isLoggedIn,
    required this.onLoginStateChanged,
    super.key,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _hasAttemptedLoad = false;
  bool _isEditing = false;
  // Text editing controllers
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  // Editable fields
  String? _editedType;
  UserPreferences? _editedPreferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// Loads user profile if not already loaded
  Future<void> _loadProfileIfNeeded() async {
    if (!mounted) return;
    if (!widget.isLoggedIn) return;
    if (_hasAttemptedLoad) return;

    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();

    if (authService.uid != null) {
      setState(() {
        _hasAttemptedLoad = true;
      });
      userService.getUserProfile(authService.uid!);
    }
  }

  /// Initialises edit mode with current user data
  void _startEditing() {
    final userService = context.read<UserService>();
    final user = userService.currentProfile;
    if (user == null) return;

    setState(() {
      _isEditing = true;
      // Populate controllers with current values
      _displayNameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      _editedType = user.type ?? '';
      // Auto-fetch preferences on first edit
      _editedPreferences = user.getPreferences();
    });
  }

  /// Saves all edited fields
  Future<void> _saveChanges() async {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();

    if (authService.uid == null) return;

    // Validate type is set
    if (_editedType == null || _editedType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isTraditionalChinese
                ? '請選擇帳戶類型'
                : 'Please select account type',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prepare updates map
    final Map<String, dynamic> updates = {};

    // Add changed fields
    if (_displayNameController.text.isNotEmpty) updates['displayName'] = _displayNameController.text;
    if (_emailController.text.isNotEmpty) updates['email'] = _emailController.text;
    if (_phoneController.text.isNotEmpty) updates['phoneNumber'] = _phoneController.text;
    if (_bioController.text.isNotEmpty) updates['bio'] = _bioController.text;
    if (_editedType != null && _editedType!.isNotEmpty) updates['type'] = _editedType;
    if (_editedPreferences != null) updates['preferences'] = _editedPreferences!.toJson();

    // Save to API
    final success = await userService.updateUserProfile(
      authService.uid!,
      updates,
    );

    if (success) {
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isTraditionalChinese
                  ? '個人資料已更新'
                  : 'Profile updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userService.errorMessage ??
                  (widget.isTraditionalChinese ? '更新失敗' : 'Update failed'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return widget.isTraditionalChinese ? '不適用' : 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime.toLocal());
  }

  /// Builds section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds info row with edit capability
  Widget _buildInfoRow(
      String label,
      String value, {
        IconData? icon,
        bool editable = false,
        TextEditingController? controller,
        VoidCallback? onEdit,
      }) {
    // Dark mode text colour support
    final labelColour = widget.isDarkMode ? Colors.white : Colors.grey.shade600;
    final valueColour = widget.isDarkMode ? Colors.white70 : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: labelColour,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: labelColour,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _isEditing && editable && controller != null
                ? TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColour,
              ),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                suffixIcon: const Icon(Icons.edit, size: 16),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColour,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                if (_isEditing && editable && onEdit != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds status badge with improved contrast
  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    // Improved contrast colours for dark mode
    final badgeColour = widget.isDarkMode
        ? (label.contains('Verified') || label.contains('已驗證')
        ? const Color(0xFF4CAF50) // Brighter green for dark mode
        : const Color(0xFFFF9800)) // Brighter orange for dark mode
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColour.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColour),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: badgeColour,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds statistics card
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows type selection popup
  Future<void> _showTypeSelector() async {
    final types = ['Diner', 'Restaurant'];
    final typeLabels = widget.isTraditionalChinese
        ? {'Diner': '食客', 'Restaurant': '商戶'}
        : {'Diner': 'Diner', 'Restaurant': 'Restaurant'};

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isTraditionalChinese ? '選擇帳戶類型' : 'Select Account Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: types.map((type) {
            return RadioListTile<String>(
              title: Text(typeLabels[type] ?? type),
              value: type,
              groupValue: _editedType,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _editedType = selected;
      });
    }
  }

  /// Shows preferences editor popup
  Future<void> _showPreferencesEditor() async {
    final prefs = _editedPreferences ?? UserPreferences.fromJson(null);

    String tempLanguage = prefs.language;
    bool tempNotifications = prefs.notifications;
    String tempTheme = prefs.theme;

    final result = await showDialog<UserPreferences>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            widget.isTraditionalChinese ? '編輯偏好設定' : 'Edit Preferences',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selection
                Text(
                  widget.isTraditionalChinese ? '語言' : 'Language',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'EN',
                  groupValue: tempLanguage,
                  onChanged: (value) {
                    setDialogState(() {
                      tempLanguage = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('繁體中文'),
                  value: 'TC',
                  groupValue: tempLanguage,
                  onChanged: (value) {
                    setDialogState(() {
                      tempLanguage = value!;
                    });
                  },
                ),
                const Divider(),

                // Notifications toggle
                SwitchListTile(
                  title: Text(
                    widget.isTraditionalChinese ? '通知' : 'Notifications',
                  ),
                  value: tempNotifications,
                  onChanged: (value) {
                    setDialogState(() {
                      tempNotifications = value;
                    });
                  },
                ),
                const Divider(),

                // Theme selection
                Text(
                  widget.isTraditionalChinese ? '主題' : 'Theme',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                RadioListTile<String>(
                  title: Text(widget.isTraditionalChinese ? '淺色' : 'Light'),
                  value: 'light',
                  groupValue: tempTheme,
                  onChanged: (value) {
                    setDialogState(() {
                      tempTheme = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: Text(widget.isTraditionalChinese ? '深色' : 'Dark'),
                  value: 'dark',
                  groupValue: tempTheme,
                  onChanged: (value) {
                    setDialogState(() {
                      tempTheme = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.isTraditionalChinese ? '取消' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updatedPrefs = UserPreferences(
                  language: tempLanguage,
                  notifications: tempNotifications,
                  theme: tempTheme,
                );
                Navigator.pop(context, updatedPrefs);
              },
              child: Text(widget.isTraditionalChinese ? '確認' : 'OK'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _editedPreferences = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Localised strings
    final personalInfoTitle = widget.isTraditionalChinese ? '個人資料' : 'Personal Information';
    final accountStatusTitle = widget.isTraditionalChinese ? '帳戶狀態' : 'Account Status';
    final preferencesTitle = widget.isTraditionalChinese ? '偏好設定' : 'Preferences';
    final statisticsTitle = widget.isTraditionalChinese ? '統計資料' : 'Statistics';
    final actionsTitle = widget.isTraditionalChinese ? '操作' : 'Actions';

    final uidLabel = widget.isTraditionalChinese ? '使用者ID' : 'User ID';
    final emailLabel = widget.isTraditionalChinese ? '電郵' : 'Email';
    final displayNameLabel = widget.isTraditionalChinese ? '顯示名稱' : 'Display Name';
    final phoneLabel = widget.isTraditionalChinese ? '電話' : 'Phone Number';
    final accountTypeLabel = widget.isTraditionalChinese ? '帳戶類型' : 'Account Type';
    final bioLabel = widget.isTraditionalChinese ? '個人簡介' : 'Bio';

    final verifiedLabel = widget.isTraditionalChinese ? '已驗證' : 'Verified';
    final notVerifiedLabel = widget.isTraditionalChinese ? '未驗證' : 'Not Verified';

    final createdAtLabel = widget.isTraditionalChinese ? '建立日期' : 'Created';
    final modifiedAtLabel = widget.isTraditionalChinese ? '修改日期' : 'Modified';
    final lastLoginLabel = widget.isTraditionalChinese ? '上次登入' : 'Last Login';
    final loginCountLabel = widget.isTraditionalChinese ? '登入次數' : 'Login Count';

    final editProfileLabel = widget.isTraditionalChinese ? '編輯個人資料' : 'Edit Profile';
    final saveChangesLabel = widget.isTraditionalChinese ? '儲存變更' : 'Save Changes';
    final logoutLabel = widget.isTraditionalChinese ? '登出' : 'Logout';

    final loginPrompt = widget.isTraditionalChinese ? '請先登入' : 'Please log in';
    final loginButtonLabel = widget.isTraditionalChinese ? '登入' : 'Login';
    final loadingMessage = widget.isTraditionalChinese ? '載入中...' : 'Loading...';
    final noProfileMessage = widget.isTraditionalChinese ? '沒有找到使用者資料' : 'No profile found';
    final retryLabel = widget.isTraditionalChinese ? '重試' : 'Retry';

    // Early return if not logged in
    if (!widget.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_circle,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    loginPrompt,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginPage(
                            isTraditionalChinese: widget.isTraditionalChinese,
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            onSkip: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: Text(loginButtonLabel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<UserService>(
      builder: (context, userService, _) {
        // Loading state
        if (userService.isLoading && !_hasAttemptedLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (userService.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userService.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAttemptedLoad = false;
                      });
                      _loadProfileIfNeeded();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
        }

        final user = userService.currentProfile;

        // No profile state
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    noProfileMessage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAttemptedLoad = false;
                      });
                      _loadProfileIfNeeded();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(retryLabel),
                  ),
                ],
              ),
            ),
          );
        }

        // Get preferences for display
        final prefs = _editedPreferences ?? user.getPreferences();
        final typeDisplay = _editedType ?? user.type ?? '';
        final typeLabels = widget.isTraditionalChinese
            ? {'Diner': '食客', 'Restaurant': '商戶', '': '無'}
            : {'Diner': 'Diner', 'Restaurant': 'Restaurant', '': 'None'};

        // Display profile
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile header with avatar and name
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                            ? NetworkImage(user.photoURL!)
                            : null,
                        backgroundColor: Colors.white,
                        child: user.photoURL == null || user.photoURL!.isEmpty
                            ? Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).colorScheme.primary,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Display name
                    Text(
                      user.displayName ?? emailLabel,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Email verification badge
                    _buildStatusBadge(
                      user.emailVerified ? verifiedLabel : notVerifiedLabel,
                      user.emailVerified ? Colors.green : Colors.orange,
                      user.emailVerified ? Icons.verified : Icons.warning,
                    ),
                  ],
                ),
              ),

              // Statistics cards
              _buildSectionHeader(statisticsTitle, Icons.analytics),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildStatCard(
                      loginCountLabel,
                      '${user.loginCount ?? 0}',
                      Icons.login,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      widget.isTraditionalChinese ? '帳戶天數' : 'Days Active',
                      user.createdAt != null
                          ? '${DateTime.now().difference(user.createdAt!).inDays}'
                          : '0',
                      Icons.calendar_today,
                      Colors.purple,
                    ),
                  ],
                ),
              ),

              // Personal information section
              _buildSectionHeader(personalInfoTitle, Icons.person),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow(uidLabel, user.uid, icon: Icons.fingerprint),
                    const Divider(height: 1),
                    _buildInfoRow(
                      emailLabel,
                      user.email ?? 'N/A',
                      icon: Icons.email,
                      editable: true,
                      controller: _emailController,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      displayNameLabel,
                      _displayNameController.text.isEmpty
                          ? (user.displayName ?? 'N/A')
                          : _displayNameController.text,
                      icon: Icons.badge,
                      editable: true,
                      controller: _displayNameController,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      phoneLabel,
                      _phoneController.text.isEmpty
                          ? (user.phoneNumber ?? 'N/A')
                          : _phoneController.text,
                      icon: Icons.phone,
                      editable: true,
                      controller: _phoneController,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      accountTypeLabel,
                      typeLabels[typeDisplay] ?? typeDisplay,
                      icon: Icons.category,
                      editable: true,
                      onEdit: _showTypeSelector,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      bioLabel,
                      _bioController.text.isEmpty
                          ? (user.bio ?? 'N/A')
                          : _bioController.text,
                      icon: Icons.description,
                      editable: true,
                      controller: _bioController,
                    ),
                  ],
                ),
              ),

              // Account status section
              _buildSectionHeader(accountStatusTitle, Icons.info),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      createdAtLabel,
                      _formatDateTime(user.createdAt),
                      icon: Icons.event,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      modifiedAtLabel,
                      _formatDateTime(user.modifiedAt),
                      icon: Icons.update,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      lastLoginLabel,
                      _formatDateTime(user.lastLoginAt),
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),

              // Preferences section
              _buildSectionHeader(preferencesTitle, Icons.settings),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      widget.isTraditionalChinese ? '語言' : 'Language',
                      prefs.language == 'EN' ? 'English' : '繁體中文',
                      icon: Icons.language,
                      editable: true,
                      onEdit: _showPreferencesEditor,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      widget.isTraditionalChinese ? '通知' : 'Notifications',
                      prefs.notifications
                          ? (widget.isTraditionalChinese ? '啟用' : 'Enabled')
                          : (widget.isTraditionalChinese ? '停用' : 'Disabled'),
                      icon: Icons.notifications,
                      editable: true,
                      onEdit: _showPreferencesEditor,
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      widget.isTraditionalChinese ? '主題' : 'Theme',
                      prefs.theme == 'light'
                          ? (widget.isTraditionalChinese ? '淺色' : 'Light')
                          : (widget.isTraditionalChinese ? '深色' : 'Dark'),
                      icon: Icons.palette,
                      editable: true,
                      onEdit: _showPreferencesEditor,
                    ),
                  ],
                ),
              ),

              // Actions section
              _buildSectionHeader(actionsTitle, Icons.touch_app),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _isEditing ? _saveChanges : _startEditing,
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      label: Text(_isEditing ? saveChangesLabel : editProfileLabel),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              widget.isTraditionalChinese ? '確認登出' : 'Confirm Logout',
                            ),
                            content: Text(
                              widget.isTraditionalChinese
                                  ? '您確定要登出嗎？'
                                  : 'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  widget.isTraditionalChinese ? '取消' : 'Cancel',
                                ),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onLoginStateChanged(false);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                ),
                                child: Text(logoutLabel),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(logoutLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}